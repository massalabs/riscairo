#[derive(Drop)]
pub enum FlowControl {
    Continue,
    InvalidInstruction,
    End,
    ECall,
    EBreak,
    URet,
    SRet,
    MRet,
    Wfi
}

pub struct RISCVMachine {
    pc: u32,
    prog_end: u32, // when pc reaches this value, the program ends
    registers: Felt252Dict<u32>,
    mem: Felt252Dict<u8>,
    csrs: Felt252Dict<u32>,
}

impl RISCVMachineDestruct of Destruct<RISCVMachine> {
    fn destruct(self: RISCVMachine) nopanic {
        self.registers.squash();
        self.mem.squash();
        self.csrs.squash();
    }
}

// Warning: divisions in cairo are not rounding the same way as in other languages, so avoid any case of rounding by only doing exact divisions

// decode an u-type instuction
// returns (rd, imm)
fn decode_uinstr(instr: u32) -> (u32, u32) {
    // bits 31-12 of the immediate value (bits 31-12 of the instruction)
    let imm: u32 = instr & 0b11111111111111111111000000000000;

    // destination register (bits 11-7 of the instruction)
    let rd = (instr & 0b111110000000) / 0b10000000;

    (rd, imm)
}

// decode an i-type instuction
// returns (rd, rs1, imm)
fn decode_iinstr(instr: u32) -> (u32, u32, u32) {
    // bits 11-0 of the immediate value (bits 31-20 of the instruction)
    let imm: u32 = (instr & 0b11111111111100000000000000000000) / 0b100000000000000000000;

    // rs1 register (bits 19-15 of the instruction)
    let rs1 = (instr & 0b11111000000000000000) / 0b1000000000000000;

    // destination register (bits 11-7 of the instruction)
    let rd = (instr & 0b111110000000) / 0b10000000;

    (rd, rs1, imm)
}

// decode an r-type instuction
// returns (rd, rs1, rs2)
fn decode_rinstr(instr: u32) -> (u32, u32, u32) {
    // rs2 register (bits 24-20 of the instruction)
    let rs2 = (instr & 0b1111100000000000000000000) / 0b100000000000000000000;

    // rs1 register (bits 19-15 of the instruction)
    let rs1 = (instr & 0b11111000000000000000) / 0b1000000000000000;

    // destination register (bits 11-7 of the instruction)
    let rd = (instr & 0b111110000000) / 0b10000000;

    (rd, rs1, rs2)
}

// decode a j-type instuction
// returns (rd, imm)
fn decode_jinstr(instr: u32) -> (u32, u32) {
    let imm = ((instr & 0b10000000000000000000000000000000) / 0b100000000000) // bit 20
        + ((instr & 0b01111111111000000000000000000000) / 0b100000000000000000000) // bits 10-1
        + ((instr & 0b00000000000100000000000000000000) / 0b1000000000) // bit 11
        + ((instr & 0b00000000000011111111000000000000)); // bits 19-12

    // destination register (bits 11-7 of the instruction)
    let rd = (instr & 0b111110000000) / 0b10000000;

    (rd, imm)
}

// decode a b-type instuction
// returns (rs1, rs2, imm)
fn decode_binstr(instr: u32) -> (u32, u32, u32) {
    let imm = ((instr & 0b10000000000000000000000000000000) / 0b10000000000000000000) // bit 12
        + ((instr & 0b01111110000000000000000000000000) / 0b100000000000000000000) // bits 10-5
        + ((instr & 0b00000000000000000000111100000000) / 0b10000000) // bits 4-1
        + ((instr & 0b00000000000000000000000010000000) * 0b10000); // bit 11

    // rs2 register (bits 24-20 of the instruction)
    let rs2 = (instr & 0b1111100000000000000000000) / 0b100000000000000000000;

    // rs1 register (bits 19-15 of the instruction)
    let rs1 = (instr & 0b11111000000000000000) / 0b1000000000000000;

    (rs1, rs2, imm)
}

// decode funct3 in an instruction
fn decode_funct3(instr: u32) -> u32 {
    // bits 14-12 of the instruction
    (instr & 0b111000000000000) / 0b1000000000000
}

// decode funct7 in an instruction
fn decode_funct7(instr: u32) -> u32 {
    // bits 31-25 of the instruction
    (instr & 0b11111110000000000000000000000000) / 0b10000000000000000000000000
}

// sign-extend a 21-bit value to 32 bits
pub fn sext21(input: u32) -> u32 {
    if (input & 0b100000000000000000000) != 0 {
        // negative
        input | 0b11111111111100000000000000000000
    } else {
        // positive
        input & 0b00000000000011111111111111111111
    }
}

// sign-extend a 12-bit value to 32 bits
pub fn sext12(input: u32) -> u32 {
    if (input & 0b100000000000) != 0 {
        // negative
        input | 0b11111111111111111111100000000000
    } else {
        // positive
        input & 0b00000000000000000000011111111111
    }
}

// sign-extend a 13-bit value to 32 bits
pub fn sext13(input: u32) -> u32 {
    if (input & 0b1000000000000) != 0 {
        // negative
        input | 0b11111111111111111111000000000000
    } else {
        // positive
        input & 0b00000000000000000000111111111111
    }
}

// sign-extend a 16-bit value to 32 bits
pub fn sext16(input: u32) -> u32 {
    if (input & 0b1000000000000000) != 0 {
        // negative
        input | 0b11111111111111111000000000000000
    } else {
        // positive
        input & 0b00000000000000000111111111111111
    }
}

// sign-extend a 8-bit value to 32 bits
pub fn sext8(input: u32) -> u32 {
    if (input & 0b10000000) != 0 {
        // negative
        input | 0b11111111111111111111111110000000
    } else {
        // positive
        input & 0b00000000000000000000000001111111
    }
}

// Interprets a raw u32 (typically a register) as being a 2-complement encoded i32
pub fn decode_signed(input: u32) -> i32 {
    if (input & 0b10000000000000000000000000000000) != 0 {
        // negative: sign-extend
        let tmp_i64: i64 = -(0b100000000000000000000000000000000 - input.into());
        tmp_i64.try_into().unwrap()
    } else {
        // positive
        input.try_into().unwrap()
    }
}

// Encodes a i32 into a raw u32 format using 2-complement 
pub fn encode_signed(input: i32) -> u32 {
    if input >= 0 {
        // positive: simply cast
        input.try_into().unwrap()
    } else {
        // negative: 2-complement encoding
        let tmp_i64: i64 = 0b100000000000000000000000000000000 + input.into();
        tmp_i64.try_into().unwrap()
    }
}

// wrapping 32-bit addition
pub fn wrap_add(a: u32, b: u32) -> u32 {
    let tmp: u64 = a.into() + b.into();
    if tmp > 0xFFFFFFFF {
        (tmp - 0b100000000000000000000000000000000).try_into().unwrap()
    } else {
        tmp.try_into().unwrap()
    }
}

// wrapping 32-bit subtraction
pub fn wrap_sub(a: u32, b: u32) -> u32 {
    let tmp: i64 = a.into() - b.into();
    if tmp < 0 {
        // negative: wrap
        (tmp + 0b100000000000000000000000000000000).try_into().unwrap()
    } else {
        // positive: return
        tmp.try_into().unwrap()
    }
}

// raw bit shift left
pub fn shl(mut v: u32, mut shift: u32) -> u32 {
    while shift != 0 {
        v = (v & 0b01111111111111111111111111111111) * 2;
        shift -= 1;
    };
    v
}

// raw bit shift right
pub fn shr(mut v: u32, mut shift: u32) -> u32 {
    while shift != 0 {
        v = (v & 0b01111111111111111111111111111110) / 2;
        shift -= 1;
    };
    v
}

// arithmetic bit shift right
pub fn shrs(mut v: u32, mut shift: u32) -> u32 {
    while shift != 0 {
        let high_bit = v & 0b10000000000000000000000000000000;
        v = ((v & 0b11111111111111111111111111111110) / 2) | high_bit;
        shift -= 1;
    };
    v
}

// arithmetic bit shift left
pub fn shls(mut v: u32, mut shift: u32) -> u32 {
    while shift != 0 {
        let high_bit = v & 0b10000000000000000000000000000000;
        v = ((v & 0b00111111111111111111111111111111) * 2) | high_bit;
        shift -= 1;
    };
    v
}

// convert u32 to little-endian representation
pub fn to_le(v: u32) -> u32 {
    // most significant byte is b0
    let b0 = (v & 0b11111111000000000000000000000000) / 0b1000000000000000000000000;
    let b1 = (v & 0b00000000111111110000000000000000) / 0b10000000000000000;
    let b2 = (v & 0b00000000000000001111111100000000) / 0b100000000;
    let b3 = (v & 0b00000000000000000000000011111111);

    // put the most significant byte last in the generated number
    b0 + (b1 * 0b100000000) + (b2 * 0b10000000000000000) + (b3 * 0b1000000000000000000000000)
}

// parse an u32 from its little-endian representation
pub fn from_le(v: u32) -> u32 {
    // most significant byte is b0
    let b3 = (v & 0b11111111000000000000000000000000) / 0b1000000000000000000000000;
    let b2 = (v & 0b00000000111111110000000000000000) / 0b10000000000000000;
    let b1 = (v & 0b00000000000000001111111100000000) / 0b100000000;
    let b0 = (v & 0b00000000000000000000000011111111);

    // put the most significant byte last in the generated number
    b3 + (b2 * 0b100000000) + (b1 * 0b10000000000000000) + (b0 * 0b1000000000000000000000000)
}

#[generate_trait]
pub impl RISCVMachineImpl of RISCVMachineTrait {
    fn new() -> RISCVMachine {
        RISCVMachine {
            pc: 0,
            prog_end: 0,
            registers: Default::default(),
            mem: Default::default(),
            csrs: Default::default(),
        }
    }

    fn mem_get(ref self: RISCVMachine, offset: u32) -> u8 {
        self.mem.get(offset.into())
    }

    fn mem_set(ref self: RISCVMachine, offset: u32, value: u8) {
        self.mem.insert(offset.into(), value);
    }

    fn get_pc(ref self: RISCVMachine) -> u32 {
        self.pc
    }

    fn set_pc(ref self: RISCVMachine, pc: u32) {
        self.pc = pc;
    }

    // get a register value
    fn get_r(ref self: RISCVMachine, r: u32) -> Option<u32> {
        if r > 31 {
            // invalid register
            return Option::None;
        }
        if r == 0 {
            // r0 is hardcoded to 0
            return Option::Some(0);
        }
        Option::Some(self.registers.get(r.into()))
    }

    // set a register value
    fn set_r(ref self: RISCVMachine, r: u32, value: u32) -> bool {
        if r > 31 {
            // invalid register
            return false;
        }
        if r == 0 {
            // r0 is hardcoded to 0: ignore the write
            return true;
        }
        self.registers.insert(r.into(), value);
        true
    }

    // set prog_end
    fn set_prog_end(ref self: RISCVMachine, prog_end: u32) {
        self.prog_end = prog_end;
    }

    // get a CSR value
    // for now, no particular CSR is implemented and no access checks are done
    fn get_csr(ref self: RISCVMachine, csr: u32) -> Option<u32> {
        if csr > 0xFFF {
            // invalid CSR
            return Option::None;
        }
        Option::Some(self.csrs.get(csr.into()))
    }

    // set a CSR value
    // for now, no particular CSR is implemented and no advanced access checks are done
    fn set_csr_checked(ref self: RISCVMachine, csr: u32, value: u32) -> bool {
        if csr > 0xFFF {
            // invalid CSR
            return false;
        }
        if (csr & 0b110000000000) == 0b110000000000 {
            // this CSR is read-only
            if value != self.csrs.get(csr.into()) {
                // as such, its value should not change
                return false;
            }
        }
        self.csrs.insert(csr.into(), value);
        true
    }

    // force-set a CSR value
    fn set_csr(ref self: RISCVMachine, csr: u32, value: u32) -> bool {
        if csr > 0xFFF {
            // invalid CSR
            return false;
        }
        self.csrs.insert(csr.into(), value);
        true
    }

    // returns true to halt
    fn execute_instr(ref self: RISCVMachine, instr: u32) -> FlowControl {
        // print the instruction in binary
        if (instr & 0b11 != 0b11) {
            return FlowControl::InvalidInstruction;
        }
        let mut return_v = FlowControl::Continue;
        match ((instr & 0b1111100) / 0b100) {
            0b00000 => {
                // memory load instructions
                let (rd, rs1, imm) = decode_iinstr(instr);
                let rs1_v = match self.get_r(rs1) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                let offset = sext12(imm);
                let outv = match decode_funct3(instr) {
                    0b000 => {
                        // lb
                        let base_offset = wrap_add(rs1_v, offset);
                        let b1: u32 = self.mem_get(base_offset).into();
                        sext8(b1)
                    },
                    0b001 => {
                        // lh
                        let base_offset = wrap_add(rs1_v, offset);
                        let b1: u32 = self.mem_get(base_offset).into();
                        let b2: u32 = self.mem_get(wrap_add(base_offset, 1)).into();
                        // little-endian means b1 is the least significant byte
                        let res = b1 + (b2 * 0b100000000);
                        sext16(res)
                    },
                    0b010 => {
                        // lw
                        let base_offset = wrap_add(rs1_v, offset);
                        let b1: u32 = self.mem_get(base_offset).into();
                        let b2: u32 = self.mem_get(wrap_add(base_offset, 1)).into();
                        let b3: u32 = self.mem_get(wrap_add(base_offset, 2)).into();
                        let b4: u32 = self.mem_get(wrap_add(base_offset, 3)).into();
                        // little-endian means b1 is the least significant byte
                        b1
                            + (b2 * 0b100000000)
                            + (b3 * 0b10000000000000000)
                            + (b4 * 0b1000000000000000000000000)
                    },
                    0b011 => { return FlowControl::InvalidInstruction; },
                    0b100 => {
                        // lbu
                        let base_offset = wrap_add(rs1_v, offset);
                        self.mem_get(base_offset).into()
                    },
                    0b101 => {
                        // lhu
                        let base_offset = wrap_add(rs1_v, offset);
                        let b1: u32 = self.mem_get(base_offset).into();
                        let b2: u32 = self.mem_get(wrap_add(base_offset, 1)).into();
                        b1 + (b2 * 0b100000000)
                    },
                    0b110 => { return FlowControl::InvalidInstruction; },
                    0b111 => { return FlowControl::InvalidInstruction; },
                    _ => { return FlowControl::InvalidInstruction; },
                };
                if !self.set_r(rd, outv) {
                    return FlowControl::InvalidInstruction;
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b00001 => { return FlowControl::InvalidInstruction; },
            0b00010 => { return FlowControl::InvalidInstruction; },
            0b00011 => {
                // fence / fence.i: ignore for now
                // TODO at least check validity in the future
                self.pc = wrap_add(self.pc, 4);
            },
            0b00100 => {
                match decode_funct3(instr) {
                    0b000 => {
                        // addi
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, wrap_add(rs1_v, sext12(imm))) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b001 => {
                        // slli
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let shift = imm & 0b00000000000000000000000000011111;
                        // note: the 6th bit of imm is used only in RV64
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, shl(rs1_v, shift)) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b010 => {
                        // slti
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let res = if decode_signed(rs1_v) < decode_signed(sext12(imm)) {
                            1
                        } else {
                            0
                        };
                        if !self.set_r(rd, res) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b011 => {
                        // sltiu
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let res = if rs1_v < sext12(imm) {
                            1
                        } else {
                            0
                        };
                        if !self.set_r(rd, res) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b100 => {
                        // xori
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let res = rs1_v ^ sext12(imm);
                        if !self.set_r(rd, res) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b101 => {
                        // binary shifts
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let subtype = (imm & 0b1111100000000000000000000000000)
                            / 0b100000000000000000000000000;
                        let shift = imm & 0b00000000000000000000000000011111;
                        // note: the 6th bit of imm is used only in RV64
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let res = if subtype == 0b00000 {
                            // srli
                            shr(rs1_v, shift)
                        } else if subtype == 0b01000 {
                            // srai
                            shrs(rs1_v, shift)
                        } else {
                            return FlowControl::InvalidInstruction;
                        };
                        if !self.set_r(rd, res) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b110 => {
                        // ori
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let res = rs1_v | sext12(imm);
                        if !self.set_r(rd, res) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b111 => {
                        // andi
                        let (rd, rs1, imm) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let res = rs1_v & sext12(imm);
                        if !self.set_r(rd, res) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    _ => { return FlowControl::InvalidInstruction; },
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b00101 => {
                // auipc
                let (rd, imm) = decode_uinstr(instr);
                if !self.set_r(rd, wrap_add(self.pc, imm)) {
                    return FlowControl::InvalidInstruction;
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b00110 => { return FlowControl::InvalidInstruction; },
            0b00111 => { return FlowControl::InvalidInstruction; },
            0b01000 => {
                // memory store instructions
                let offset_h = decode_funct7(instr);
                let funct3 = decode_funct3(instr);
                let (offset_l, rs1, rs2) = decode_rinstr(instr);
                let offset = sext12((offset_h * 0b100000) + offset_l);
                let rs1_v = match self.get_r(rs1) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                let rs2_v = match self.get_r(rs2) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                match funct3 {
                    0b000 => {
                        // sb
                        let base_offset = wrap_add(rs1_v, offset);
                        self.mem_set(base_offset, (rs2_v & 0b11111111).try_into().unwrap());
                    },
                    0b001 => {
                        // sh
                        // warning: little-endian
                        let base_offset = wrap_add(rs1_v, offset);
                        let b1: u8 = (rs2_v & 0b11111111).try_into().unwrap();
                        let b2: u8 = ((rs2_v & 0b1111111100000000) / 0b100000000)
                            .try_into()
                            .unwrap();
                        self.mem_set(base_offset, b1);
                        self.mem_set(wrap_add(base_offset, 1), b2);
                    },
                    0b010 => {
                        // sw
                        // warning: little-endian
                        let base_offset = wrap_add(rs1_v, offset);
                        let b1: u8 = (rs2_v & 0b11111111).try_into().unwrap();
                        let b2: u8 = ((rs2_v & 0b1111111100000000) / 0b100000000)
                            .try_into()
                            .unwrap();
                        let b3: u8 = ((rs2_v & 0b111111110000000000000000) / 0b10000000000000000)
                            .try_into()
                            .unwrap();
                        let b4: u8 = ((rs2_v & 0b11111111000000000000000000000000)
                            / 0b1000000000000000000000000)
                            .try_into()
                            .unwrap();
                        self.mem_set(base_offset, b1);
                        self.mem_set(wrap_add(base_offset, 1), b2);
                        self.mem_set(wrap_add(base_offset, 2), b3);
                        self.mem_set(wrap_add(base_offset, 3), b4);
                    },
                    0b011 => { return FlowControl::InvalidInstruction; },
                    0b100 => { return FlowControl::InvalidInstruction; },
                    0b101 => { return FlowControl::InvalidInstruction; },
                    0b110 => { return FlowControl::InvalidInstruction; },
                    0b111 => { return FlowControl::InvalidInstruction; },
                    _ => { return FlowControl::InvalidInstruction; },
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b01001 => { return FlowControl::InvalidInstruction; },
            0b01010 => { return FlowControl::InvalidInstruction; },
            0b01011 => { return FlowControl::InvalidInstruction; },
            0b01100 => {
                let funct7 = decode_funct7(instr);
                let funct3 = decode_funct3(instr);
                let (rd, rs1, rs2) = decode_rinstr(instr);
                let rs1_v = match self.get_r(rs1) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                let rs2_v = match self.get_r(rs2) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                let res = if funct7 == 0b0000000 && funct3 == 0b000 {
                    // add
                    wrap_add(rs1_v, rs2_v)
                } else if funct7 == 0b0100000 && funct3 == 0b000 {
                    // sub
                    wrap_sub(rs1_v, rs2_v)
                } else if funct7 == 0b0000000 && funct3 == 0b001 {
                    // sll
                    shl(rs1_v, rs2_v & 0b11111)
                } else if funct7 == 0b0000000 && funct3 == 0b010 {
                    // slt
                    if decode_signed(rs1_v) < decode_signed(rs2_v) {
                        1
                    } else {
                        0
                    }
                } else if funct7 == 0b0000000 && funct3 == 0b011 {
                    // sltu
                    if rs1_v < rs2_v {
                        1
                    } else {
                        0
                    }
                } else if funct7 == 0b0000000 && funct3 == 0b100 {
                    // xor
                    rs1_v ^ rs2_v
                } else if funct7 == 0b0000000 && funct3 == 0b101 {
                    // srl
                    shr(rs1_v, rs2_v & 0b11111)
                } else if funct7 == 0b0100000 && funct3 == 0b101 {
                    // sra
                    shrs(rs1_v, rs2_v & 0b11111)
                } else if funct7 == 0b0000000 && funct3 == 0b110 {
                    // or
                    rs1_v | rs2_v
                } else if funct7 == 0b0000000 && funct3 == 0b111 {
                    // and
                    rs1_v & rs2_v
                } else {
                    return FlowControl::InvalidInstruction;
                };
                if !self.set_r(rd, res) {
                    return FlowControl::InvalidInstruction;
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b01101 => {
                // lui
                let (rd, imm) = decode_uinstr(instr);
                if !self.set_r(rd, imm) {
                    return FlowControl::InvalidInstruction;
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b01110 => { return FlowControl::InvalidInstruction; },
            0b01111 => { return FlowControl::InvalidInstruction; },
            0b10000 => { return FlowControl::InvalidInstruction; },
            0b10001 => { return FlowControl::InvalidInstruction; },
            0b10010 => { return FlowControl::InvalidInstruction; },
            0b10011 => { return FlowControl::InvalidInstruction; },
            0b10100 => { return FlowControl::InvalidInstruction; },
            0b10101 => { return FlowControl::InvalidInstruction; },
            0b10110 => { return FlowControl::InvalidInstruction; },
            0b10111 => { return FlowControl::InvalidInstruction; },
            0b11000 => {
                // conditional branches
                let funct3 = decode_funct3(instr);
                let (rs1, rs2, imm) = decode_binstr(instr);
                let rs1_v = match self.get_r(rs1) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                let rs2_v = match self.get_r(rs2) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                match funct3 {
                    0b000 => {
                        // beq
                        if rs1_v == rs2_v {
                            self.pc = wrap_add(self.pc, sext13(imm));
                        } else {
                            self.pc = wrap_add(self.pc, 4);
                        }
                    },
                    0b001 => {
                        // bne
                        if rs1_v != rs2_v {
                            self.pc = wrap_add(self.pc, sext13(imm));
                        } else {
                            self.pc = wrap_add(self.pc, 4);
                        }
                    },
                    0b010 => { return FlowControl::InvalidInstruction; },
                    0b011 => { return FlowControl::InvalidInstruction; },
                    0b100 => {
                        // blt
                        if decode_signed(rs1_v) < decode_signed(rs2_v) {
                            self.pc = wrap_add(self.pc, sext13(imm));
                        } else {
                            self.pc = wrap_add(self.pc, 4);
                        }
                    },
                    0b101 => {
                        // bge
                        if decode_signed(rs1_v) >= decode_signed(rs2_v) {
                            self.pc = wrap_add(self.pc, sext13(imm));
                        } else {
                            self.pc = wrap_add(self.pc, 4);
                        }
                    },
                    0b110 => {
                        // bltu
                        if rs1_v < rs2_v {
                            self.pc = wrap_add(self.pc, sext13(imm));
                        } else {
                            self.pc = wrap_add(self.pc, 4);
                        }
                    },
                    0b111 => {
                        // bgeu
                        if rs1_v >= rs2_v {
                            self.pc = wrap_add(self.pc, sext13(imm));
                        } else {
                            self.pc = wrap_add(self.pc, 4);
                        }
                    },
                    _ => { return FlowControl::InvalidInstruction; },
                };
            },
            0b11001 => {
                // jalr
                let (rd, rs1, imm) = decode_iinstr(instr);
                let rs1_v = match self.get_r(rs1) {
                    Option::Some(v) => v,
                    Option::None => { return FlowControl::InvalidInstruction; },
                };
                let tmp = wrap_add(self.pc, 4);
                self.pc = wrap_add(rs1_v, sext12(imm)) & 0b11111111111111111111111111111110;
                if !self.set_r(rd, tmp) {
                    return FlowControl::InvalidInstruction;
                }
            },
            0b11010 => { return FlowControl::InvalidInstruction; },
            0b11011 => {
                // jal
                let (rd, imm) = decode_jinstr(instr);
                if !self.set_r(rd, wrap_add(self.pc, 4)) {
                    return FlowControl::InvalidInstruction;
                }
                self.pc = wrap_add(self.pc, sext21(imm));
            },
            0b11100 => {
                match decode_funct3(instr) {
                    0b000 => {
                        if instr == 0b00000_00_00000_00000_000_00000_11100_11 {
                            // ecall
                            return_v = FlowControl::ECall;
                        } else if instr == 0b00000_00_00001_00000_000_00000_11100_11 {
                            // ebreak
                            return_v = FlowControl::EBreak;
                        } else if instr == 0b00000_00_00010_00000_000_00000_11100_11 {
                            // uret
                            return_v = FlowControl::URet;
                        } else if instr == 0b00010_00_00010_00000_000_00000_11100_11 {
                            // sret
                            return_v = FlowControl::SRet;
                        } else if instr == 0b00110_00_00010_00000_000_00000_11100_11 {
                            // mret
                            return_v = FlowControl::MRet;
                        } else if instr == 0b00010_00_00101_00000_000_00000_11100_11 {
                            // wfi
                            return_v = FlowControl::Wfi;
                        } else if (instr
                            & 0b11111_11_00000_00000_111_00000_11111_11) == 0b00010_01_00000_00000_000_00000_11100_11 { // sfence.vma
                        // ignore for now
                        } else {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b001 => {
                        // csrrw
                        let (rd, rs1, csr) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let old_csr_value = match self.get_csr(csr) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, old_csr_value) {
                            return FlowControl::InvalidInstruction;
                        }
                        if !self.set_csr_checked(csr, rs1_v) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b010 => {
                        // csrrs
                        let (rd, rs1, csr) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let old_csr_value = match self.get_csr(csr) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, old_csr_value) {
                            return FlowControl::InvalidInstruction;
                        }
                        if !self.set_csr_checked(csr, old_csr_value | rs1_v) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b011 => {
                        // csrrc
                        let (rd, rs1, csr) = decode_iinstr(instr);
                        let rs1_v = match self.get_r(rs1) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        let old_csr_value = match self.get_csr(csr) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, old_csr_value) {
                            return FlowControl::InvalidInstruction;
                        }
                        if !self.set_csr_checked(csr, old_csr_value & ~rs1_v) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b100 => { return FlowControl::InvalidInstruction; },
                    0b101 => {
                        // csrrwi
                        let (rd, rs1, csr) = decode_iinstr(instr);
                        let old_csr_value = match self.get_csr(csr) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, old_csr_value) {
                            return FlowControl::InvalidInstruction;
                        }
                        if !self.set_csr_checked(csr, rs1) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b110 => {
                        // csrrsi
                        let (rd, rs1, csr) = decode_iinstr(instr);
                        let old_csr_value = match self.get_csr(csr) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, old_csr_value) {
                            return FlowControl::InvalidInstruction;
                        }
                        if !self.set_csr_checked(csr, old_csr_value | rs1) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    0b111 => {
                        // csrrci
                        let (rd, rs1, csr) = decode_iinstr(instr);
                        let old_csr_value = match self.get_csr(csr) {
                            Option::Some(v) => v,
                            Option::None => { return FlowControl::InvalidInstruction; },
                        };
                        if !self.set_r(rd, old_csr_value) {
                            return FlowControl::InvalidInstruction;
                        }
                        if !self.set_csr_checked(csr, old_csr_value & ~rs1) {
                            return FlowControl::InvalidInstruction;
                        }
                    },
                    _ => { return FlowControl::InvalidInstruction; },
                }
                self.pc = wrap_add(self.pc, 4);
            },
            0b11101 => { return FlowControl::InvalidInstruction; },
            0b11110 => { return FlowControl::InvalidInstruction; },
            0b11111 => { return FlowControl::InvalidInstruction; },
            _ => { return FlowControl::InvalidInstruction; },
        }

        return_v
    }

    // runs a program step (instruction)
    fn step(ref self: RISCVMachine) -> FlowControl {
        // check for program end
        if self.pc >= self.prog_end {
            return FlowControl::End;
        }

        // construct a full instruction from the pc (4 bytes)
        let instr1: u32 = self.mem_get(self.pc).into();
        let instr2: u32 = self.mem_get(wrap_add(self.pc, 1)).into();
        let instr3: u32 = self.mem_get(wrap_add(self.pc, 2)).into();
        let instr4: u32 = self.mem_get(wrap_add(self.pc, 3)).into();
        // little endian (MSB at highest address)
        let instr: u32 = instr4 * 0b1000000000000000000000000
            + instr3 * 0b10000000000000000
            + instr2 * 0b100000000
            + instr1;
        self.execute_instr(instr)
    }
}
