use snforge_std::fs::{FileTrait, read_txt};
use riscairo::riscv_call;
use super::tools::load_file;
use riscairo::elf::ELFLoaderTrait;
use riscairo::riscv::{RISCVMachineTrait, FlowControl};

fn run_test(test_name: ByteArray) {
    // load ELF file
    let mut file_path: ByteArray = "riscv_compliance_checks/out/";
    file_path.append(@test_name);
    let bytecode = load_file(file_path);

    let mut machine = RISCVMachineTrait::new();
    let mut elf_loader = ELFLoaderTrait::new();

    // parse ELF data and load initial CPU and RAM states
    if !elf_loader.load(@bytecode, ref machine) {
        panic!("Failed to parse ELF data.");
    }

    // run CPU cycles
    loop {
        match machine.step() {
            FlowControl::Continue => {},
            FlowControl::InvalidInstruction => { panic!("CPU signalled an invalid instruction."); },
            FlowControl::ECall => { break; },
            FlowControl::EBreak => {},
            FlowControl::URet => {},
            FlowControl::SRet => {},
            FlowControl::MRet => {},
            FlowControl::Wfi => {},
        };
    };

    // read and check CPU output
    let syscall_num = machine.get_r(17).unwrap();
    let return_status = machine.get_r(10).unwrap();
    if syscall_num != 93 {
        panic!("CPU: Expected x17 == 93 after ecall, got {}.", syscall_num);
    }
    if (return_status != 0) {
        panic!("CPU returned that the guest test failed with code {}.", return_status);
    }
}

#[test]
fn test_cpu_add() {
    run_test("rv32ui-p-add");
}

#[test]
fn test_cpu_addi() {
    run_test("rv32ui-p-addi");
}

#[test]
fn test_cpu_and() {
    run_test("rv32ui-p-and");
}

#[test]
fn test_cpu_andi() {
    run_test("rv32ui-p-andi");
}

#[test]
fn test_cpu_auipc() {
    run_test("rv32ui-p-auipc");
}

#[test]
fn test_cpu_beq() {
    run_test("rv32ui-p-beq");
}

#[test]
fn test_cpu_bge() {
    run_test("rv32ui-p-bge");
}

#[test]
fn test_cpu_bgeu() {
    run_test("rv32ui-p-bgeu");
}

#[test]
fn test_cpu_blt() {
    run_test("rv32ui-p-blt");
}

#[test]
fn test_cpu_bltu() {
    run_test("rv32ui-p-bltu");
}

#[test]
fn test_cpu_bne() {
    run_test("rv32ui-p-bne");
}

#[test]
fn test_cpu_fence_i() {
    run_test("rv32ui-p-fence_i");
}

#[test]
fn test_cpu_jal() {
    run_test("rv32ui-p-jal");
}

#[test]
fn test_cpu_jalr() {
    run_test("rv32ui-p-jalr");
}

#[test]
fn test_cpu_lb() {
    run_test("rv32ui-p-lb");
}

#[test]
fn test_cpu_lbu() {
    run_test("rv32ui-p-lbu");
}

#[test]
fn test_cpu_lh() {
    run_test("rv32ui-p-lh");
}

#[test]
fn test_cpu_lhu() {
    run_test("rv32ui-p-lhu");
}

#[test]
fn test_cpu_lui() {
    run_test("rv32ui-p-lui");
}

#[test]
fn test_cpu_lw() {
    run_test("rv32ui-p-lw");
}

#[test]
fn test_cpu_ma_data() {
    run_test("rv32ui-p-ma_data");
}

#[test]
fn test_cpu_or() {
    run_test("rv32ui-p-or");
}

#[test]
fn test_cpu_ori() {
    run_test("rv32ui-p-ori");
}

#[test]
fn test_cpu_sb() {
    run_test("rv32ui-p-sb");
}

#[test]
fn test_cpu_sh() {
    run_test("rv32ui-p-sh");
}

#[test]
fn test_cpu_simple() {
    run_test("rv32ui-p-simple");
}

#[test]
fn test_cpu_sll() {
    run_test("rv32ui-p-sll");
}

#[test]
fn test_cpu_slli() {
    run_test("rv32ui-p-slli");
}

#[test]
fn test_cpu_slt() {
    run_test("rv32ui-p-slt");
}

#[test]
fn test_cpu_slti() {
    run_test("rv32ui-p-slti");
}

#[test]
fn test_cpu_sltiu() {
    run_test("rv32ui-p-sltiu");
}

#[test]
fn test_cpu_sltu() {
    run_test("rv32ui-p-sltu");
}

#[test]
fn test_cpu_sra() {
    run_test("rv32ui-p-sra");
}

#[test]
fn test_cpu_srai() {
    run_test("rv32ui-p-srai");
}

#[test]
fn test_cpu_srl() {
    run_test("rv32ui-p-srl");
}

#[test]
fn test_cpu_srli() {
    run_test("rv32ui-p-srli");
}

#[test]
fn test_cpu_sub() {
    run_test("rv32ui-p-sub");
}

#[test]
fn test_cpu_xor() {
    run_test("rv32ui-p-xor");
}

#[test]
fn test_cpu_xori() {
    run_test("rv32ui-p-xori");
}

