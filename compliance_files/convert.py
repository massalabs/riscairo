import os



def convert_file(in_file_name, out_file_name):
    with open(in_file_name, 'rb') as f:
        with open(out_file_name, 'w') as f2:
            byte = f.read(1)
            while byte:
                f2.write('0x{:02x}\n'.format(ord(byte)))
                byte = f.read(1)

def main():
    in_folder = "in"
    out_folder = "out"

    if not os.path.exists(out_folder):
        os.makedirs(out_folder)

    for file_name in os.listdir(in_folder):
        if os.path.isfile(os.path.join(in_folder, file_name)):
            convert_file(os.path.join(in_folder, file_name), os.path.join(out_folder, file_name))
        print('Converted', file_name)

if __name__ == '__main__':
    main()
    print("ELF conversion done")
