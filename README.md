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
Linear fit for CPU in array_reverse:
  Intercept (gas used at zero input complexity): 6366.72
  Slope (gas per unit of input complexity): 22.51
Linear fit for Local in array_reverse:
  Intercept (gas used at zero input complexity): 0.28
  Slope (gas per unit of input complexity): 0.29
Linear fit for CPU in fibonacci:
  Intercept (gas used at zero input complexity): 6457.50
  Slope (gas per unit of input complexity): 9.87
Linear fit for Local in fibonacci:
  Intercept (gas used at zero input complexity): 0.50
  Slope (gas per unit of input complexity): 0.16
Linear fit for CPU in find_max:
  Intercept (gas used at zero input complexity): 6386.98
  Slope (gas per unit of input complexity): 15.96
Linear fit for Local in find_max:
  Intercept (gas used at zero input complexity): 1.00
  Slope (gas per unit of input complexity): 0.20
```
