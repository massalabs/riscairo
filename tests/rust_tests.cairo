use snforge_std::fs::{FileTrait, read_txt};
use riscairo::riscv_call;
use super::tools::load_file;

fn run_fn(func_name: @ByteArray, args: @ByteArray) -> ByteArray {
    // load ELF file
    let file_path: ByteArray = "test_elfs/rust_tests/out/rust_tests";
    let bytecode = load_file(file_path);

    // call the function
    riscv_call(@bytecode, func_name, args)
}

#[test]
fn test_cpu_add() {
    let mut args: ByteArray = "";
    args.append_byte(1);
    args.append_byte(3);
    let res = run_fn(@"add", @args);
    assert_eq!(res.len(), 1, "Unexpected return value length");
    assert_eq!(res[0], args[0] + args[1], "Unexpected return value");
}

#[test]
fn test_cpu_sub() {
    let mut args: ByteArray = "";
    args.append_byte(7);
    args.append_byte(3);
    let res = run_fn(@"sub", @args);
    assert_eq!(res.len(), 1, "Unexpected return value length");
    assert_eq!(res[0], args[0] - args[1], "Unexpected return value");
}

#[test]
fn test_cpu_prepend_hello() {
    let mut args: ByteArray = "world";
    let res = run_fn(@"prepend_hello", @args);
    assert_eq!(res, "hello world", "Unexpected return value");
}

