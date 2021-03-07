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

pub mod bip32;
pub mod classic;

use crate::*;

pub(super) fn change_secret_code(
    dewif: &str,
    old_secret_code: &str,
    member_wallet: bool,
    secret_code_type: SecretCodeType,
    system_memory: i64,
) -> Result<Vec<String>, DubpError> {
    let new_log_n = log_n(system_memory);
    let new_secret_code = gen_secret_code(member_wallet, secret_code_type, new_log_n)?;

    let new_dewif =
        dup_crypto::dewif::change_dewif_passphrase(dewif, old_secret_code, &new_secret_code)
            .map_err(DubpError::DewifReadError)?;

    Ok(vec![new_dewif, new_secret_code])
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

    let log_n = log_n(system_memory);
    let secret_code = gen_secret_code(member_wallet, secret_code_type, log_n)?;

    let keypair = dup_crypto::keys::ed25519::bip32::KeyPair::from_seed(seed.clone());
    let pubkey = keypair.public_key();
    let dewif =
        dup_crypto::dewif::write_dewif_v4_content(currency, log_n, &secret_code, &pubkey, seed);

    Ok(vec![dewif, secret_code])
}

pub(super) fn get_dewif_meta(
    dewif: &str,
    member_wallet: bool,
    secret_code_type: SecretCodeType,
) -> Result<Vec<String>, DubpError> {
    let dup_crypto::dewif::DewifMeta {
        currency,
        log_n,
        version,
    } = dup_crypto::dewif::read_dewif_meta(dewif).map_err(DubpError::DewifReadError)?;

    let secret_code_len =
        crate::secret_code::compute_secret_code_len(member_wallet, secret_code_type, log_n)?;

    Ok(vec![
        currency.to_string(),
        secret_code_len.to_string(),
        version.to_string(),
    ])
}

pub(super) fn get_pubkey(
    account_index_opt: Option<u32>,
    address_index_opt: Option<U31>,
    currency: Currency,
    dewif: &str,
    external_opt: Option<bool>,
    secret_code: &str,
) -> Result<String, DubpError> {
    if let Some(account_index) = account_index_opt {
        dewif::bip32::get_bip32_pubkey(
            account_index,
            address_index_opt,
            currency,
            dewif,
            external_opt,
            secret_code,
        )
    } else if address_index_opt.is_none() && external_opt.is_none() {
        let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
            ExpectedCurrency::Specific(currency),
            dewif,
            &secret_code.to_ascii_uppercase(),
        )
        .map_err(DubpError::DewifReadError)?;

        match keypairs.next() {
            Some(KeyPairEnum::Ed25519(keypair)) => Ok(keypair.public_key().to_base58()),
            Some(KeyPairEnum::Bip32Ed25519(_)) => Err(DubpError::GetMasterPubkeyOfHdWallet),
            Some(_) => Err(DubpError::UnsupportedDewifVersion),
            None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
        }
    } else {
        Err(DubpError::GiveExternalBoolOrAddressIndexForLegacyWallet)
    }
}

pub(super) fn get_secret_code_len(
    dewif: *const raw::c_char,
    member_wallet: u32,
    secret_code_type: u32,
) -> Result<usize, DubpError> {
    let dewif = char_ptr_to_str(dewif)?;
    let member_wallet = member_wallet != 0;
    let secret_code_type = SecretCodeType::from(secret_code_type);

    let log_n = dup_crypto::dewif::read_dewif_log_n(ExpectedCurrency::Any, dewif)
        .map_err(DubpError::DewifReadError)?;

    Ok(crate::secret_code::compute_secret_code_len(
        member_wallet,
        secret_code_type,
        log_n,
    )?)
}

pub(crate) fn log_n(system_memory: i64) -> u8 {
    if system_memory > 3_000_000_000 {
        15
    } else {
        12
    }
}

pub(super) fn sign(
    account_index_opt: Option<u32>,
    address_index_opt: Option<U31>,
    currency: Currency,
    dewif: &str,
    external_opt: Option<bool>,
    secret_code: &str,
    msg: &str,
) -> Result<String, DubpError> {
    if let Some(account_index) = account_index_opt {
        dewif::bip32::sign_bip32(
            account_index,
            address_index_opt,
            currency,
            dewif,
            external_opt,
            secret_code,
            msg,
        )
    } else {
        dewif::classic::sign(currency, dewif, secret_code, msg)
    }
}

pub(super) fn sign_several(
    account_index_opt: Option<u32>,
    address_index_opt: Option<U31>,
    currency: Currency,
    dewif: &str,
    external_opt: Option<bool>,
    secret_code: &str,
    msgs: &[&str],
) -> Result<Vec<String>, DubpError> {
    if let Some(account_index) = account_index_opt {
        dewif::bip32::sign_several_bip32(
            account_index,
            address_index_opt,
            currency,
            dewif,
            external_opt,
            secret_code,
            msgs,
        )
    } else {
        dewif::classic::sign_several(currency, dewif, secret_code, msgs)
    }
}
