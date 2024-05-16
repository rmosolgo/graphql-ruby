use graphql_parser::query::parse_query;
mod translation;

use rb_sys::{
    rb_define_module, rb_define_singleton_method, rb_str_buf_append,
    rb_utf8_str_new_cstr, VALUE, rb_str_new, rb_string_value_ptr, rb_string_value_cstr
};
use std::{intrinsics::transmute, os::raw::c_char};

use std::ffi::CStr;
use std::str;

// Converts a static &str to a C string usable in foreign functions.
macro_rules! static_cstring {
    ($string:expr) => {{
        concat!($string, "\0").as_ptr() as *const c_char
    }};
}

unsafe fn parse(query: VALUE) -> VALUE {
    let ptr = rb_sys::RSTRING_PTR(query) as *const u8;
    let len = rb_sys::RSTRING_LEN(query) as usize;
    // let query_str = std::ffi::CStr::from_ptr(query_ptr).to_str().unwrap();
    let query_str = std::str::from_utf8_unchecked(std::slice::from_raw_parts(ptr, len));
    let ast = parse_query::<&str>(&query_str).unwrap();
    // let result: String = format!("{:?}", ast);
    // // let result: String = "foo".to_string();
    // return rb_str_new(result.as_ptr() as *const c_char, result.len().try_into().unwrap());
    return translation::translate_document(&ast);
}

unsafe extern "C" fn wrapped_parse(_: VALUE, query: VALUE) -> VALUE {
    let result = parse(query);
    return result;
}

#[no_mangle]
unsafe extern "C" fn Init_rust_graphql_parser() {
    let module = rb_define_module(static_cstring!("RustGraphqlParser"));

    rb_define_singleton_method(
        module,
        static_cstring!("parse"),
        Some(transmute::<unsafe extern "C" fn(VALUE, VALUE) -> VALUE, _>(
            wrapped_parse,
        )),
        1,
    );
}