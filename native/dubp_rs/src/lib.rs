//  Copyright (C) 2020  Éloïs SANCHEZ.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#![allow(clippy::missing_safety_doc, clippy::not_unsafe_ptr_arg_deref)]

mod r#async;
mod dewif;
mod error;
mod mnemonic;

use crate::error::{DartRes, DubpError};
use crate::r#async::exec_async;
use allo_isolate::{IntoDart, Isolate};
use dup_crypto::{
    bases::b58::ToBase58,
    dewif::{Currency, DewifReadError, ExpectedCurrency, G1_CURRENCY, G1_TEST_CURRENCY},
    keys::{
        ed25519::KeyPairFromSeed32Generator, KeyPair as _, KeyPairEnum, Signator as _,
        Signature as _,
    },
    mnemonic::{Language, Mnemonic, MnemonicType},
};
use fast_threadpool::{ThreadPool, ThreadPoolConfig, ThreadPoolSyncHandler};
use once_cell::sync::Lazy;
use std::{ffi::CStr, io, os::raw};
use thiserror::Error;

pub(crate) fn char_ptr_to_str<'a>(c_char_ptr: *const raw::c_char) -> Result<&'a str, DubpError> {
    if c_char_ptr.is_null() {
        Err(DubpError::NullParamErr)
    } else {
        unsafe { CStr::from_ptr(c_char_ptr).to_str() }.map_err(DubpError::Utf8Error)
    }
}

fn char_ptr_prt_to_vec_str<'a>(
    char_ptr_ptr: *const *const raw::c_char,
    len: u32,
) -> Result<Vec<&'a str>, DubpError> {
    let len = len as usize;
    let char_ptr_slice: &[*const raw::c_char] =
        unsafe { std::slice::from_raw_parts(char_ptr_ptr, len) };
    let mut str_vec = Vec::with_capacity(len);
    for char_ptr in char_ptr_slice {
        str_vec.push(char_ptr_to_str(*char_ptr)?);
    }
    Ok(str_vec)
}

fn u32_to_language(i: u32) -> Result<Language, DubpError> {
    match i {
        0 => Ok(Language::English),
        1 => Ok(Language::French),
        _ => Err(DubpError::UnknownLanguage),
    }
}

#[no_mangle]
pub extern "C" fn change_dewif_pin(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    old_pin: *const raw::c_char,
    new_pin: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let dewif = char_ptr_to_str(dewif)?;
            let old_pin = char_ptr_to_str(old_pin)?;
            let new_pin = char_ptr_to_str(new_pin)?;
            Ok((currency, dewif, old_pin, new_pin))
        },
        |(currency, dewif, old_pin, new_pin)| dewif::change_pin(currency, dewif, old_pin, new_pin),
    )
}

#[no_mangle]
pub extern "C" fn gen_dewif(
    port: i64,
    currency: *const raw::c_char,
    language: u32,
    mnemonic: *const raw::c_char,
    pin: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let mnemonic = char_ptr_to_str(mnemonic)?;
            let pin = char_ptr_to_str(pin)?;
            Ok((currency, language, mnemonic, pin))
        },
        |(currency, language, mnemonic, pin)| dewif::gen_dewif(currency, language, mnemonic, pin),
    )
}

#[no_mangle]
pub extern "C" fn gen_mnemonic(port: i64, language: u32) {
    Isolate::new(port).post(DartRes::from(mnemonic::gen_mnemonic(language)));
}

#[no_mangle]
pub extern "C" fn gen_pin6(port: i64) {
    Isolate::new(port).post(DartRes::from(dewif::gen_pin6()));
}

#[no_mangle]
pub extern "C" fn gen_pin8(port: i64) {
    Isolate::new(port).post(DartRes::from(dewif::gen_pin8()));
}

#[no_mangle]
pub extern "C" fn gen_pin10(port: i64) {
    Isolate::new(port).post(DartRes::from(dewif::gen_pin10()));
}

#[no_mangle]
pub extern "C" fn get_dewif_pubkey(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let dewif = char_ptr_to_str(dewif)?;
            let pin = char_ptr_to_str(pin)?;
            Ok((currency, dewif, pin))
        },
        |(currency, dewif, pin)| dewif::get_pubkey(currency, dewif, pin),
    )
}

#[no_mangle]
pub extern "C" fn mnemonic_to_pubkey(
    port: i64,
    language: u32,
    mnemonic_phrase: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let mnemonic_phrase = char_ptr_to_str(mnemonic_phrase)?;
            Ok((language, mnemonic_phrase))
        },
        |(language, mnemonic_phrase)| mnemonic::mnemonic_to_pubkey(language, mnemonic_phrase),
    )
}

#[no_mangle]
pub extern "C" fn sign(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msg: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let dewif = char_ptr_to_str(dewif)?;
            let pin = char_ptr_to_str(pin)?;
            let msg = char_ptr_to_str(msg)?;
            Ok((currency, dewif, pin, msg))
        },
        |(currency, dewif, pin, msg)| dewif::sign(currency, dewif, pin, msg),
    )
}

#[no_mangle]
pub extern "C" fn sign_several(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msgs_len: u32,
    msgs: *const *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let dewif = char_ptr_to_str(dewif)?;
            let pin = char_ptr_to_str(pin)?;
            let msgs = char_ptr_prt_to_vec_str(msgs, msgs_len)?;
            Ok((currency, dewif, pin, msgs))
        },
        |(currency, dewif, pin, msgs)| dewif::sign_several(currency, dewif, pin, &msgs),
    )
}
