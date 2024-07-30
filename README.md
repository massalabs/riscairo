# riscairo

RISC-V ELF interpreter in cairo.

## Intro

This cairo library implements an ELF file parser and a RISC-V virtual machine.
The machine implements the RV32i instruction set, without extensions.

The VM was tested for compliance under the `rv32ui-p-*` test suite from (see https://github.com/riscv-software-src/riscv-tests).

For usage information, please check https://github.com/massalabs/riscairo_template .

## Run tests

To run all tests, use `./run_tests.sh`.

Expected output:

```
     Removed 13 files, 16.2KiB total
   Compiling rust_tests v0.1.0 (/home/damip/riscairo/rust_tests)
    Finished `release` profile [optimized] target(s) in 0.16s
Converting ELF files to snfoundry-compatible text files...
  Converted riscv_compliance_checks/in/rv32ui-p-lbu to riscv_compliance_checks/out/rv32ui-p-lbu
  Converted riscv_compliance_checks/in/rv32ui-p-sra to riscv_compliance_checks/out/rv32ui-p-sra
  Converted riscv_compliance_checks/in/rv32ui-p-lw to riscv_compliance_checks/out/rv32ui-p-lw
  Converted riscv_compliance_checks/in/rv32ui-p-slti to riscv_compliance_checks/out/rv32ui-p-slti
  Converted riscv_compliance_checks/in/rv32ui-p-fence_i to riscv_compliance_checks/out/rv32ui-p-fence_i
  Converted riscv_compliance_checks/in/rv32ui-p-ori to riscv_compliance_checks/out/rv32ui-p-ori
  Converted riscv_compliance_checks/in/rv32ui-p-ma_data to riscv_compliance_checks/out/rv32ui-p-ma_data
  Converted riscv_compliance_checks/in/rv32ui-p-sll to riscv_compliance_checks/out/rv32ui-p-sll
  Converted riscv_compliance_checks/in/rv32ui-p-bge to riscv_compliance_checks/out/rv32ui-p-bge
  Converted riscv_compliance_checks/in/rv32ui-p-slli to riscv_compliance_checks/out/rv32ui-p-slli
  Converted riscv_compliance_checks/in/rv32ui-p-addi to riscv_compliance_checks/out/rv32ui-p-addi
  Converted riscv_compliance_checks/in/rv32ui-p-srai to riscv_compliance_checks/out/rv32ui-p-srai
  Converted riscv_compliance_checks/in/rv32ui-p-bgeu to riscv_compliance_checks/out/rv32ui-p-bgeu
  Converted riscv_compliance_checks/in/rv32ui-p-lhu to riscv_compliance_checks/out/rv32ui-p-lhu
  Converted riscv_compliance_checks/in/rv32ui-p-lui to riscv_compliance_checks/out/rv32ui-p-lui
  Converted riscv_compliance_checks/in/rv32ui-p-srli to riscv_compliance_checks/out/rv32ui-p-srli
  Converted riscv_compliance_checks/in/rv32ui-p-xor to riscv_compliance_checks/out/rv32ui-p-xor
  Converted riscv_compliance_checks/in/rv32ui-p-sltu to riscv_compliance_checks/out/rv32ui-p-sltu
  Converted riscv_compliance_checks/in/rv32ui-p-beq to riscv_compliance_checks/out/rv32ui-p-beq
  Converted riscv_compliance_checks/in/rv32ui-p-jal to riscv_compliance_checks/out/rv32ui-p-jal
  Converted riscv_compliance_checks/in/rv32ui-p-sub to riscv_compliance_checks/out/rv32ui-p-sub
  Converted riscv_compliance_checks/in/rv32ui-p-slt to riscv_compliance_checks/out/rv32ui-p-slt
  Converted riscv_compliance_checks/in/rv32ui-p-blt to riscv_compliance_checks/out/rv32ui-p-blt
  Converted riscv_compliance_checks/in/rv32ui-p-jalr to riscv_compliance_checks/out/rv32ui-p-jalr
  Converted riscv_compliance_checks/in/rv32ui-p-bltu to riscv_compliance_checks/out/rv32ui-p-bltu
  Converted riscv_compliance_checks/in/rv32ui-p-and to riscv_compliance_checks/out/rv32ui-p-and
  Converted riscv_compliance_checks/in/rv32ui-p-simple to riscv_compliance_checks/out/rv32ui-p-simple
  Converted riscv_compliance_checks/in/rv32ui-p-srl to riscv_compliance_checks/out/rv32ui-p-srl
  Converted riscv_compliance_checks/in/rv32ui-p-bne to riscv_compliance_checks/out/rv32ui-p-bne
  Converted riscv_compliance_checks/in/rv32ui-p-lh to riscv_compliance_checks/out/rv32ui-p-lh
  Converted riscv_compliance_checks/in/rv32ui-p-sh to riscv_compliance_checks/out/rv32ui-p-sh
  Converted riscv_compliance_checks/in/rv32ui-p-lb to riscv_compliance_checks/out/rv32ui-p-lb
  Converted riscv_compliance_checks/in/rv32ui-p-or to riscv_compliance_checks/out/rv32ui-p-or
  Converted riscv_compliance_checks/in/rv32ui-p-sltiu to riscv_compliance_checks/out/rv32ui-p-sltiu
  Converted riscv_compliance_checks/in/rv32ui-p-sb to riscv_compliance_checks/out/rv32ui-p-sb
  Converted riscv_compliance_checks/in/rv32ui-p-sw to riscv_compliance_checks/out/rv32ui-p-sw
  Converted riscv_compliance_checks/in/rv32ui-p-andi to riscv_compliance_checks/out/rv32ui-p-andi
  Converted riscv_compliance_checks/in/rv32ui-p-auipc to riscv_compliance_checks/out/rv32ui-p-auipc
  Converted riscv_compliance_checks/in/rv32ui-p-add to riscv_compliance_checks/out/rv32ui-p-add
  Converted riscv_compliance_checks/in/rv32ui-p-xori to riscv_compliance_checks/out/rv32ui-p-xori
  Converted rust_tests/in/rust_tests to rust_tests/out/rust_tests
ELF conversion done.
   Compiling riscairo v0.1.0 (/home/damip/riscairo/Scarb.toml)
    Finished release target(s) in 2 seconds


Collected 42 test(s) from riscairo package
Running 0 test(s) from src/
Running 42 test(s) from tests/
[PASS] tests::riscv_compliance_tests::test_cpu_simple (gas: ~1811)
[PASS] tests::riscv_compliance_tests::test_cpu_lui (gas: ~1952)
[PASS] tests::riscv_compliance_tests::test_cpu_jal (gas: ~1922)
[PASS] tests::riscv_compliance_tests::test_cpu_andi (gas: ~2378)
[PASS] tests::riscv_compliance_tests::test_cpu_beq (gas: ~2715)
[PASS] tests::riscv_compliance_tests::test_cpu_sltiu (gas: ~2580)
[PASS] tests::riscv_compliance_tests::test_cpu_ori (gas: ~2388)
[PASS] tests::riscv_compliance_tests::test_cpu_fence_i (gas: ~3597)
[PASS] tests::riscv_compliance_tests::test_cpu_add (gas: ~3332)
[PASS] tests::riscv_compliance_tests::test_cpu_bge (gas: ~2808)
[PASS] tests::riscv_compliance_tests::test_cpu_xor (gas: ~3249)
[PASS] tests::riscv_compliance_tests::test_cpu_or (gas: ~3251)
[PASS] tests::riscv_compliance_tests::test_cpu_slt (gas: ~3328)
[PASS] tests::riscv_compliance_tests::test_cpu_and (gas: ~3223)
[PASS] tests::riscv_compliance_tests::test_cpu_lbu (gas: ~3758)
[PASS] tests::riscv_compliance_tests::test_cpu_sra (gas: ~3641)
[PASS] tests::riscv_compliance_tests::test_cpu_bne (gas: ~2715)
[PASS] tests::riscv_compliance_tests::test_cpu_lh (gas: ~3808)
[PASS] tests::riscv_compliance_tests::test_cpu_blt (gas: ~2727)
[PASS] tests::riscv_compliance_tests::test_cpu_lhu (gas: ~3821)
[PASS] tests::rust_tests::test_cpu_sub (gas: ~4059)
[PASS] tests::riscv_compliance_tests::test_cpu_jalr (gas: ~2117)
[PASS] tests::riscv_compliance_tests::test_cpu_lb (gas: ~3758)
[PASS] tests::riscv_compliance_tests::test_cpu_slli (gas: ~2656)
[PASS] tests::riscv_compliance_tests::test_cpu_slti (gas: ~2585)
[PASS] tests::rust_tests::test_cpu_prepend_hello (gas: ~4984)
[PASS] tests::riscv_compliance_tests::test_cpu_xori (gas: ~2391)
[PASS] tests::riscv_compliance_tests::test_cpu_srli (gas: ~2691)
[PASS] tests::riscv_compliance_tests::test_cpu_auipc (gas: ~1910)
[PASS] tests::riscv_compliance_tests::test_cpu_bgeu (gas: ~2839)
[PASS] tests::riscv_compliance_tests::test_cpu_sh (gas: ~4534)
[PASS] tests::riscv_compliance_tests::test_cpu_sll (gas: ~3535)
[PASS] tests::riscv_compliance_tests::test_cpu_srl (gas: ~3633)
[PASS] tests::riscv_compliance_tests::test_cpu_addi (gas: ~2612)
[PASS] tests::riscv_compliance_tests::test_cpu_bltu (gas: ~2736)
[PASS] tests::riscv_compliance_tests::test_cpu_sub (gas: ~3315)
[PASS] tests::riscv_compliance_tests::test_cpu_srai (gas: ~2700)
[PASS] tests::riscv_compliance_tests::test_cpu_sltu (gas: ~3321)
[PASS] tests::riscv_compliance_tests::test_cpu_lw (gas: ~3862)
[PASS] tests::rust_tests::test_cpu_add (gas: ~3982)
[PASS] tests::riscv_compliance_tests::test_cpu_sb (gas: ~4387)
[PASS] tests::riscv_compliance_tests::test_cpu_ma_data (gas: ~4404)
Tests: 42 passed, 0 failed, 0 skipped, 0 ignored, 0 filtered out
All tests passed, the RISC-V CPU is working correctly.
```