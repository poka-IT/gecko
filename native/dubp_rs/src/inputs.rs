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

pub(crate) fn char_ptr_to_str<'a>(c_char_ptr: *const raw::c_char) -> Result<&'a str, DubpError> {
    if c_char_ptr.is_null() {
        Err(DubpError::NullParamErr)
    } else {
        unsafe { CStr::from_ptr(c_char_ptr).to_str() }.map_err(DubpError::Utf8Error)
    }
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

pub(crate) fn u32_to_language(i: u32) -> Result<Language, DubpError> {
    match i {
        0 => Ok(Language::English),
        1 => Ok(Language::French),
        _ => Err(DubpError::UnknownLanguage),
    }
}
