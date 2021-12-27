use byteorder::{BigEndian, WriteBytesExt};
use nix::fcntl::{open, OFlag};
use nix::sys::stat::Mode;
use nix::unistd::{close, read, write};
use sha2::{Digest, Sha256};
use std::env;
use std::fmt::Write;
use std::fs;
use std::io::prelude::*;
use std::time::SystemTime;

trait AsHex: AsRef<[u8]> {
    fn as_hex(&self) -> String {
        let bytes = self.as_ref();
        let mut result = String::with_capacity(bytes.len() * 2 + bytes.len() / 32);
        for (i, b) in bytes.iter().enumerate() {
            if i > 0 && 0 == (i % 32) {
                write!(result, "\n").unwrap();
            }
            write!(result, "{:02x}", b).unwrap();
        }
        result
    }
}

impl AsHex for [u8] {}
impl AsHex for Vec<u8> {}

fn make_chunk(buffer: &mut Vec<u8>) {
    let msg_len = buffer.len() * 8;
    buffer.push(0x80);
    let chunk_used_space = buffer.len() % 64;
    if chunk_used_space < 56 {
        buffer.resize(buffer.len() + 56 - chunk_used_space, 0x00);
    } else {
        buffer.resize(buffer.len() + 64 + 56 - chunk_used_space, 0x00);
    }
    buffer.write_u64::<BigEndian>(msg_len as u64).unwrap();
}

fn make_speed(length: u64, millis: u64) -> f32 {
    let result = (length as f32) * 1000.0 / (millis as f32) / 1024.0 / 1024.0;
    result
}

fn dump_interrupt() {
    let interrupts = String::from_utf8(fs::read("/proc/interrupts").unwrap()).unwrap();
    for line in interrupts.lines() {
        if line.contains("xilinx-dma-controller") {
            println!("interrupt info:\n{}", line);
        }
    }
}

fn main() {
    let sha256_dev =
        open("/dev/sha256", OFlag::O_RDWR | OFlag::O_SYNC, Mode::empty()).expect("open sha256 dev");
    // let mut str_buffer = String::from("b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9");
    // let mut buffer = unsafe { str_buffer.as_mut_vec() };
    // let file_len = buffer.len() as u64;

    let self_path = env::args().next().expect("open self");
    let mut self_file = fs::File::open(self_path.as_str()).expect(self_path.as_str());
    let file_len = self_file.metadata().expect(self_path.as_str()).len();
    let mut buffer = Vec::with_capacity(file_len as usize + 64 * 2);
    self_file
        .read_to_end(&mut buffer)
        .expect(self_path.as_str());
    println!("file size: {}KiB", buffer.len() / 1024);

    let mut hasher = Sha256::new();
    let systime = SystemTime::now();
    hasher.update(buffer.as_slice());
    let software_cost = systime.elapsed().unwrap().as_millis() as u64;

    println!("software sha256: {}", hasher.finalize()[..].as_hex());
    println!(
        "by Rust, crate: 'sha2', cost: {}ms, speed: {:.2}MiB/s",
        software_cost,
        make_speed(file_len, software_cost)
    );

    make_chunk(&mut buffer);
    // println!("dump:\n{}\n", buffer.as_hex());

    let systime = SystemTime::now();
    match write(sha256_dev, buffer.as_slice()) {
        Ok(_n) => {}
        Err(e) => {
            panic!("{}", e);
        }
    }
    let mut result: [u8; 32] = [0; 32];
    match read(sha256_dev, &mut result) {
        Ok(_n) => {
            let hardware_cost = systime.elapsed().unwrap().as_millis() as u64;
            println!("hardware sha256: {}", result.as_hex());
            println!(
                "by FPGA@120MHz, device: '/dev/sha256', cost: {}ms, speed: {:.2}MiB/s",
                hardware_cost,
                make_speed(file_len, hardware_cost)
            );
        }
        Err(e) => {
            panic!("{}", e);
        }
    }
    dump_interrupt();
    close(sha256_dev).expect("close sha256 dev");
}
