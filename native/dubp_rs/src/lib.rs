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
        ed25519::bip32::{
            ChainCode, InvalidAccountIndex, KeyPair, PrivateDerivationPath, PublicKeyWithChainCode,
        },
        ed25519::{KeyPairFromSeed32Generator, PublicKey},
        KeyPair as _, KeyPairEnum, Signator as _, Signature as _,
    },
    mnemonic::{Language, Mnemonic, MnemonicType},
    utils::{U31Error, U31},
};
use fast_threadpool::{ThreadPool, ThreadPoolConfig, ThreadPoolSyncHandler};
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use std::{collections::HashMap, ffi::CStr, io, os::raw, sync::Arc};
use thiserror::Error;

#[no_mangle]
pub extern "C" fn change_dewif_secret_code(
    port: i64,
    dewif: *const raw::c_char,
    old_secret_code: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
    system_memory: i64,
) {
    exec_async(
        port,
        || {
            let dewif = char_ptr_to_str(dewif)?;
            let old_secret_code = char_ptr_to_str(old_secret_code)?;
            let member_wallet = member_wallet != 0;
            let secret_code_type = SecretCodeType::from(secret_code_type);
            Ok((
                dewif,
                old_secret_code,
                member_wallet,
                secret_code_type,
                system_memory,
            ))
        },
        |(dewif, old_secret_code, member_wallet, secret_code_type, system_memory)| {
            dewif::change_secret_code(
                dewif,
                old_secret_code,
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
pub extern "C" fn gen_dewif_from_legacy(
    port: i64,
    currency: *const raw::c_char,
    salt: *const raw::c_char,
    password: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
    system_memory: i64,
) {
    exec_async(
        port,
        || {
            let currency = char_ptr_to_str(currency)?;
            let salt = char_ptr_to_str(salt)?.to_owned();
            let password = char_ptr_to_str(password)?.to_owned();
            let member_wallet = member_wallet != 0;
            let secret_code_type = SecretCodeType::from(secret_code_type);
            Ok((
                currency,
                salt,
                password,
                member_wallet,
                secret_code_type,
                system_memory,
            ))
        },
        |(currency, salt, password, member_wallet, secret_code_type, system_memory)| {
            legacy::gen_dewif_from_legacy(
                currency,
                salt,
                password,
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
pub extern "C" fn get_bip32_dewif_accounts_pubkeys(
    port: i64,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    secret_code: *const raw::c_char,
    accounts_indexs_len: u32,
    accounts_indexs: *const u32,
) {
    exec_async(
        port,
        || {
            let currency = parse_currency(char_ptr_to_str(currency)?)?;
            let dewif = char_ptr_to_str(dewif)?;
            let secret_code = char_ptr_to_str(secret_code)?;
            let accounts_indexs = char_ptr_prt_to_vec_u31(accounts_indexs, accounts_indexs_len)?;
            Ok((currency, dewif, secret_code, accounts_indexs))
        },
        |(currency, dewif, secret_code, accounts_indexs)| {
            dewif::bip32::get_accounts_pubkeys(currency, dewif, secret_code, accounts_indexs)
        },
    )
}

#[no_mangle]
pub extern "C" fn get_dewif_meta(
    port: i64,
    dewif: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
) {
    exec_async(
        port,
        || {
            let dewif = char_ptr_to_str(dewif)?;
            let member_wallet = member_wallet != 0;
            let secret_code_type = SecretCodeType::from(secret_code_type);
            Ok((dewif, member_wallet, secret_code_type))
        },
        |(dewif, member_wallet, secret_code_type)| {
            dewif::get_dewif_meta(dewif, member_wallet, secret_code_type)
        },
    )
}

#[no_mangle]
pub extern "C" fn get_dewif_secret_code_len(
    dewif: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
) -> i32 {
    if let Ok(secret_code_len) = dewif::get_secret_code_len(dewif, member_wallet, secret_code_type)
    {
        secret_code_len as i32
    } else {
        -1
    }
}

#[no_mangle]
pub extern "C" fn get_dewif_pubkey(
    port: i64,
    account_index: i32,
    address_index: i32,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    external_opt: i32,
    pin: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let account_index_opt = i32_to_opt_u32(account_index);
            let address_index_opt = i32_to_opt_u31(address_index)?;
            let currency = parse_currency(char_ptr_to_str(currency)?)?;
            let dewif = char_ptr_to_str(dewif)?;
            let external_opt = i32_to_opt_bool(external_opt);
            let pin = char_ptr_to_str(pin)?;
            Ok((
                account_index_opt,
                address_index_opt,
                currency,
                dewif,
                external_opt,
                pin,
            ))
        },
        |(account_index_opt, address_index_opt, currency, dewif, external_opt, pin)| {
            dewif::get_pubkey(
                account_index_opt,
                address_index_opt,
                currency,
                dewif,
                external_opt,
                pin,
            )
        },
    )
}

#[no_mangle]
pub extern "C" fn get_opaque_account_next_external_address(port: i64, account_index: u32) {
    exec_async(
        port,
        || {
            let account_index = U31::new(account_index)?;
            Ok(account_index)
        },
        dewif::bip32::get_opaque_account_next_external_address,
    )
}

#[no_mangle]
pub extern "C" fn load_opaque_bip32_accounts(
    port: i64,
    accounts_indexs_len: u32,
    accounts_indexs: *const u32,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    secret_code: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let accounts_indexs = char_ptr_prt_to_vec_u31(accounts_indexs, accounts_indexs_len)?;
            let currency = parse_currency(char_ptr_to_str(currency)?)?;
            let dewif = char_ptr_to_str(dewif)?;
            let secret_code = char_ptr_to_str(secret_code)?;
            Ok((accounts_indexs, currency, dewif, secret_code))
        },
        |(accounts_indexs, currency, dewif, secret_code)| {
            dewif::bip32::load_opaque_bip32_accounts(accounts_indexs, currency, dewif, secret_code)
        },
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
    account_index: i32,
    address_index: i32,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    external_opt: i32,
    secret_code: *const raw::c_char,
    msg: *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let account_index_opt = i32_to_opt_u32(account_index);
            let address_index_opt = i32_to_opt_u31(address_index)?;
            let currency = parse_currency(char_ptr_to_str(currency)?)?;
            let dewif = char_ptr_to_str(dewif)?;
            let external_opt = i32_to_opt_bool(external_opt);
            let secret_code = char_ptr_to_str(secret_code)?;
            let msg = char_ptr_to_str(msg)?;
            Ok((
                account_index_opt,
                address_index_opt,
                currency,
                dewif,
                external_opt,
                secret_code,
                msg,
            ))
        },
        |(
            account_index_opt,
            address_index_opt,
            currency,
            dewif,
            external_opt,
            secret_code,
            msg,
        )| {
            dewif::sign(
                account_index_opt,
                address_index_opt,
                currency,
                dewif,
                external_opt,
                secret_code,
                msg,
            )
        },
    )
}

#[no_mangle]
pub extern "C" fn sign_several(
    port: i64,
    account_index: i32,
    address_index: i32,
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    external_opt: i32,
    secret_code: *const raw::c_char,
    msgs_len: u32,
    msgs: *const *const raw::c_char,
) {
    exec_async(
        port,
        || {
            let account_index_opt = i32_to_opt_u32(account_index);
            let address_index_opt = i32_to_opt_u31(address_index)?;
            let currency = parse_currency(char_ptr_to_str(currency)?)?;
            let dewif = char_ptr_to_str(dewif)?;
            let external_opt = i32_to_opt_bool(external_opt);
            let secret_code = char_ptr_to_str(secret_code)?;
            let msgs = char_ptr_prt_to_vec_str(msgs, msgs_len)?;
            Ok((
                account_index_opt,
                address_index_opt,
                currency,
                dewif,
                external_opt,
                secret_code,
                msgs,
            ))
        },
        |(
            account_index_opt,
            address_index_opt,
            currency,
            dewif,
            external_opt,
            secret_code,
            msgs,
        )| {
            dewif::sign_several(
                account_index_opt,
                address_index_opt,
                currency,
                dewif,
                external_opt,
                secret_code,
                &msgs,
            )
        },
    )
}
