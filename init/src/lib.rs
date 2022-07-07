#![no_std]
#![no_main]
#![feature(lang_items)]

#[lang = "eh_personality"]
extern "C" fn eh_personality() {}

#[panic_handler]
fn panic(info: &core::panic::PanicInfo) -> ! {
    abort();
}


fn abort() -> ! {
    loop {}
}


extern "C" 
fn USERSPACE_INIT() {

}
