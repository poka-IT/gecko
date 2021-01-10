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
mod inputs;
mod legacy;
mod mnemonic;
mod secret_code;

use crate::error::{DartRes, DubpError};
use crate::inputs::*;
use crate::r#async::exec_async;
use crate::secret_code::gen_secret_code;
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

#[no_mangle]
pub extern "C" fn change_dewif_secret_code(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    old_pin: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
    system_memory: i64,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let dewif = char_ptr_to_str(dewif)?;
            let old_pin = char_ptr_to_str(old_pin)?;
            let member_wallet = member_wallet != 0;
            let secret_code_type = SecretCodeType::from(secret_code_type);
            Ok((
                currency,
                dewif,
                old_pin,
                member_wallet,
                secret_code_type,
                system_memory,
            ))
        },
        |(currency, dewif, old_pin, member_wallet, secret_code_type, system_memory)| {
            dewif::change_secret_code(
                currency,
                dewif,
                old_pin,
                member_wallet,
                secret_code_type,
                system_memory,
            )
        },
    )
}

#[no_mangle]
pub extern "C" fn gen_dewif(
    port: i64,
    currency: *const raw::c_char,
    language: u32,
    mnemonic: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
    system_memory: i64,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let language = u32_to_language(language)?;
            let mnemonic = char_ptr_to_str(mnemonic)?;
            let member_wallet = member_wallet != 0;
            let secret_code_type = SecretCodeType::from(secret_code_type);
            Ok((
                currency,
                language,
                mnemonic,
                member_wallet,
                secret_code_type,
                system_memory,
            ))
        },
        |(currency, language, mnemonic, member_wallet, secret_code_type, system_memory)| {
            dewif::gen_dewif(
                currency,
                language,
                mnemonic,
                member_wallet,
                secret_code_type,
                system_memory,
            )
        },
    )
}

#[no_mangle]
pub extern "C" fn gen_mnemonic(port: i64, language: u32) {
    exec_async(port, || u32_to_language(language), mnemonic::gen_mnemonic)
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
            let currency = parse_currency(char_ptr_to_str(currency)?)?;
            let dewif = char_ptr_to_str(dewif)?;
            let pin = char_ptr_to_str(pin)?;
            Ok((currency, dewif, pin))
        },
        |(currency, dewif, pin)| dewif::get_pubkey(currency, dewif, pin),
    )
}

#[no_mangle]
pub extern "C" fn get_legacy_pubkey(
    port: i64,
    salt: *const raw::c_char,
    password: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let salt = char_ptr_to_str(salt)?;
            let password = char_ptr_to_str(password)?;
            Ok((salt, password))
        },
        |(salt, password)| Ok::<_, DubpError>(legacy::get_pubkey(salt, password)),
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
            let language = u32_to_language(language)?;
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
pub extern "C" fn sign_legacy(
    port: i64,
    salt: *const raw::c_char,
    password: *const raw::c_char,
    msg: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let salt = char_ptr_to_str(salt)?;
            let password = char_ptr_to_str(password)?;
            let msg = char_ptr_to_str(msg)?;
            Ok((salt, password, msg))
        },
        |(salt, password, msg)| Ok::<_, DubpError>(legacy::sign(salt, password, msg)),
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
