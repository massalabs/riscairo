# riscairo

RISC-V ELF interpreter in cairo.

## Intro

This cairo library implements an ELF file parser and a RISC-V virtual machine.
The machine implements the RV32i instruction set, without extensions.

The VM was tested for compliance under the `rv32ui-p-*` test suite from https://github.com/riscv-software-src/riscv-tests .

For usage information, please check https://github.com/massalabs/riscairo_template .

## Tests and benchmarks

To run all tests and benchmarks, use `./run_tests.sh`.

Below are some benchmark results:

![Alt text](bench.png)

```
Linear fit for CPU in find_max:
  Offset: 6398.70
  Gas per input size: 15.97
Linear fit for Local in find_max:
  Offset: 1.00
  Gas per input size: 0.20
Linear fit for CPU in array_reverse:
  Offset: 6378.82
  Gas per input size: 22.52
Linear fit for Local in array_reverse:
  Offset: 0.28
  Gas per input size: 0.29
Linear fit for CPU in fibonacci:
  Offset: 6470.00
  Gas per input size: 9.87
Linear fit for Local in fibonacci:
  Offset: 0.50
  Gas per input size: 0.16
```
