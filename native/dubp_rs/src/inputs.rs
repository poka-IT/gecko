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

use crate::*;

#[derive(Clone, Copy, Debug)]
pub(crate) enum SecretCodeType {
    Digits,
    Letters,
}
impl From<u32> for SecretCodeType {
    fn from(i: u32) -> Self {
        if i == 0 {
            SecretCodeType::Digits
        } else {
            SecretCodeType::Letters
        }
    }
}
#[derive(Clone, Copy, Debug)]
pub(crate) enum WalletType {
    Ed25519,
    Bip32Ed25519,
}
impl From<u32> for WalletType {
    fn from(i: u32) -> Self {
        if i == 1 {
            WalletType::Bip32Ed25519
        } else {
            WalletType::Ed25519
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

pub(crate) fn char_ptr_prt_to_vec_hard_derivation_index(
    u32_ptr: *const u32,
    len: u32,
) -> Result<Vec<DerivationIndex>, DubpError> {
    u32_ptr_to_vec_u32(u32_ptr, len)
        .into_iter()
        .map(|ai| DerivationIndex::hard(ai).map_err(DubpError::InvalidDerivationIndex))
        .collect()
}

pub(crate) fn char_ptr_prt_to_vec_str<'a>(
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

pub(crate) fn parse_currency(currency: &str) -> Result<Currency, DubpError> {
    let currency_code = match currency {
        "g1" => G1_CURRENCY,
        "g1-test" | "gt" => G1_TEST_CURRENCY,
        _ => return Err(DubpError::UnknownCurrencyName),
    };
    Ok(Currency::from(currency_code))
}

pub(crate) fn transparent_account_index(account_index: u32) -> Result<DerivationIndex, DubpError> {
    if account_index % 3 == 0 {
        DerivationIndex::hard(account_index).map_err(DubpError::InvalidDerivationIndex)
    } else {
        Err(DubpError::NotTransparentAccountIndex)
    }
}

pub(crate) fn u32_ptr_to_vec_u32(u32_ptr: *const u32, len: u32) -> Vec<u32> {
    let len = len as usize;
    let u32_slice: &[u32] = unsafe { std::slice::from_raw_parts(u32_ptr, len) };
    let mut vec = Vec::with_capacity(len);
    for u32_ in u32_slice {
        vec.push(*u32_);
    }
    vec
}

pub(crate) fn u32_to_language(i: u32) -> Result<Language, DubpError> {
    match i {
        0 => Ok(Language::English),
        1 => Ok(Language::French),
        _ => Err(DubpError::UnknownLanguage),
    }
}
