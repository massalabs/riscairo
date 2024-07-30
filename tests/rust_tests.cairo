use snforge_std::fs::{FileTrait, read_txt};
use riscairo::riscv::{RISCVMachineTrait, RISCVMachine, FlowControl};
use super::tools::load_elf;

const ECALL_CATEGORY_PANIC: u32 = 1;
const ECALL_CATEGORY_RETURN: u32 = 2;

const IN_ORIGIN: u32 = 0x30000000;
const IN_FUNCT_NAME_LEN_OFFSET : u32 = IN_ORIGIN + 0;
const IN_FUNCT_NAME_OFFSET : u32 = IN_FUNCT_NAME_LEN_OFFSET + 4;
const IN_FUNCT_ARGS_LEN_OFFSET : u32 = IN_FUNCT_NAME_OFFSET + 255;
const IN_FUNCT_ARGS_OFFSET : u32 = IN_FUNCT_ARGS_LEN_OFFSET + 4;

fn write_args_to_ram(ref machine: RISCVMachine, input_func: @ByteArray, input_args: @ByteArray) {
    let input_func_len = input_func.len();
    let input_args_len = input_args.len();

    // set the input length in RAM. Warning: little endian
    machine.mem_set(IN_FUNCT_NAME_LEN_OFFSET+0, (input_func_len & 0x000000FF).try_into().unwrap());
    machine.mem_set(IN_FUNCT_NAME_LEN_OFFSET+1, ((input_func_len & 0x0000FF00) / 256).try_into().unwrap());
    machine.mem_set(IN_FUNCT_NAME_LEN_OFFSET+2, ((input_func_len & 0x00FF0000) / 65536).try_into().unwrap());
    machine.mem_set(IN_FUNCT_NAME_LEN_OFFSET+3, ((input_func_len & 0xFF000000) / 16777216).try_into().unwrap());

    // set the func name in RAM using a loop
    let mut i: u32 = 0;
    loop {
        if i >= input_func_len {
            break;
        }
        machine.mem_set(IN_FUNCT_NAME_OFFSET+i, input_func[i]);
        i += 1;
    };

    // set the input args length in RAM. Warning: little endian
    machine.mem_set(IN_FUNCT_ARGS_LEN_OFFSET+0, (input_args_len & 0x000000FF).try_into().unwrap());
    machine.mem_set(IN_FUNCT_ARGS_LEN_OFFSET+1, ((input_args_len & 0x0000FF00) / 256).try_into().unwrap());
    machine.mem_set(IN_FUNCT_ARGS_LEN_OFFSET+2, ((input_args_len & 0x00FF0000) / 65536).try_into().unwrap());
    machine.mem_set(IN_FUNCT_ARGS_LEN_OFFSET+3, ((input_args_len & 0xFF000000) / 16777216).try_into().unwrap());

    // set the input args in RAM using a loop
    let mut j: u32 = 0;
    loop {
        if j >= input_args_len {
            break;
        }
        machine.mem_set(IN_FUNCT_ARGS_OFFSET+j, input_args[j]);
        j += 1;
    };
}

fn run_fn(func_name: @ByteArray, args: @ByteArray) -> ByteArray {
    // load ELF file
    let file_path: ByteArray = "test_elfs/rust_tests/out/rust_tests";
    let mut machine = load_elf(file_path);

    // set the input data in RAM
    write_args_to_ram(ref machine, func_name, args);

    // run the machine
    let res = loop {
        let (_instr, ctl) = machine.step();
        match ctl {
            FlowControl::Continue => {},
            FlowControl::InvalidInstruction => {
                panic!("CPU signalled an invalid instruction.");
            },
            FlowControl::ECall => {
                // read output
                let category: u32 = machine.get_r(10).unwrap();
                let len: u32 = machine.get_r(11).unwrap();
                let addr: u32 = machine.get_r(12).unwrap();
                let mut res_bytes: ByteArray = "";
                let mut i: u32 = 0;
                while i < len {
                    let v = machine.mem_get(addr + i);
                    res_bytes.append_byte(v);
                    i += 1;
                };
                if category == ECALL_CATEGORY_PANIC {
                    panic!("CPU: Guest panicked: {}", res_bytes);
                } else if category == ECALL_CATEGORY_RETURN {
                    break res_bytes;
                } else {
                    panic!("CPU: Unknown ECall category: {}", category);
                }
            },
            FlowControl::EBreak => { },
            FlowControl::URet => { },
            FlowControl::SRet => { },
            FlowControl::MRet => { },
            FlowControl::Wfi => { },
        };
    };

    res
}

#[test]
fn test_cpu_add() {
    let mut args: ByteArray = "";
    args.append_byte(1);
    args.append_byte(3);
    let res = run_fn(@"add", @args);
    assert_eq!(res.len(), 1, "Unexpected return value length");
    assert_eq!(res[0], args[0]+args[1], "Unexpected return value");
}

#[test]
fn test_cpu_sub() {
    let mut args: ByteArray = "";
    args.append_byte(7);
    args.append_byte(3);
    let res = run_fn(@"sub", @args);
    assert_eq!(res.len(), 1, "Unexpected return value length");
    assert_eq!(res[0], args[0]-args[1], "Unexpected return value");
}

#[test]
fn test_cpu_prepend_hello() {
    let mut args: ByteArray = "world";
    let res = run_fn(@"prepend_hello", @args);
    assert_eq!(res, "hello world", "Unexpected return value");
}

