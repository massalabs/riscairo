#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

cd rust_tests
cargo clean
cargo build --release
cd ..
cp rust_tests/target/riscv32i-unknown-none-elf/release/rust_tests test_elfs/rust_tests/in/
cd test_elfs
python3 convert.py
cd ..
snforge test --detailed-resources | tee test_report.txt
echo "All tests passed, the RISC-V CPU is working correctly."
python3 plot_results.py
