import os


def convert_file(in_file_name, out_file_name):
    with open(in_file_name, 'rb') as f:
        with open(out_file_name, 'w') as f2:
            byte = f.read(1)
            while byte:
                f2.write('0x{:02x}\n'.format(ord(byte)))
                byte = f.read(1)
    print('  Converted', in_file_name, 'to', out_file_name)

def convert_folder(in_folder, out_folder):
    if not os.path.exists(out_folder):
        os.makedirs(out_folder)

    for file_name in os.listdir(in_folder):
        if os.path.isfile(os.path.join(in_folder, file_name)):
            convert_file(os.path.join(in_folder, file_name), os.path.join(out_folder, file_name))

def main():
    print("Converting ELF files to snfoundry-compatible text files...")

    # convert RISCV CPU compliance checks
    convert_folder(os.path.join('riscv_compliance_checks', 'in'), os.path.join('riscv_compliance_checks', 'out'))

    # convert rust tests
    convert_folder(os.path.join('rust_tests', 'in'), os.path.join('rust_tests', 'out'))

    print("ELF conversion done.")


if __name__ == '__main__':
    main()
