pub mod riscv;
pub mod elf;
pub mod bytes;
use utils::traits::bytes::{ToBytes, FromBytes};


use riscairo::riscv::{RISCVMachineTrait, RISCVMachine, FlowControl};
use riscairo::elf::ELFLoaderTrait;
// use riscairo::bytes::{ToBytes, FromBytes};

const ECALL_CATEGORY_PANIC: u32 = 1;
const ECALL_CATEGORY_RETURN: u32 = 2;

const IN_ORIGIN: u32 = 0x30000000;
const IN_FUNCT_NAME_LEN_OFFSET: u32 = IN_ORIGIN + 0;
const IN_FUNCT_NAME_OFFSET: u32 = IN_FUNCT_NAME_LEN_OFFSET + 4;
const IN_FUNCT_ARGS_LEN_OFFSET: u32 = IN_FUNCT_NAME_OFFSET + 255;
const IN_FUNCT_ARGS_OFFSET: u32 = IN_FUNCT_ARGS_LEN_OFFSET + 4;

fn write_args_to_ram(ref machine: RISCVMachine, input_func: @ByteArray, input_args: Span<u8>) {
    let input_func_len = input_func.len();
    let input_args_len = input_args.len();

    // set the input length in RAM. Warning: little endian
    machine
        .mem_set(IN_FUNCT_NAME_LEN_OFFSET + 0, (input_func_len & 0x000000FF).try_into().unwrap());
    machine
        .mem_set(
            IN_FUNCT_NAME_LEN_OFFSET + 1, ((input_func_len & 0x0000FF00) / 256).try_into().unwrap()
        );
    machine
        .mem_set(
            IN_FUNCT_NAME_LEN_OFFSET + 2,
            ((input_func_len & 0x00FF0000) / 65536).try_into().unwrap()
        );
    machine
        .mem_set(
            IN_FUNCT_NAME_LEN_OFFSET + 3,
            ((input_func_len & 0xFF000000) / 16777216).try_into().unwrap()
        );

    // set the func name in RAM using a loop
    let mut i: u32 = 0;
    while i < input_func_len {
        machine.mem_set(IN_FUNCT_NAME_OFFSET + i, input_func[i]);
        i += 1;
    };

    // set the input args length in RAM. Warning: little endian
    machine
        .mem_set(IN_FUNCT_ARGS_LEN_OFFSET + 0, (input_args_len & 0x000000FF).try_into().unwrap());
    machine
        .mem_set(
            IN_FUNCT_ARGS_LEN_OFFSET + 1, ((input_args_len & 0x0000FF00) / 256).try_into().unwrap()
        );
    machine
        .mem_set(
            IN_FUNCT_ARGS_LEN_OFFSET + 2,
            ((input_args_len & 0x00FF0000) / 65536).try_into().unwrap()
        );
    machine
        .mem_set(
            IN_FUNCT_ARGS_LEN_OFFSET + 3,
            ((input_args_len & 0xFF000000) / 16777216).try_into().unwrap()
        );

    // set the input args in RAM using a loop
    let mut j: u32 = 0;
    while j < input_args_len {
        machine.mem_set(IN_FUNCT_ARGS_OFFSET + j, *input_args.at(j));
        j += 1;
    };
}

pub fn riscv_call<A, R, +ToBytes<A>, +FromBytes<R>>(
    bytecode: Span<u8>, func_name: @ByteArray, args: A
) -> R {
    riscv_call_impl(bytecode, func_name, args.to_le_bytes())
        .span()
        .from_le_bytes()
        .unwrap()
}

fn riscv_call_impl(bytecode: Span<u8>, func_name: @ByteArray, args: Span<u8>) -> Array<u8> {
    // load ELF file
    let mut machine = RISCVMachineTrait::new();
    let mut elf_loader = ELFLoaderTrait::new();

    // parse ELF data and load initial CPU and RAM states
    if !elf_loader.load(bytecode, ref machine) {
        panic!("Failed to parse ELF data.");
    }

    // set the input data in RAM
    write_args_to_ram(ref machine, func_name, args);

    // run the machine
    loop {
        match machine.step() {
            FlowControl::Continue => {},
            FlowControl::InvalidInstruction => { panic!("CPU signalled an invalid instruction."); },
            FlowControl::ECall => { break; },
            FlowControl::EBreak => {},
            FlowControl::URet => {},
            FlowControl::SRet => {},
            FlowControl::MRet => {},
            FlowControl::Wfi => {},
        };
    };

    // read output
    let category: u32 = machine.get_r(10).unwrap();
    let len: u32 = machine.get_r(11).unwrap();
    let addr: u32 = machine.get_r(12).unwrap();
    let mut res_bytes = ArrayTrait::<u8>::new();
    if category == ECALL_CATEGORY_PANIC {
        let mut res_msg: ByteArray = "";
        let mut i: u32 = 0;
        while i < len {
            res_msg.append_byte(machine.mem_get(addr + i));
            i += 1;
        };
        panic!("CPU: Guest panicked: {}", res_msg);
    } else if category == ECALL_CATEGORY_RETURN {
        let mut i: u32 = 0;
        while i < len {
            res_bytes.append(machine.mem_get(addr + i));
            i += 1;
        };
    } else {
        panic!("CPU: Unknown ECall category: {}", category);
    }
    res_bytes
}
