use riscairo::riscv::{RISCVMachineTrait, RISCVMachine};
use riscairo::elf::ELFLoaderTrait;
use snforge_std::fs::{FileTrait, read_txt};

pub fn load_elf(file_path: ByteArray) -> RISCVMachine {    
    // Read ELF file
    let elf_file = FileTrait::new(file_path);
    let elf_arr = read_txt(@elf_file);
    let mut elf_bytes: Array<u8> = ArrayTrait::new();
    let mut i: u32 = 0;
    loop {
        if i >= elf_arr.len() {
            break;
        }
        elf_bytes.append(elf_arr.at(i).clone().try_into().unwrap());
        i += 1;
    };
    let mut machine = RISCVMachineTrait::new();
    let mut elf_loader = ELFLoaderTrait::new();

    // parse ELF data and load initial CPU and RAM states
    if !elf_loader.load(@elf_bytes, ref machine) {
        panic!("Failed to parse ELF data.");
    }

    machine
}
