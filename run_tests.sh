#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Building rust tests..."
cd rust_tests
cargo clean
cargo build --release
cd ..
echo "Converting elf files..."
python3 convert.py
echo "Running cairo tests..."
RUST_MIN_STACK=5000000 snforge test --detailed-resources | tee test_report.txt
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "snforge test failed"
  exit 1
fi
echo "Gathering results..."
python3 plot_results.py
