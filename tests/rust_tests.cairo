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

fn get_array_10() -> @Array<u8> {
    @array![0x47, 0x44, 0x17, 0x97, 0xDE, 0xFE, 0xBD, 0x1C, 0x19, 0xF0]
}

fn get_array_10_rev() -> @Array<u8> {
    @array![0xF0, 0x19, 0x1C, 0xBD, 0xFE, 0xDE, 0x97, 0x17, 0x44, 0x47]
}

fn get_array_50() -> @Array<u8> {
    @array![
        0x71, 0xcf, 0x32, 0x2b, 0x2e, 0x89, 0x4a, 0x7d, 0x01, 0x62, 0xc6, 0x87, 0x2b, 0x4b, 0x17, 0x79, 
        0x94, 0x27, 0x82, 0x72, 0x89, 0xb5, 0x73, 0x9f, 0x76, 0xca, 0x70, 0x85, 0x02, 0x42, 0x9e, 0x5a, 
        0x3f, 0x7c, 0x75, 0x79, 0x32, 0x07, 0x96, 0x9c, 0x87, 0xe0, 0xfd, 0xdc, 0x13, 0x68, 0x01, 0xa9, 
        0xe6, 0xdc
    ]
}

fn get_array_50_rev() -> @Array<u8> {
    @array![
        0xdc, 0xe6, 0xa9, 0x01, 0x68, 0x13, 0xdc, 0xfd, 0xe0, 0x87, 0x9c, 0x96, 0x07, 0x32, 0x79, 0x75, 
        0x7c, 0x3f, 0x5a, 0x9e, 0x42, 0x02, 0x85, 0x70, 0xca, 0x76, 0x9f, 0x73, 0xb5, 0x89, 0x72, 0x82, 
        0x27, 0x94, 0x79, 0x17, 0x4b, 0x2b, 0x87, 0xc6, 0x62, 0x01, 0x7d, 0x4a, 0x89, 0x2e, 0x2b, 0x32, 
        0xcf, 0x71
    ]
}

fn get_array_100() -> @Array<u8> {
    @array![
        0xfa, 0xbd, 0x28, 0xf6, 0x44, 0x9e, 0x8b, 0x37, 0xcd, 0x6d, 0x06, 0xf7, 0x81, 0xa3, 0x48, 0x96, 
        0x0f, 0x5e, 0x81, 0xec, 0x28, 0xf8, 0xe3, 0x18, 0x78, 0xf7, 0xd8, 0x04, 0xe5, 0xe0, 0xa2, 0x07, 
        0x13, 0x72, 0x1a, 0x0d, 0x8e, 0x63, 0xc5, 0x98, 0xf9, 0xbd, 0x76, 0x66, 0xd8, 0xba, 0x5c, 0x7a, 
        0xfe, 0x24, 0x91, 0x8b, 0x3e, 0x68, 0x7c, 0xa7, 0x2d, 0x5e, 0x91, 0xa3, 0x3f, 0x31, 0x38, 0xf9, 
        0x57, 0x5f, 0xfe, 0xdd, 0x10, 0x71, 0x6b, 0x7b, 0x1b, 0x9d, 0xd7, 0x51, 0xd0, 0xab, 0xb1, 0xf7, 
        0x10, 0x22, 0x29, 0xb9, 0xb4, 0x2b, 0xb5, 0x0c, 0x43, 0x41, 0x75, 0xba, 0xc9, 0xb3, 0x2d, 0xa0, 
        0xe2, 0x4c, 0x40, 0xdb
    ]
}

fn get_array_100_rev() -> @Array<u8> {
    @array![
        0xdb, 0x40, 0x4c, 0xe2, 0xa0, 0x2d, 0xb3, 0xc9, 0xba, 0x75, 0x41, 0x43, 0x0c, 0xb5, 0x2b, 0xb4, 
        0xb9, 0x29, 0x22, 0x10, 0xf7, 0xb1, 0xab, 0xd0, 0x51, 0xd7, 0x9d, 0x1b, 0x7b, 0x6b, 0x71, 0x10, 
        0xdd, 0xfe, 0x5f, 0x57, 0xf9, 0x38, 0x31, 0x3f, 0xa3, 0x91, 0x5e, 0x2d, 0xa7, 0x7c, 0x68, 0x3e, 
        0x8b, 0x91, 0x24, 0xfe, 0x7a, 0x5c, 0xba, 0xd8, 0x66, 0x76, 0xbd, 0xf9, 0x98, 0xc5, 0x63, 0x8e, 
        0x0d, 0x1a, 0x72, 0x13, 0x07, 0xa2, 0xe0, 0xe5, 0x04, 0xd8, 0xf7, 0x78, 0x18, 0xe3, 0xf8, 0x28, 
        0xec, 0x81, 0x5e, 0x0f, 0x96, 0x48, 0xa3, 0x81, 0xf7, 0x06, 0x6d, 0xcd, 0x37, 0x8b, 0x9e, 0x44, 
        0xf6, 0x28, 0xbd, 0xfa
    ]
}

fn run_array_reverse_cpu(arr: @Array<u8>) -> Array<u8> {
    run_fn(@"array_reverse", arr)
}

fn run_array_reverse_local(arr: @Array<u8>) -> Array<u8> {
    let mut res = ArrayTrait::<u8>::new();
    let mut i: u32 = 0;
    while i < arr.len() {
        res.append(*arr.at( arr.len() - 1 - i));
        i += 1;
    };
    res
}

fn u32_to_le_bytes(v: u32) -> Array<u8> {
    let mut res = ArrayTrait::<u8>::new();
    res.append((v & 0b00000000000000000000000011111111).try_into().unwrap());
    res.append(((v & 0b00000000000000001111111100000000) / 0b100000000).try_into().unwrap());
    res.append(((v & 0b00000000111111110000000000000000) / 0b10000000000000000).try_into().unwrap());
    res.append(((v & 0b11111111000000000000000000000000) / 0b1000000000000000000000000).try_into().unwrap());
    res
}

fn le_bytes_to_u32(arr: @Array<u8>) -> u32 {
    (*arr.at(0)).into()
        + ((*arr.at(1)).into() * 0b100000000)
        + ((*arr.at(2)).into() * 0b10000000000000000)
        + ((*arr.at(3)).into() * 0b1000000000000000000000000)
}


fn run_fibonacci_cpu(n: u32) -> u32 {
    le_bytes_to_u32(@run_fn(@"fibonacci", @u32_to_le_bytes(n)))
}

fn run_fibonacci_local(n: u32) -> u32 {
    let mut a: u32 = 0;
    let mut b: u32 = 1;
    let mut i: u32 = 0;
    while i < n {
        let tmp = a + b;
        a = b;
        b = tmp;
        i += 1;
    };
    b
}

fn run_find_max_cpu(arr: @Array<u8>) -> u8 {
    *run_fn(@"find_max", arr).at(0)
}

fn run_find_max_local(arr: @Array<u8>) -> u8 {
    let mut max: u8 = 0;
    let mut i: u32 = 0;
    while i < arr.len() {
        if *arr.at(i) > max {
            max = *arr.at(i);
        }
        i += 1;
    };
    max
}


#[test]
fn test_array_reverse_cpu_10() {
    let output = run_array_reverse_cpu(get_array_10());
    assert_eq!(@output, get_array_10_rev(), "Unexpected return value");
}

#[test]
fn test_array_reverse_local_10() {
    let output = run_array_reverse_local(get_array_10());
    assert_eq!(@output, get_array_10_rev(), "Unexpected return value");
}

#[test]
fn test_array_reverse_cpu_50() {
    let output = run_array_reverse_cpu(get_array_50());
    assert_eq!(@output, get_array_50_rev(), "Unexpected return value");
}

#[test]
fn test_array_reverse_local_50() {
    let output = run_array_reverse_local(get_array_50());
    assert_eq!(@output, get_array_50_rev(), "Unexpected return value");
}

#[test]
fn test_array_reverse_cpu_100() {
    let output = run_array_reverse_cpu(get_array_100());
    assert_eq!(@output, get_array_100_rev(), "Unexpected return value");
}

#[test]
fn test_array_reverse_local_100() {
    let output = run_array_reverse_local(get_array_100());
    assert_eq!(@output, get_array_100_rev(), "Unexpected return value");
}

#[test]
fn test_fibonacci_cpu_10() {
    let output = run_fibonacci_cpu(10);
    assert_eq!(output, 89, "Unexpected return value");
}

#[test]
fn test_fibonacci_local_10() {
    let output = run_fibonacci_local(10);
    assert_eq!(output, 89, "Unexpected return value");
}

#[test]
fn test_fibonacci_cpu_20() {
    let output = run_fibonacci_cpu(20);
    assert_eq!(output, 10946, "Unexpected return value");
}

#[test]
fn test_fibonacci_local_20() {
    let output = run_fibonacci_local(20);
    assert_eq!(output, 10946, "Unexpected return value");
}

#[test]
fn test_fibonacci_cpu_30() {
    let output = run_fibonacci_cpu(30);
    assert_eq!(output, 1346269, "Unexpected return value");
}

#[test]
fn test_fibonacci_local_30() {
    let output = run_fibonacci_local(30);
    assert_eq!(output, 1346269, "Unexpected return value");
}

#[test]
fn test_fibonacci_cpu_40() {
    let output = run_fibonacci_cpu(40);
    assert_eq!(output, 165580141, "Unexpected return value");
}

#[test]
fn test_fibonacci_local_40() {
    let output = run_fibonacci_local(40);
    assert_eq!(output, 165580141, "Unexpected return value");
}

#[test]
fn test_find_max_cpu_10() {
    let output = run_find_max_cpu(get_array_10());
    assert_eq!(output, 0xFE, "Unexpected return value");
}

#[test]
fn test_find_max_local_10() {
    let output = run_find_max_local(get_array_10());
    assert_eq!(output, 0xFE, "Unexpected return value");
}

#[test]
fn test_find_max_cpu_50() {
    let output = run_find_max_cpu(get_array_50());
    assert_eq!(output, 0xFD, "Unexpected return value");
}

#[test]
fn test_find_max_local_50() {
    let output = run_find_max_local(get_array_50());
    assert_eq!(output, 0xFD, "Unexpected return value");
}


#[test]
fn test_find_max_cpu_100() {
    let output = run_find_max_cpu(get_array_100());
    assert_eq!(output, 0xFE, "Unexpected return value");
}

#[test]
fn test_find_max_local_100() {
    let output = run_find_max_local(get_array_100());
    assert_eq!(output, 0xFE, "Unexpected return value");
}
