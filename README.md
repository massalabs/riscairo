# riscairo

RISC-V ELF interpreter in cairo 2.

## Intro

This is my first program in cairo !
It implements an ELF file parser and a RISC-V virtual machine.

## Run a basic test

Bu running the command `scarb test` it should trigger a basic test that loads the following RISC-V program compiled as ELF:

```
.global _start

_start:
    
    # run only one instance
    csrr    t0, mhartid
    bnez    t0, forever
    
    # prepare for the loop
    li      s1, 0x10000000  # output offset   
    la      s2, hello       # load string start addr into s2
    addi    s3, s2, 13      # set up string end addr in s3

loop:
    lb      s4, 0(s2)       # load next byte at s2 into s4
    sb      s4, 0(s1)       # write byte to output 
    addi    s2, s2, 1       # increase s2
    addi    s1, s1, 1       # increase s1
    blt     s2, s3, loop    # branch back until end addr (s3) reached

forever:
    wfi
    j       forever


.section .data

hello:
    .string "hello world!\n"
```

the expected output of the run is:

```
$ scarb test
     Running cairo-test riscairo
   Compiling test(riscairo_unittest) riscairo v0.1.0 (/home/damip/riscairo/Scarb.toml)
    Finished release target(s) in 10 seconds
testing riscairo ...
running 1 test
The RISC-V ELF was executed and sent the following output: hello world!

test riscairo::tests::memory_communication ... ok (gas usage est.: 18563824)
test result: ok. 1 passed; 0 failed; 0 ignored; 0 filtered out;
```
