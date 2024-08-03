use snforge_std::fs::{FileTrait, read_txt};
use riscairo::riscv_call;
use super::tools::load_file;

fn run_fn(func_name: @ByteArray, args: @Array<u8>) -> Array<u8> {
    // load ELF file
    let file_path: ByteArray = "test_elfs/rust_tests/out/rust_tests";
    let bytecode = load_file(file_path);

    // call the function
    riscv_call(@bytecode, func_name, args)
}

#[test]
fn test_cpu_add() {
    let mut args = ArrayTrait::<u8>::new();
    args.append(1);
    args.append(3);
    let res = run_fn(@"add", @args);
    assert_eq!(res.len(), 1, "Unexpected return value length");
    assert_eq!(*res.at(0), *args.at(0) + *args.at(1), "Unexpected return value");
}

#[test]
fn test_cpu_sub() {
    let mut args = ArrayTrait::<u8>::new();
    args.append(7);
    args.append(3);
    let res = run_fn(@"sub", @args);
    assert_eq!(res.len(), 1, "Unexpected return value length");
    assert_eq!(*res.at(0), *args.at(0) - *args.at(1), "Unexpected return value");
}

#[test]
fn test_cpu_prepend_hello() {
    let mut args_txt: ByteArray = "world";
    let mut args = ArrayTrait::<u8>::new();
    let mut i = 0;
    while i < args_txt.len() {
        args.append(args_txt[i]);
        i += 1;
    };
    let res = run_fn(@"prepend_hello", @args);
    let mut res_txt: ByteArray = "";
    let mut j = 0;
    while j < res.len() {
        res_txt.append_byte(*res.at(j));
        j += 1;
    };
    assert_eq!(res_txt, "hello world", "Unexpected return value");
}

