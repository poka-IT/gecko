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
use std::{ffi::CStr, io, os::raw};
use thiserror::Error;

/// Dubp error
#[derive(Debug, Error)]
pub enum DubpError {
    #[error("{0}")]
    DewifReadError(DewifReadError),
    #[error("I/O error: {0}")]
    IoErr(io::Error),
    #[error("A given parameter is null")]
    NullParamErr,
    #[error("fail to generate random bytes")]
    RandErr,
    #[error("Unknown currency name")]
    UnknownCurrencyName,
    #[error("Unknown language")]
    UnknownLanguage,
    #[error("{0}")]
    Utf8Error(std::str::Utf8Error),
    #[error("Wrong language")]
    WrongLanguage,
}

impl From<io::Error> for DubpError {
    fn from(e: io::Error) -> Self {
        Self::IoErr(e)
    }
}

struct DartRes(allo_isolate::ffi::DartCObject);
impl IntoDart for DartRes {
    fn into_dart(self) -> allo_isolate::ffi::DartCObject {
        self.0.into_dart()
    }
}
impl<E> From<Result<String, E>> for DartRes
where
    E: ToString,
{
    fn from(res: Result<String, E>) -> Self {
        match res {
            Ok(string) => Self(vec![string].into_dart()),
            Err(e) => Self(vec![String::from("_"), e.to_string()].into_dart()),
        }
    }
}
impl<E> From<Result<Vec<String>, E>> for DartRes
where
    E: ToString,
{
    fn from(res: Result<Vec<String>, E>) -> Self {
        match res {
            Ok(vec_string) => Self(vec_string.into_dart()),
            Err(e) => Self(vec![String::with_capacity(0), e.to_string()].into_dart()),
        }
    }
}

pub(crate) fn char_ptr_to_str<'a>(c_char_ptr: *const raw::c_char) -> Result<&'a str, DubpError> {
    if c_char_ptr.is_null() {
        Err(DubpError::NullParamErr)
    } else {
        unsafe { CStr::from_ptr(c_char_ptr).to_str() }.map_err(DubpError::Utf8Error)
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
    Isolate::new(port).post(DartRes::from(dewif::change_pin(
        currency, dewif, old_pin, new_pin,
    )));
}

#[no_mangle]
pub extern "C" fn gen_dewif(
    port: i64,
    currency: *const raw::c_char,
    language: u32,
    mnemonic: *const raw::c_char,
    pin: *const raw::c_char,
) {
    Isolate::new(port).post(DartRes::from(dewif::gen_dewif(
        currency, language, mnemonic, pin,
    )));
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
    Isolate::new(port).post(DartRes::from(dewif::get_pubkey(currency, dewif, pin)));
}

#[no_mangle]
pub extern "C" fn mnemonic_to_pubkey(
    port: i64,
    language: u32,
    mnemonic_phrase: *const raw::c_char,
) {
    Isolate::new(port).post(DartRes::from(mnemonic::mnemonic_to_pubkey(
        language,
        mnemonic_phrase,
    )));
}

#[no_mangle]
pub extern "C" fn sign(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msg: *const raw::c_char,
) {
    Isolate::new(port).post(DartRes::from(dewif::sign(currency, dewif, pin, msg)));
}

#[no_mangle]
pub extern "C" fn sign_several(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msgs_len: usize,
    msgs: *const *const raw::c_char,
) {
    Isolate::new(port).post(dewif::sign_several(currency, dewif, pin, msgs_len, msgs));
}

fn u32_to_language(i: u32) -> Result<Language, DubpError> {
    match i {
        0 => Ok(Language::English),
        1 => Ok(Language::French),
        _ => Err(DubpError::UnknownLanguage),
    }
}
