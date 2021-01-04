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

mod dewif;
mod mnemonic;

use allo_isolate::Isolate;
use dup_crypto::{
    bases::b58::ToBase58,
    dewif::{Currency, DewifReadError, ExpectedCurrency, G1_CURRENCY, G1_TEST_CURRENCY},
    keys::{
        ed25519::KeyPairFromSeed32Generator, KeyPair as _, KeyPairEnum, Signator as _,
        Signature as _,
    },
    mnemonic::{Language, Mnemonic, MnemonicType},
};
use ffi_helpers::null_pointer_check;
use std::{ffi::CStr, io, os::raw};
use thiserror::Error;

/// Dubp error
#[derive(Debug, Error)]
pub enum DubpError {
    #[error("{0}")]
    DewifReadError(DewifReadError),
    #[error("I/O error: {0}")]
    IoErr(io::Error),
    #[error("fail to generate random bytes")]
    RandErr,
    #[error("Unknown currency name")]
    UnknownCurrencyName,
    #[error("Unknown language")]
    UnknownLanguage,
    #[error("Wrong language")]
    WrongLanguage,
}

impl From<io::Error> for DubpError {
    fn from(e: io::Error) -> Self {
        Self::IoErr(e)
    }
}

macro_rules! error {
    ($result:expr) => {
        error!($result, 0);
    };
    ($result:expr, $error:expr) => {
        match $result {
            Ok(value) => value,
            Err(e) => {
                ffi_helpers::update_last_error(e);
                return $error;
            }
        }
    };
}

macro_rules! cstr {
    ($ptr:expr) => {
        cstr!($ptr, 0);
    };
    ($ptr:expr, $error:expr) => {{
        null_pointer_check!($ptr);
        error!(unsafe { CStr::from_ptr($ptr).to_str() }, $error)
    }};
}

#[no_mangle]
pub unsafe extern "C" fn last_error_length() -> i32 {
    ffi_helpers::error_handling::last_error_length()
}

#[no_mangle]
pub unsafe extern "C" fn error_message_utf8(buf: *mut raw::c_char, length: i32) -> i32 {
    ffi_helpers::error_handling::error_message_utf8(buf, length)
}

#[no_mangle]
pub extern "C" fn change_dewif_pin(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    old_pin: *const raw::c_char,
    new_pin: *const raw::c_char,
) -> i32 {
    let currency = cstr!(currency);
    let dewif = cstr!(dewif);
    let old_pin = cstr!(old_pin);
    let new_pin = cstr!(new_pin);
    Isolate::new(port).post(error!(dewif::change_pin(currency, dewif, old_pin, new_pin)));
    1
}

#[no_mangle]
pub extern "C" fn gen_dewif(
    port: i64,
    currency: *const raw::c_char,
    language: u32,
    mnemonic: *const raw::c_char,
    pin: *const raw::c_char,
) -> i32 {
    let currency = cstr!(currency);
    let mnemonic = cstr!(mnemonic);
    let pin = cstr!(pin);
    Isolate::new(port).post(error!(dewif::gen_dewif(currency, language, mnemonic, pin)));
    1
}

#[no_mangle]
pub extern "C" fn gen_mnemonic(port: i64, language: u32) -> i32 {
    Isolate::new(port).post(error!(mnemonic::gen_mnemonic(language)));
    1
}

#[no_mangle]
pub extern "C" fn gen_pin6(port: i64) -> i32 {
    Isolate::new(port).post(error!(dewif::gen_pin6()));
    1
}

#[no_mangle]
pub extern "C" fn gen_pin8(port: i64) -> i32 {
    Isolate::new(port).post(error!(dewif::gen_pin8()));
    1
}

#[no_mangle]
pub extern "C" fn gen_pin10(port: i64) -> i32 {
    Isolate::new(port).post(error!(dewif::gen_pin10()));
    1
}

#[no_mangle]
pub extern "C" fn get_dewif_pubkey(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
) -> i32 {
    let currency = cstr!(currency);
    let dewif = cstr!(dewif);
    let pin = cstr!(pin);
    Isolate::new(port).post(error!(dewif::get_pubkey(
        currency,
        dewif,
        &pin.to_ascii_uppercase()
    )));
    1
}

#[no_mangle]
pub extern "C" fn mnemonic_to_pubkey(
    port: i64,
    language: u32,
    mnemonic_phrase: *const raw::c_char,
) -> i32 {
    let mnemonic_phrase = cstr!(mnemonic_phrase);
    Isolate::new(port).post(error!(mnemonic::mnemonic_to_pubkey(
        language,
        mnemonic_phrase
    )));
    1
}

#[no_mangle]
pub extern "C" fn sign(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msg: *const raw::c_char,
) -> i32 {
    let currency = cstr!(currency);
    let dewif = cstr!(dewif);
    let pin = cstr!(pin);
    let msg = cstr!(msg);
    Isolate::new(port).post(error!(dewif::sign(
        currency,
        dewif,
        &pin.to_ascii_uppercase(),
        msg
    )));
    1
}

#[no_mangle]
pub extern "C" fn sign_several(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msgs: *const raw::c_char,
) -> i32 {
    let currency = cstr!(currency);
    let dewif = cstr!(dewif);
    let pin = cstr!(pin);
    let msgs = cstr!(msgs);
    Isolate::new(port).post(error!(dewif::sign_several(
        currency,
        dewif,
        &pin.to_ascii_uppercase(),
        msgs
    )));
    1
}

fn u32_to_language(i: u32) -> Result<Language, DubpError> {
    match i {
        0 => Ok(Language::English),
        1 => Ok(Language::French),
        _ => Err(DubpError::UnknownLanguage),
    }
}
