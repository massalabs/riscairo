use super::riscv::{RISCVMachine, RISCVMachineImpl, RISCVMachineTrait, wrap_add};

#[derive(Drop)]
pub struct ELFLoader {
    format32: bool, // true if 32 bit format
    little_endian: bool, // true if little endian
    e_entry: u32, // Program entry point
    e_phoff: u32, // Program header offset
    e_shoff: u32, // Section header offset
    e_flags: u32, // Flags
    e_ehsize: u16, // Header size
    e_phentsize: u16, // Program header size
    e_phnum: u16, // Program header count
    e_shentsize: u16, // Section header size
    e_shnum: u16, // Section header count
    e_shstrndx: u16, // Section header string table index
}

#[generate_trait]
pub impl ELFLoaderImpl of ELFLoaderTrait {
    fn new() -> ELFLoader {
        ELFLoader {
            format32: false,
            little_endian: false,
            e_entry: 0,
            e_phoff: 0,
            e_shoff: 0,
            e_flags: 0,
            e_ehsize: 0,
            e_phentsize: 0,
            e_phnum: 0,
            e_shentsize: 0,
            e_shnum: 0,
            e_shstrndx: 0,
        }
    }

    fn get_byte(ref self: ELFLoader, data: @Array<u8>, offset: u32) -> Option<u8> {
        match data.get(offset.into()) {
            Option::Some(v) => Option::Some(*v.unbox()),
            Option::None => Option::None,
        }
    }

    fn get_halfw(ref self: ELFLoader, data: @Array<u8>, offset: u32) -> Option<u16> {
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

    fn get_w(ref self: ELFLoader, data: @Array<u8>, offset: u32) -> Option<u32> {
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

    fn load(ref self: ELFLoader, data: @Array<u8>, ref machine: RISCVMachine) -> bool {
        // parse elf header
        if !self.parse_elf_header(data, ref machine) {
            return false;
        }

        // parse section headers
        if !self.parse_section_headers(data, ref machine) {
            return false;
        }

        // parse program headers
        if !self.parse_program_headers(data, ref machine) {
            return false;
        }

        true
    }

    fn parse_section_headers(
        ref self: ELFLoader, data: @Array<u8>, ref machine: RISCVMachine
    ) -> bool {
        // The section headers start at e_shoff and are e_shnum in number, each with a size of e_shentsize.
        // The section header string table index is e_shstrndx.

        let mut section_index = 0;
        let mut offset = self.e_shoff;
        let mut res = true;

        loop {
            // check for termination
            if section_index == self.e_shnum {
                break;
            }

            // read section header

            // sh_name
            // An offset to a string in the .shstrtab section that represents the name of this section.
            let _sh_name = match self.get_w(data, offset + 0x00) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // sh_type
            let _sh_type = match self.get_w(data, offset + 0x04) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

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

            // sh_link
            let _sh_link = match self.get_w(data, offset + 0x18) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // sh_info
            let _sh_info = match self.get_w(data, offset + 0x1C) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // sh_addralign
            let _sh_addralign = match self.get_w(data, offset + 0x20) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // sh_entsize
            let _sh_entsize = match self.get_w(data, offset + 0x24) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // load section into memory
            let mut file_cursor = sh_offset;
            let mut mem_cursor = sh_addr;
            loop {
                if file_cursor >= sh_offset + sh_size {
                    break;
                }

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

    fn parse_program_headers(
        ref self: ELFLoader, data: @Array<u8>, ref machine: RISCVMachine
    ) -> bool {
        // The program header table tells the system how to create a process image.
        // It is found at file offset e_phoff, and consists of e_phnum entries, each with size e_phentsize.

        let mut prog_index = 0;
        let mut offset = self.e_phoff;
        let mut res = true;
        loop {
            // check for termination
            if prog_index == self.e_phnum {
                break;
            }

            // read program header

            // type
            match self.get_w(data, offset + 0x00) {
                Option::Some(v) => {
                    if v == 0x00000001 { // PT_LOAD
                    // this is a loadable segment
                    } else {
                        // ignore non-loadable segments
                        continue;
                    }
                },
                Option::None => {
                    res = false;
                    break;
                },
            };

            // Offset of the segment in the file image
            let _p_offset = match self.get_w(data, offset + 0x04) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // Virtual address of the segment in memory
            let p_vaddr = match self.get_w(data, offset + 0x08) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // Physical address
            let _p_paddr = match self.get_w(data, offset + 0x0C) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // Size of the segment in the file image
            let _p_filesz = match self.get_w(data, offset + 0x10) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // Size of the segment in memory
            let p_memsz = match self.get_w(data, offset + 0x14) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // set program end
            machine.set_prog_end(wrap_add(p_vaddr, p_memsz));

            // Flags
            let _p_flags = match self.get_w(data, offset + 0x18) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            // Alignment
            let _p_align = match self.get_w(data, offset + 0x1C) {
                Option::Some(v) => v,
                Option::None => {
                    res = false;
                    break;
                },
            };

            
            //// Load segment into machine memory
            //let mut file_cursor = p_offset;
            //let mut mem_cursor = p_vaddr;
            //loop {
            //    if file_cursor >= p_offset + p_filesz {
            //        break;
            //    }
            //
            //    let entry = match self.get_byte(data, file_cursor) {
            //        Option::Some(v) => v,
            //        Option::None => {
            //            res = false;
            //            break;
            //        },
            //    };
            //
            //    machine.mem_set(mem_cursor, entry);
            //
            //    file_cursor += 1;
            //    mem_cursor += 1;
            //};
            //if res == false {
            //    break;
            //}
            

            // update cursor
            prog_index += 1;
            offset += self.e_phentsize.into();
        };
        res
    }

    fn parse_elf_header(ref self: ELFLoader, data: @Array<u8>, ref machine: RISCVMachine) -> bool {
        // magic
        match self.get_byte(data, 0x00 + 0) {
            Option::Some(v) => { if v != 0x7F {
                return false;
            } },
            Option::None => { return false; },
        }
        match self.get_byte(data, 0x00 + 1) {
            Option::Some(v) => { if v != 0x45 {
                return false;
            } },
            Option::None => { return false; },
        }
        match self.get_byte(data, 0x00 + 2) {
            Option::Some(v) => { if v != 0x4c {
                return false;
            } },
            Option::None => { return false; },
        }
        match self.get_byte(data, 0x00 + 3) {
            Option::Some(v) => { if v != 0x46 {
                return false;
            } },
            Option::None => { return false; },
        }

        // bit depth
        match self.get_byte(data, 0x04) {
            Option::Some(v) => {
                if v == 1 {
                    // 32-bit
                    self.format32 = true;
                } else if v == 2 {
                    // 64-bit
                    self.format32 = false;
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

        // version
        match self.get_byte(data, 0x06) {
            Option::Some(v) => { if v != 1 {
                return false;
            } },
            Option::None => { return false; },
        }

        // OS ABI
        match self.get_byte(data, 0x07) {
            Option::Some(v) => { if v != 0 {
                return false;
            } },
            Option::None => { return false; },
        }

        // Ignore OS ABI version at 0x08

        // Ignore padding at 0x09

        // Type
        match self.get_halfw(data, 0x10) {
            Option::Some(v) => {
                if v != 0x02 {
                    // unsupported elf type (only ET_EXEC=0x02 is supported)
                    return false;
                }
            },
            Option::None => { return false; },
        }

        // Machine
        match self.get_halfw(data, 0x12) {
            Option::Some(v) => {
                if v != 0xF3 {
                    // unsupported machine (only EM_RISCV=0xF3 is supported)
                    return false;
                }
            },
            Option::None => { return false; },
        }

        // Version
        match self.get_w(data, 0x14) {
            Option::Some(v) => { if v != 1 {
                return false;
            } },
            Option::None => { return false; },
        }

        // Entry point
        self.e_entry = match self.get_w(data, 0x18) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };
        machine.set_pc(self.e_entry);

        // Program header offset
        self.e_phoff = match self.get_w(data, 0x1C) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Section header offset
        self.e_shoff = match self.get_w(data, 0x20) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Flags
        self.e_flags = match self.get_w(data, 0x24) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Header size
        self.e_ehsize = match self.get_halfw(data, 0x28) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Program header size
        self.e_phentsize = match self.get_halfw(data, 0x2A) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        // Program header count
        self.e_phnum = match self.get_halfw(data, 0x2C) {
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

        // Section header string table index
        self.e_shstrndx = match self.get_halfw(data, 0x32) {
            Option::Some(v) => v,
            Option::None => { return false; },
        };

        true
    }
}
