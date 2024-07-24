mod riscv;
mod elf;

use riscv::{RISCVMachineTrait, FlowControl};
use elf::ELFLoaderTrait;

pub fn run_riscvelf(
    elf_data: @Array<u8>, funct_name: ByteArray, params: ByteArray
) -> Result<ByteArray, ByteArray> {
    let mut elf_loader = ELFLoaderTrait::new();
    let mut machine = RISCVMachineTrait::new();

    let res = elf_loader.load(elf_data, ref machine);
    if !res {
        println!("Failed to load ELF");
        return Result::Err("Failed to load ELF");
    }

    // run the machine
    let mut success = true;
    loop {
        match machine.step() {
            FlowControl::Continue => {},
            FlowControl::End => {
                println!("EOF");
                break;
            },
            FlowControl::InvalidInstruction => {
                println!("Invalid instruction");
                success = false;
                break;
            },
            FlowControl::ECall => { println!("ECall"); },
            FlowControl::EBreak => { println!("EBreak"); },
            FlowControl::URet => { println!("URet"); },
            FlowControl::SRet => { println!("SRet"); },
            FlowControl::MRet => { println!("MRet"); },
            FlowControl::Wfi => {
                // interrupt on wfi because that's how this particular program signals that it has finished
                break;
            },
        };
    };
    if !success {
        return Result::Err("Program execution failed");
    }

    // read the output registry
    let mut indx: u32 = 0x10000000;
    let mut res_string: ByteArray = "";
    loop {
        if indx == 0x10000000 + 13 {
            break;
        }
        let v = machine.mem_get(indx);
        res_string.append_byte(v);
        indx += 1;
    };

    return Result::Ok(res_string);
}
