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

pub(crate) fn sign(
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
    if let Some(KeyPairEnum::Ed25519(keypair)) = keypairs.next() {
        Ok(keypair.generate_signator().sign(msg.as_bytes()).to_base64())
    } else {
        Err(DubpError::DewifReadError(DewifReadError::CorruptedContent))
    }
}

pub(crate) fn sign_several(
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
