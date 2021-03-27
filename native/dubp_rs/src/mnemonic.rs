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

pub(super) fn gen_mnemonic(language: Language) -> Result<String, DubpError> {
    let mnemonic =
        Mnemonic::new(MnemonicType::Words12, language).map_err(|_| DubpError::RandErr)?;
    Ok(mnemonic.phrase().to_owned())
}

pub(super) fn mnemonic_to_pubkey(language: Language, mnemonic: &str) -> Result<String, DubpError> {
    let mnemonic =
        Mnemonic::from_phrase(mnemonic, language).map_err(|_| DubpError::WrongLanguage)?;
    let seed = dubp_client::crypto::mnemonic::mnemonic_to_seed(&mnemonic);
    let keypair = KeyPairFromSeed32Generator::generate(seed);
    Ok(keypair.public_key().to_base58())
}
