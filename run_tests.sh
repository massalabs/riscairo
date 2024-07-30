#!/bin/bash

cd rust_tests \
    && cargo clean \
    && cargo build --release \
    && cd .. \
    && cp rust_tests/target/riscv32i-unknown-none-elf/release/rust_tests test_elfs/rust_tests/in/ \
    && cd test_elfs \
    && python3 convert.py \
    && cd .. \
    && snforge test \
    && echo "All tests passed, the RISC-V CPU is working correctly."
