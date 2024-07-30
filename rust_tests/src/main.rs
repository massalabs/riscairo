#![no_std]
#![no_main]

use core::arch::{asm, global_asm};

// initialize the stack pointer and call the user entry point
global_asm!(
    "
    .section .text.init
    .global _start
    _start:
        la   sp, __sp
        call _user_entry
    "
);

// fixed memory area for input data
extern "C" {
    static IN_FUNC_NAME_LEN: usize;
    static IN_FUNC_NAME: [u8; 255];
    static IN_FUNC_ARGS_LEN: usize;
    static IN_FUNC_ARGS: [u8; 10240];
    static HEAP: [u8; 1048576];
}


const ECALL_CATEGORY_PANIC: u32 = 1;
const ECALL_CATEGORY_RETURN: u32 = 2;


extern crate alloc;
use alloc::vec::Vec;
use core::alloc::{GlobalAlloc, Layout};
use core::cell::UnsafeCell;
use core::ptr::null_mut;

// a simple allocator that never frees
struct BumpAllocator {
    offset: UnsafeCell<usize>,
}

impl BumpAllocator {
    const fn new() -> Self {
        BumpAllocator {
            offset: UnsafeCell::new(0),
        }
    }

    unsafe fn bump_alloc(&self, layout: Layout) -> *mut u8 {
        let heap_start = HEAP.as_ptr() as usize;
        let offset = self.offset.get();
        let alloc_start = heap_start + *offset;
        let alloc_size = layout.size();
        let Some(alloc_end) = alloc_start.checked_add(alloc_size) else {
            return null_mut();
        };
        if alloc_end > heap_start + HEAP.len() {
            return null_mut();
        }
        *offset += alloc_size;
        alloc_start as *mut u8
    }
}

// Implementing Sync for BumpAllocator
unsafe impl Sync for BumpAllocator {}

unsafe impl GlobalAlloc for BumpAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        self.bump_alloc(layout)
    }

    unsafe fn dealloc(&self, _ptr: *mut u8, _layout: Layout) {
        // Bump allocator does not deallocate
    }
}

#[global_allocator]
static GLOBAL_ALLOCATOR: BumpAllocator = BumpAllocator::new();

// use assembly to send the memory address of the data, and call "ecall" to signal upstream that there is data to be read
fn ecall(data: &[u8], category: u32) {
    unsafe {
        let data_len: u32 = data.len() as u32;
        let data_ptr: u32 = data.as_ptr() as u32;
        asm!(
            "mv a0, {0}",   // x10 registry: category
            "mv a1, {1}",   // x11 registry: data_len
            "mv a2, {2}",   // x12 registry: data_ptr
            "ecall",
            in(reg) category,
            in(reg) data_len,
            in(reg) data_ptr,
            out("a0") _,
            out("a1") _,
            out("a2") _,
        );
    };
}

// retuns a tuple of the function name and the function arguments
fn einput() -> (&'static [u8], &'static [u8]) {
    unsafe {
        (
            core::slice::from_raw_parts(IN_FUNC_NAME.as_ptr(), IN_FUNC_NAME_LEN),
            core::slice::from_raw_parts(IN_FUNC_ARGS.as_ptr(), IN_FUNC_ARGS_LEN),
        )
    }
}

// handle panic by sending the panic message to the upstream and quit
#[panic_handler]
fn panic(info: &core::panic::PanicInfo) -> ! {
    let msg = info.message().as_str().unwrap_or_default().as_bytes();
    ecall(msg, ECALL_CATEGORY_PANIC);
    // assume we never return from this ecall
    unsafe {
        asm!("", options(noreturn));
    };
}

// send result data to the upstream and quit
fn ereturn(data: &[u8]) -> ! {
    ecall(data, ECALL_CATEGORY_RETURN);
    // assume we never return from this ecall
    unsafe {
        asm!("", options(noreturn));
    };
}

// main entry point of the program
#[no_mangle]
pub extern "C" fn _user_entry() -> ! {
    // Read input data
    let (func_name, args) = einput();

    match func_name {
        b"add" => {
            if args.len() != 2 {
                panic!("Invalid arguments");
            }
            let res = args[0] + args[1];
            ereturn(&[res]);
        }
        b"sub" => {
            if args.len() != 2 {
                panic!("Invalid arguments");
            }
            let res = args[0] - args[1];
            ereturn(&[res]);
        }
        b"prepend_hello" => {
            let mut res = Vec::new();
            res.extend_from_slice(b"hello ");
            res.extend_from_slice(args);
            ereturn(&res);
        }
        _ => {
            panic!("Unknown function");
        }
    }
}
