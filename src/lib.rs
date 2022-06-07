#![no_std]
#![feature(lang_items)]


use core::panic::PanicInfo;

#[no_mangle]
pub extern fn rust_main() {
    let hello = b"Hello World!";
    let colour_byte = 0x1f;
    let mut hello_coloured = [colour_byte; 24];
    for (i, char_byte) in hello.into_iter().enumerate() {
        hello_coloured[i*2] = *char_byte;
    }
    let buffer_ptr = (0xb8000 + 1988) as *mut _;
    unsafe { *buffer_ptr = hello_coloured };
    loop{}
}

#[lang = "eh_personality"] #[no_mangle] pub extern fn eh_personality() {}


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}
