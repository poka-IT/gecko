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
use dup_crypto::keys::ed25519::{KeyPairFromSaltedPasswordGenerator, SaltedPassword};

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
        .generate(SaltedPassword::new(salt, password));

    let log_n = crate::dewif::log_n(system_memory);
    let secret_code = gen_secret_code(member_wallet, secret_code_type, log_n)?;
    let dewif = dup_crypto::dewif::write_dewif_v3_content(currency, &keypair, log_n, &secret_code);
    let pubkey = keypair.public_key().to_base58();
    Ok(vec![dewif, secret_code, pubkey])
}

pub(super) fn get_pubkey(salt: &str, password: &str) -> String {
    KeyPairFromSaltedPasswordGenerator::with_default_parameters()
        .generate(SaltedPassword::new(salt.to_owned(), password.to_owned()))
        .public_key()
        .to_base58()
}

pub(super) fn sign(salt: &str, password: &str, msg: &str) -> String {
    KeyPairFromSaltedPasswordGenerator::with_default_parameters()
        .generate(SaltedPassword::new(salt.to_owned(), password.to_owned()))
        .generate_signator()
        .sign(msg.as_bytes())
        .to_base64()
}
