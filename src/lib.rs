#![no_std]
#![feature(lang_items)]
#![feature(ptr_internals)]
#![no_main] // disable all Rust-level entry points
#![feature(abi_x86_interrupt)]

extern crate spin;
extern crate lazy_static;
extern crate x86_64;
extern crate volatile;
extern crate multiboot2;

mod vga;

use core::panic::PanicInfo;

#[no_mangle]
pub extern fn rust_main(multiboot_information_address: usize) {
    println!("Hello World");
    let boot_info = unsafe{ multiboot2::load(multiboot_information_address).unwrap() };
    let memory_map_tag = boot_info.memory_map_tag()
        .expect("Memory map tag required");

    println!("memory areas:");
    for area in memory_map_tag.memory_areas() {
        println!("    start: 0x{:x}, length: 0x{:x}", area.start_address(), area.size());
    }
    loop{}
}

#[lang = "eh_personality"] #[no_mangle] pub extern fn eh_personality() {}


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}
