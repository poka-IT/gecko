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

pub(super) fn gen_pin6() -> Result<String, DubpError> {
    let i = dup_crypto::rand::gen_u32().map_err(|_| DubpError::RandErr)?;
    Ok(gen_pin6_inner(i))
}
pub(super) fn gen_pin8() -> Result<String, DubpError> {
    let i = dup_crypto::rand::gen_u32().map_err(|_| DubpError::RandErr)?;
    let i2 = dup_crypto::rand::gen_u32().map_err(|_| DubpError::RandErr)?;
    let mut pin = gen_pin6_inner(i);
    gen_pin2_inner(i2, &mut pin);
    Ok(pin)
}
pub(super) fn gen_pin10() -> Result<String, DubpError> {
    let i = dup_crypto::rand::gen_u32().map_err(|_| DubpError::RandErr)?;
    let i2 = dup_crypto::rand::gen_u32().map_err(|_| DubpError::RandErr)?;
    let mut pin = gen_pin6_inner(i);
    gen_pin4_inner(i2, &mut pin);
    Ok(pin)
}

pub(super) fn change_pin(
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    old_pin: *const raw::c_char,
    new_pin: *const raw::c_char,
) -> Result<String, DubpError> {
    let currency = char_ptr_to_str(currency)?;
    let dewif = char_ptr_to_str(dewif)?;
    let old_pin = char_ptr_to_str(old_pin)?;
    let new_pin = char_ptr_to_str(new_pin)?;

    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        old_pin,
    )
    .map_err(DubpError::DewifReadError)?;
    if let Some(KeyPairEnum::Ed25519(keypair)) = keypairs.next() {
        Ok(dup_crypto::dewif::write_dewif_v1_content(
            currency, &keypair, new_pin,
        ))
    } else {
        Err(DubpError::DewifReadError(DewifReadError::CorruptedContent))
    }
}

pub(super) fn gen_dewif(
    currency: *const raw::c_char,
    language: u32,
    mnemonic: *const raw::c_char,
    pin: *const raw::c_char,
) -> Result<String, DubpError> {
    let currency = char_ptr_to_str(currency)?;
    let mnemonic = char_ptr_to_str(mnemonic)?;
    let pin = char_ptr_to_str(pin)?;

    let currency = parse_currency(currency)?;
    let mnemonic = Mnemonic::from_phrase(mnemonic, u32_to_language(language)?)
        .map_err(|_| DubpError::WrongLanguage)?;
    let seed = dup_crypto::mnemonic::mnemonic_to_seed(&mnemonic);
    let keypair = KeyPairFromSeed32Generator::generate(seed);
    Ok(dup_crypto::dewif::write_dewif_v1_content(
        currency, &keypair, pin,
    ))
}

pub(super) fn get_pubkey(
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
) -> Result<String, DubpError> {
    let currency = char_ptr_to_str(currency)?;
    let dewif = char_ptr_to_str(dewif)?;
    let pin = char_ptr_to_str(pin)?;

    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &pin.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;
    if let Some(KeyPairEnum::Ed25519(keypair)) = keypairs.next() {
        Ok(keypair.public_key().to_base58())
    } else {
        Err(DubpError::DewifReadError(DewifReadError::CorruptedContent))
    }
}

pub(super) fn sign(
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msg: *const raw::c_char,
) -> Result<String, DubpError> {
    let currency = char_ptr_to_str(currency)?;
    let dewif = char_ptr_to_str(dewif)?;
    let pin = char_ptr_to_str(pin)?;
    let msg = char_ptr_to_str(msg)?;

    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &pin.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;
    if let Some(KeyPairEnum::Ed25519(keypair)) = keypairs.next() {
        Ok(keypair.generate_signator().sign(msg.as_bytes()).to_base64())
    } else {
        Err(DubpError::DewifReadError(DewifReadError::CorruptedContent))
    }
}

pub(super) fn sign_several(
    currency: *const raw::c_char,
    dewif: *const raw::c_char,
    pin: *const raw::c_char,
    msgs_len: usize,
    msgs: *const *const raw::c_char,
) -> Result<Vec<String>, DubpError> {
    let currency = char_ptr_to_str(currency)?;
    let dewif = char_ptr_to_str(dewif)?;
    let pin = char_ptr_to_str(pin)?;

    let msgs_slice: &[*const raw::c_char] = unsafe { std::slice::from_raw_parts(msgs, msgs_len) };
    let mut msgs = Vec::with_capacity(msgs_len);
    for ptr_c_char in msgs_slice {
        msgs.push(char_ptr_to_str(*ptr_c_char)?);
    }

    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &pin.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;
    if let Some(KeyPairEnum::Ed25519(keypair)) = keypairs.next() {
        let signator = keypair.generate_signator();
        Ok(msgs
            .iter()
            .map(|msg| signator.sign(msg.as_bytes()).to_base64())
            .collect())
    } else {
        Err(DubpError::DewifReadError(DewifReadError::CorruptedContent))
    }
}

fn parse_currency(currency: &str) -> Result<Currency, DubpError> {
    let currency_code = match currency {
        "g1" => G1_CURRENCY,
        "g1-test" | "gt" => G1_TEST_CURRENCY,
        _ => return Err(DubpError::UnknownCurrencyName),
    };
    Ok(Currency::from(currency_code))
}

fn gen_pin2_inner(mut i: u32, pin: &mut String) {
    for _ in 0..2 {
        pin.push(to_char(i));
        i /= 35;
    }
}
fn gen_pin4_inner(mut i: u32, pin: &mut String) {
    for _ in 0..4 {
        pin.push(to_char(i));
        i /= 35;
    }
}
fn gen_pin6_inner(mut i: u32) -> String {
    let mut pin = String::new();

    for _ in 0..6 {
        pin.push(to_char(i));
        i /= 35;
    }

    pin
}

fn to_char(i: u32) -> char {
    match i % 35 {
        0 => 'Z',
        1 => '1',
        2 => '2',
        3 => '3',
        4 => '4',
        5 => '5',
        6 => '6',
        7 => '7',
        8 => '8',
        9 => '9',
        10 => 'A',
        11 => 'B',
        12 => 'C',
        13 => 'D',
        14 => 'E',
        15 => 'F',
        16 => 'G',
        17 => 'H',
        18 => 'I',
        19 => 'J',
        20 => 'K',
        21 => 'L',
        22 => 'M',
        23 => 'N',
        24 => 'O',
        25 => 'P',
        26 => 'Q',
        27 => 'R',
        28 => 'S',
        29 => 'T',
        30 => 'U',
        31 => 'V',
        32 => 'W',
        33 => 'X',
        34 => 'Y',
        _ => unreachable!(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gen_pin_6() {
        assert_eq!("ZZZZZZ", &gen_pin6_inner(0));
        assert_eq!("YZZZZZ", &gen_pin6_inner(34));
        assert_eq!("Z1ZZZZ", &gen_pin6_inner(35));
        assert_eq!("ZZ1ZZZ", &gen_pin6_inner(1225));
        assert_eq!("2Z1ZZZ", &gen_pin6_inner(1227));
        assert_eq!("Z11ZZZ", &gen_pin6_inner(1260));
        assert_eq!("111ZZZ", &gen_pin6_inner(1261));
    }
}
