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

#[derive(Debug)]
struct OpaqueAccount {
    address_index: u32,
    chain_code: ChainCode,
    public_key: PublicKey,
}

static CHAINING_EXTERNAL_PUBKEYS: Lazy<Arc<Mutex<HashMap<u32, OpaqueAccount>>>> =
    Lazy::new(|| Arc::new(Mutex::new(HashMap::new())));

pub(crate) fn get_accounts_pubkeys(
    currency: Currency,
    dewif: &str,
    secret_code: &str,
    accounts_indexs: Vec<U31>,
) -> Result<Vec<String>, DubpError> {
    if accounts_indexs.contains(&U31::new(0)?) {
        verify_member_secret_code(currency, dewif, secret_code)?;
    }
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
                PrivateDerivationPath::transparent(account_index)
                    .map(|path| master_keypair.derive(path).public_key().to_base58())
            })
            .collect::<Result<Vec<_>, InvalidAccountIndex>>()?),
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

pub(crate) fn get_bip32_pubkey(
    account_index: u32,
    address_index_opt: Option<U31>,
    currency: Currency,
    dewif: &str,
    external_opt: Option<bool>,
    secret_code: &str,
) -> Result<String, DubpError> {
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;

    if account_index == 0 {
        verify_member_secret_code(currency, dewif, secret_code)?;
    }

    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => get_bip32_pubkey_inner(
            account_index,
            address_index_opt,
            external_opt,
            master_keypair,
        ),
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

pub(crate) fn get_opaque_account_next_external_address(
    account_index: U31,
) -> Result<String, DubpError> {
    let mut guard = CHAINING_EXTERNAL_PUBKEYS.lock();
    if let Some(opaque_account) = guard.get_mut(&account_index.into_u32()) {
        let next_address = PublicKeyWithChainCode {
            chain_code: opaque_account.chain_code,
            public_key: opaque_account.public_key,
        }
        .derive(U31::new(opaque_account.address_index).expect("unreachable"))
        .expect("unreachable")
        .public_key;

        opaque_account.address_index += 1;

        Ok(next_address.to_base58())
    } else {
        Err(DubpError::OpaqueAccountNotLoaded)
    }
}

pub(crate) fn load_opaque_bip32_accounts(
    accounts_indexs: Vec<U31>,
    currency: Currency,
    dewif: &str,
    secret_code: &str,
) -> Result<(), DubpError> {
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;
    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => {
            for account_index in accounts_indexs {
                let external_path = PrivateDerivationPath::opaque(account_index, true, None)?;
                let external_kp = master_keypair.derive(external_path);
                let opaque_account = OpaqueAccount {
                    address_index: 0,
                    public_key: external_kp.public_key(),
                    chain_code: external_kp.chain_code(),
                };

                let mut guard = CHAINING_EXTERNAL_PUBKEYS.lock();
                guard.insert(account_index.into_u32(), opaque_account);
            }
            Ok(())
        }
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

pub(crate) fn sign_bip32(
    account_index: u32,
    address_index_opt: Option<U31>,
    currency: Currency,
    dewif: &str,
    external_opt: Option<bool>,
    secret_code: &str,
    msg: &str,
) -> Result<String, DubpError> {
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;

    if account_index == 0 {
        verify_member_secret_code(currency, dewif, secret_code)?;
    }

    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => sign_bip32_inner(
            account_index,
            address_index_opt,
            external_opt,
            master_keypair,
            msg,
        ),
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

pub(crate) fn sign_several_bip32(
    account_index: u32,
    address_index_opt: Option<U31>,
    currency: Currency,
    dewif: &str,
    external_opt: Option<bool>,
    secret_code: &str,
    msgs: &[&str],
) -> Result<Vec<String>, DubpError> {
    let mut keypairs = dup_crypto::dewif::read_dewif_file_content(
        ExpectedCurrency::Specific(currency),
        dewif,
        &secret_code.to_ascii_uppercase(),
    )
    .map_err(DubpError::DewifReadError)?;

    if account_index == 0 {
        verify_member_secret_code(currency, dewif, secret_code)?;
    }

    match keypairs.next() {
        Some(KeyPairEnum::Bip32Ed25519(master_keypair)) => sign_several_bip32_inner(
            account_index,
            address_index_opt,
            external_opt,
            master_keypair,
            msgs,
        ),
        Some(_) => Err(DubpError::NotHdWallet),
        None => Err(DubpError::DewifReadError(DewifReadError::CorruptedContent)),
    }
}

fn get_bip32_pubkey_inner(
    account_index: u32,
    address_index_opt: Option<U31>,
    external_opt: Option<bool>,
    master_keypair: KeyPair,
) -> Result<String, DubpError> {
    Ok(master_keypair
        .derive(z_get_derivation_path(
            account_index,
            address_index_opt,
            external_opt,
        )?)
        .public_key()
        .to_base58())
}

fn sign_bip32_inner(
    account_index: u32,
    address_index_opt: Option<U31>,
    external_opt: Option<bool>,
    master_keypair: KeyPair,
    msg: &str,
) -> Result<String, DubpError> {
    Ok(master_keypair
        .derive(z_get_derivation_path(
            account_index,
            address_index_opt,
            external_opt,
        )?)
        .generate_signator()
        .sign(msg.as_bytes())
        .to_base64())
}

fn sign_several_bip32_inner(
    account_index: u32,
    address_index_opt: Option<U31>,
    external_opt: Option<bool>,
    master_keypair: KeyPair,
    msgs: &[&str],
) -> Result<Vec<String>, DubpError> {
    let signator = master_keypair
        .derive(z_get_derivation_path(
            account_index,
            address_index_opt,
            external_opt,
        )?)
        .generate_signator();

    Ok(msgs
        .iter()
        .map(|msg| signator.sign(msg.as_bytes()).to_base64())
        .collect())
}

fn verify_member_secret_code(
    currency: Currency,
    dewif: &str,
    secret_code: &str,
) -> Result<(), DubpError> {
    if crate::secret_code::is_ascii_letters(secret_code) {
        let log_n =
            dup_crypto::dewif::read_dewif_log_n(ExpectedCurrency::Specific(currency), dewif)
                .map_err(DubpError::DewifReadError)?;
        let expected_secret_code_len =
            crate::secret_code::compute_secret_code_len(true, SecretCodeType::Letters, log_n)?;

        if secret_code.len() < expected_secret_code_len {
            Err(DubpError::SecretCodeTooShort)
        } else {
            Ok(())
        }
    } else {
        Err(DubpError::InvalidSecretCodeType)
    }
}

fn z_get_derivation_path(
    account_index: u32,
    address_index_opt: Option<U31>,
    external_opt: Option<bool>,
) -> Result<PrivateDerivationPath, DubpError> {
    let account_index_u31 = U31::new(account_index)?;
    match account_index % 3 {
        0 => Ok(PrivateDerivationPath::transparent(account_index_u31)?),
        1 => {
            if let Some(external) = external_opt {
                if external {
                    if address_index_opt.is_none() {
                        Ok(PrivateDerivationPath::semi_opaque_external(
                            account_index_u31,
                        )?)
                    } else {
                        Err(DubpError::InvalidAccountIndex(InvalidAccountIndex))
                    }
                } else if address_index_opt.is_some() {
                    Ok(PrivateDerivationPath::semi_opaque_internal(
                        account_index_u31,
                        address_index_opt,
                    )?)
                } else {
                    Err(DubpError::TryToSignWithInternalChainingAddress)
                }
            } else {
                Err(DubpError::MissingExternalBool)
            }
        }
        2 => {
            if address_index_opt.is_some() {
                if let Some(external) = external_opt {
                    Ok(PrivateDerivationPath::opaque(
                        account_index_u31,
                        external,
                        address_index_opt,
                    )?)
                } else {
                    Err(DubpError::MissingExternalBool)
                }
            } else {
                Err(DubpError::TryToSignWithChainingAddress)
            }
        }
        _ => unreachable!(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use assert_matches::assert_matches;

    const MNEMONIC: &str =
        "tongue cute mail fossil great frozen same social weasel impact brush kind";

    #[test]
    fn test_get_accounts_pubkeys() -> Result<(), DubpError> {
        let vec = crate::dewif::gen_dewif(
            "g1",
            Language::English,
            MNEMONIC,
            false,
            SecretCodeType::Letters,
            1_000,
        )?;
        let dewif = &vec[0];
        let secret_code = &vec[1];
        //println!("TMP: secret_code={}", secret_code);

        assert_matches!(
            get_accounts_pubkeys(
                Currency::from(G1_CURRENCY),
                dewif,
                secret_code,
                vec![U31::new(0).expect("unreachable")],
            ),
            Err(DubpError::SecretCodeTooShort)
        );

        Ok(())
    }

    #[test]
    fn test_sign_bip32() {
        assert_matches!(
            z_get_derivation_path(1, None, None),
            Err(DubpError::MissingExternalBool)
        );
        assert_matches!(
            z_get_derivation_path(2, None, None),
            Err(DubpError::TryToSignWithChainingAddress)
        );
        assert_matches!(z_get_derivation_path(3, None, None), Ok(_));
        assert_matches!(
            z_get_derivation_path(1, None, Some(false)),
            Err(DubpError::TryToSignWithInternalChainingAddress)
        );
        assert_matches!(
            z_get_derivation_path(2, None, Some(true)),
            Err(DubpError::TryToSignWithChainingAddress)
        );
        assert_matches!(
            z_get_derivation_path(1, Some(U31::new(5).expect("unreachable")), Some(true),),
            Err(DubpError::InvalidAccountIndex(_))
        );
    }
}
