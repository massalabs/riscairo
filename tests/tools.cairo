use snforge_std::fs::{FileTrait, read_txt};

pub fn load_file(file_path: ByteArray) -> Span<u8> {
    let file = FileTrait::new(file_path);
    let file_arr = read_txt(@file);
    let mut file_bytes: Array<u8> = ArrayTrait::new();
    let mut i: u32 = 0;
    while i < file_arr.len() {
        file_bytes.append(file_arr.at(i).clone().try_into().unwrap());
        i += 1;
    };
    file_bytes.span()
}
