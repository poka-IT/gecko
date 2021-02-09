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

pub(crate) fn get_accounts_pubkeys(
    currency: Currency,
    dewif: &str,
    secret_code: &str,
    accounts_indexs: Vec<DerivationIndex>,
) -> Result<Vec<String>, DubpError> {
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;
    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => Ok(accounts_indexs
            .into_iter()
            .map(|account_index| {
                master_keypair
                    .derive(account_index)
                    .public_key()
                    .to_base58()
            })
            .collect()),
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

pub(crate) fn sign_transparent(
    account_index: DerivationIndex,
    currency: &str,
    dewif: &str,
    secret_code: &str,
    msg: &str,
) -> Result<String, DubpError> {
    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;

    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => Ok(master_keypair
            .derive(account_index)
            .generate_signator()
            .sign(msg.as_bytes())
            .to_base64()),
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

pub(crate) fn sign_several_transparent(
    account_index: DerivationIndex,
    currency: &str,
    dewif: &str,
    secret_code: &str,
    msgs: &[&str],
) -> Result<Vec<String>, DubpError> {
    let currency = parse_currency(currency)?;
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;

    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => {
            let signator = master_keypair.derive(account_index).generate_signator();
            Ok(msgs
                .iter()
                .map(|msg| signator.sign(msg.as_bytes()).to_base64())
                .collect())
        }
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}
