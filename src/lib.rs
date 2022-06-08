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
extern crate pic8259;
extern crate pc_keyboard;

mod vga;
mod gdt;
mod interrupts;


use core::panic::PanicInfo;


pub fn init() {
    gdt::init();
    interrupts::init_idt();
    unsafe { interrupts::PICS.lock().initialize() };
    x86_64::instructions::interrupts::enable();
}

#[no_mangle]
pub extern fn rust_main(multiboot_information_address: usize) {
    init();
    println!("Hello World!");
    unsafe {
        let mut x: *mut u8  = 0x23 as *mut u8;
        *x = 23;
    }
    loop{}
}

#[lang = "eh_personality"] #[no_mangle] pub extern fn eh_personality() {}


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}


