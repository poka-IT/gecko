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

pub(super) fn change_secret_code(
    currency: &str,
    dewif: &str,
    old_secret_code: &str,
    member_wallet: bool,
    secret_code_type: SecretCodeType,
    system_memory: i64,
) -> Result<Vec<String>, DubpError> {
    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        old_secret_code,
    )
    .map_err(DubpError::DewifReadError)?;
    if let Some(KeyPairEnum::Ed25519(keypair)) = keypairs.next() {
        let log_n = log_n(system_memory);
        let new_secret_code = gen_secret_code(member_wallet, secret_code_type, log_n)?;

        let dewif =
            dup_crypto::dewif::write_dewif_v3_content(currency, &keypair, log_n, &new_secret_code);
        let pubkey = keypair.public_key().to_base58();
        Ok(vec![dewif, new_secret_code, pubkey])
    } else {
        Err(DubpError::DewifReadError(DewifReadError::CorruptedContent))
    }
}

pub(super) fn gen_dewif(
    currency: &str,
    language: Language,
    mnemonic: &str,
    member_wallet: bool,
    secret_code_type: SecretCodeType,
    system_memory: i64,
) -> Result<Vec<String>, DubpError> {
    let currency = parse_currency(currency)?;
    let mnemonic =
        Mnemonic::from_phrase(mnemonic, language).map_err(|_| DubpError::WrongLanguage)?;
    let seed = dup_crypto::mnemonic::mnemonic_to_seed(&mnemonic);
    let keypair = KeyPairFromSeed32Generator::generate(seed);

    let log_n = log_n(system_memory);
    let secret_code = gen_secret_code(member_wallet, secret_code_type, log_n)?;
    let dewif = dup_crypto::dewif::write_dewif_v3_content(currency, &keypair, log_n, &secret_code);
    let pubkey = keypair.public_key().to_base58();
    Ok(vec![dewif, secret_code, pubkey])
}

pub(super) fn get_pubkey(currency: Currency, dewif: &str, pin: &str) -> Result<String, DubpError> {
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

pub(super) fn sign(currency: &str, dewif: &str, pin: &str, msg: &str) -> Result<String, DubpError> {
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
    currency: &str,
    dewif: &str,
    pin: &str,
    msgs: &[&str],
) -> Result<Vec<String>, DubpError> {
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

fn log_n(system_memory: i64) -> u8 {
    if system_memory > 3_000_000_000 {
        15
    } else {
        12
    }
}
