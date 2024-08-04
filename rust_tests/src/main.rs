//! This is the main file of the program. It contains the user-defined functions that need to be made available to the VM.
//! The `export_fn!` macro is used to register the exported functions with the VM. The string literal is the exported name of the function as visible from outside the VM.
//! Everything runs in a `no_std` environment but dynamic memory allocation is available.

#![no_std]
#![no_main]

mod rv;

use alloc::vec::Vec;

fn array_reverse(args: &[u8]) -> Vec<u8> {
    let mut res = Vec::with_capacity(args.len());
    for v in args.iter().rev() {
        res.push(*v);
    }
    res
}

fn fibonacci(args: &[u8]) -> Vec<u8> {
    let val = u32::from_le_bytes(args.try_into().expect("Invalid arguments"));

    let mut a = 0u32;
    let mut b = 1u32;

    for _ in 0..val {
        let c = a + b;
        a = b;
        b = c;
    }

    b.to_le_bytes().to_vec()
}

fn find_max(args: &[u8]) -> Vec<u8> {
    let mut max = 0u8;
    for i in args {
        if *i > max {
            max = *i;
        }
    }
    [max].to_vec()
}

export_fn!(
    "array_reverse" => array_reverse,
    "fibonacci" => fibonacci,
    "find_max" => find_max
);
