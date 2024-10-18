use utils::traits::bytes::{ToBytes, FromBytes, U8ToBytes};
use utils::traits::bytes::ByteArrayExTrait;

pub impl U8FromBytes of FromBytes<u8> {
    fn from_le_bytes(self: Span<u8>) -> Option<u8> {
        Option::Some(*self[0])
    }

    fn from_be_bytes(self: Span<u8>) -> Option<u8> {
        panic!("unsupported")
    }

    fn from_be_bytes_partial(self: Span<u8>) -> Option<u8> {
        panic!("unsupported")
    }

    fn from_le_bytes_partial(self: Span<u8>) -> Option<u8> {
        panic!("unsupported")
    }
}

pub impl ArrayU8ToBytes of ToBytes<Array<u8>> {
    fn to_le_bytes(self: Array<u8>) -> Span<u8> {
        self.span()
    }
    fn to_be_bytes(self: Array<u8>) -> Span<u8> {
        panic!("unsupported")
    }

    fn to_le_bytes_padded(self: Array<u8>) -> Span<u8> {
        panic!("unsupported")
    }

    fn to_be_bytes_padded(self: Array<u8>) -> Span<u8> {
        panic!("unsupported")
    }
}

pub impl ArrayU8FromBytes of FromBytes<Array<u8>> {
    fn from_le_bytes(self: Span<u8>) -> Option<Array<u8>> {
        let mut res: Array::<u8> = Default::default();
        for i in 0..self.len() {
            res.append(*self[i]);
        };
        Option::Some(res)
    }

    fn from_be_bytes(self: Span<u8>) -> Option<Array<u8>> {
        panic!("unsupported")
    }

    fn from_be_bytes_partial(self: Span<u8>) -> Option<Array<u8>> {
        panic!("unsupported")
    }

    fn from_le_bytes_partial(self: Span<u8>) -> Option<Array<u8>> {
        panic!("unsupported")
    }
}


pub impl ByteArrayToBytes of ToBytes<ByteArray> {
    fn to_le_bytes(self: ByteArray) -> Span<u8> {
        self.into_bytes()
    }

    fn to_be_bytes(self: ByteArray) -> Span<u8> {
        panic!("unsupported")
    }

    fn to_le_bytes_padded(self: ByteArray) -> Span<u8> {
        panic!("unsupported")
    }

    fn to_be_bytes_padded(self: ByteArray) -> Span<u8> {
        panic!("unsupported")
    }
}

pub impl ByteArrayFromBytes of FromBytes<ByteArray> {
    fn from_le_bytes(self: Span<u8>) -> Option<ByteArray> {
        Option::Some(ByteArrayExTrait::from_bytes(self))
    }

    fn from_be_bytes(self: Span<u8>) -> Option<ByteArray> {
        panic!("unsupported")
    }

    fn from_le_bytes_partial(self: Span<u8>) -> Option<ByteArray> {
        panic!("unsupported")
    }

    fn from_be_bytes_partial(self: Span<u8>) -> Option<ByteArray> {
        panic!("unsupported")
    }
}
