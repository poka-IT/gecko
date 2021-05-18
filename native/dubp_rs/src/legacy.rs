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
use dubp_client::crypto::keys::ed25519::{KeyPairFromSaltedPasswordGenerator, SaltedPassword};

#[allow(deprecated)]
pub(super) fn gen_dewif_from_legacy(
    currency: &str,
    salt: String,
    password: String,
    member_wallet: bool,
    secret_code_type: SecretCodeType,
    system_memory: i64,
) -> Result<Vec<String>, DubpError> {
    let currency = parse_currency(currency)?;
    let keypair = KeyPairFromSaltedPasswordGenerator::with_default_parameters()
        .generate(SaltedPassword::new(salt.clone(), password.clone()));

    let log_n = crate::dewif::log_n(system_memory);
    let secret_code = gen_secret_code(member_wallet, secret_code_type, log_n)?;
    let dewif = dubp_client::crypto::dewif::create_dewif_v1_legacy(
        currency,
        log_n,
        password,
        salt,
        &secret_code,
    )
    .map_err(|_| DubpError::RandErr)?;
    let pubkey = keypair.public_key().to_base58();
    Ok(vec![dewif, secret_code, pubkey])
}

pub(super) fn get_pubkey(salt: &str, password: &str) -> String {
    KeyPairFromSaltedPasswordGenerator::with_default_parameters()
        .generate(SaltedPassword::new(salt.to_owned(), password.to_owned()))
        .public_key()
        .to_base58()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dewif_legacy() -> Result<(), DubpError> {
        let wallet = gen_dewif_from_legacy(
            "g1",
            "salt".to_owned(),
            "pass".to_owned(),
            false,
            SecretCodeType::Letters,
            1_000_000_000,
        )?;
        let dewif = &wallet[0];
        let secret_code = &wallet[1];
        let pubkey = &wallet[2];

        assert_eq!(pubkey, "3YumN7F7D8c2hmkHLHf3ZD8wc3tBHiECEK9zLPkaJtAF");

        assert_eq!(get_pubkey("salt", "pass"), pubkey.to_owned());

        assert_eq!(
            crate::dewif::get_pubkey(
                None,
                None,
                Currency::from(G1_CURRENCY),
                &dewif,
                None,
                &secret_code
            )?,
            pubkey.to_owned()
        );

        Ok(())
    }
}
