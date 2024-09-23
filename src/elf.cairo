use super::riscv::{RISCVMachine, RISCVMachineImpl, RISCVMachineTrait};

#[derive(Drop)]
pub struct ELFLoader {
    little_endian: bool, // true if little endian
    e_shoff: u32, // section header offset
    e_shentsize: u16, // section header size
    e_shnum: u16, // section header count
}

#[generate_trait]
pub impl ELFLoaderImpl of ELFLoaderTrait {
    fn new() -> ELFLoader {
        ELFLoader { little_endian: false, e_shoff: 0, e_shentsize: 0, e_shnum: 0, }
    }

    fn get_byte(ref self: ELFLoader, data: Span<u8>, offset: u32) -> Option<u8> {
        match data.get(offset.into()) {
            Option::Some(v) => Option::Some(*v.unbox()),
            Option::None => Option::None,
        }
    }

    fn get_halfw(ref self: ELFLoader, data: Span<u8>, offset: u32) -> Option<u16> {
        let offset = offset.into();
        let b1 = match self.get_byte(data, offset + 0) {
            Option::Some(v) => v,
            Option::None => { return Option::None; },
        };
        let b2 = match self.get_byte(data, offset + 1) {
            Option::Some(v) => v,
            Option::None => { return Option::None; },
        };
        if self.little_endian {
            // little endian, which means the least significant byte is first
            Option::Some(b1.into() + (b2.into() * 0b100000000))
        } else {
            // big endian, which means the most significant byte is first
            Option::Some(b2.into() + (b1.into() * 0b100000000))
        }
    }

    fn get_w(ref self: ELFLoader, data: Span<u8>, offset: u32) -> Option<u32> {
        let offset = offset.into();
        let b1 = match self.get_byte(data, offset + 0) {
            Option::Some(v) => v,
            Option::None => { return Option::None; },
        };
        let b2 = match self.get_byte(data, offset + 1) {
            Option::Some(v) => v,
            Option::None => { return Option::None; },
        };
        let b3 = match self.get_byte(data, offset + 2) {
            Option::Some(v) => v,
            Option::None => { return Option::None; },
        };
        let b4 = match self.get_byte(data, offset + 3) {
            Option::Some(v) => v,
            Option::None => { return Option::None; },
        };
        if self.little_endian {
            // little endian, which means the least significant byte is first
            Option::Some(
                b1.into()
                    + (b2.into() * 0b100000000)
                    + (b3.into() * 0b10000000000000000)
                    + (b4.into() * 0b1000000000000000000000000)
            )
        } else {
            // big endian, which means the most significant byte is first
            Option::Some(
                b4.into()
                    + (b3.into() * 0b100000000)
                    + (b2.into() * 0b10000000000000000)
                    + (b1.into() * 0b1000000000000000000000000)
            )
        }
    }

    fn load(ref self: ELFLoader, data: Span<u8>, ref machine: RISCVMachine) -> bool {
        // parse elf header
        if !self.parse_elf_header(data, ref machine) {
            return false;
        }

        // parse section headers
        if !self.parse_section_headers(data, ref machine) {
            return false;
        }

        true
    }

    fn parse_section_headers(
        ref self: ELFLoader, data: Span<u8>, ref machine: RISCVMachine
    ) -> bool {
        // The section headers start at e_shoff and are e_shnum in number, each with a size of
        // e_shentsize.

        let mut section_index = 0;
        let mut offset = self.e_shoff;
        let mut res = true;

        while section_index < self.e_shnum {
            // read section header

            // sh_type
            let sh_type = match self.get_w(data, offset + 0x04) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };
            if sh_type & 0x8 != 0 {
                //NOBITS section: do not load

                // update cursor and continue
                section_index += 1;
                offset += self.e_shentsize.into();
                continue;
            }

            // sh_flags
            let sh_flags = match self.get_w(data, offset + 0x08) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };
            if sh_flags & 0x02 == 0 {
                // Does not have the SHF_ALLOC flag set: do not load

                // update cursor and continue
                section_index += 1;
                offset += self.e_shentsize.into();
                continue;
            }

            // sh_addr
            let sh_addr = match self.get_w(data, offset + 0x0C) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // sh_offset
            let sh_offset = match self.get_w(data, offset + 0x10) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // sh_size
            let sh_size = match self.get_w(data, offset + 0x14) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // load section into memory
            let mut file_cursor = sh_offset;
            let mut mem_cursor = sh_addr;
            let end_iter = sh_offset + sh_size;
            while file_cursor < end_iter {
                let entry = match self.get_byte(data, file_cursor) {
                    Option::Some(v) => v,
                    Option::None => {
                        res = false;
                        break;
                    },
                };
                machine.mem_set(mem_cursor, entry);
                file_cursor += 1;
                mem_cursor += 1;
            };
            if res == false {
                break;
            }

            // update cursor
            section_index += 1;
            offset += self.e_shentsize.into();
        };

        res
    }

    fn parse_elf_header(ref self: ELFLoader, data: Span<u8>, ref machine: RISCVMachine) -> bool {
        // bit depth
        match self.get_byte(data, 0x04) {
            Option::Some(v) => {
                if v == 1 { // 32-bit
                } else if v == 2 {
                    // 64-bit
                    // unsupported for now
                    return false;
                } else {
                    return false;
                }
            },
            Option::None => { return false; },
        }

        // endianness
        match self.get_byte(data, 0x05) {
            Option::Some(v) => {
                if v == 1 {
                    // litte endian
                    self.little_endian = true;
                } else if v == 2 {
                    // big endian
                    self.little_endian = false;
                } else {
                    return false;
                }
            },
            Option::None => { return false; },
        }

        // Entry point
        match self.get_w(data, 0x18) {
            Option::Some(v) => machine.set_pc(v),
            Option::None => { return false; },
        };

        // Section header offset
        self.e_shoff = match self.get_w(data, 0x20) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Section header size
        self.e_shentsize = match self.get_halfw(data, 0x2E) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Section header count
        self.e_shnum = match self.get_halfw(data, 0x30) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        true
    }
}
