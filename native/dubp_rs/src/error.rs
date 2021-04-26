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

/// Dubp error
#[allow(clippy::large_enum_variant)]
#[derive(Debug, Error)]
pub(crate) enum DubpError {
    #[error("{0}")]
    DewifReadError(DewifReadError),
    #[error("Digits secret code forbid for member wallet")]
    DigitsCodeForbidForMemberWallet,
    #[error("It is forbidden to retrieve the master public key of an HD wallet.")]
    GetMasterPubkeyOfHdWallet,
    #[error("Give external bool or address index for legacy wallet.")]
    GiveExternalBoolOrAddressIndexForLegacyWallet,
    #[error("{0}")]
    GvaClientError(dubp_client::GvaClientError),
    #[error("I/O error: {0}")]
    IoErr(io::Error),
    #[error("{0}")]
    InvalidAccountIndex(InvalidAccountIndex),
    #[error("{0}")]
    InvalidPubkey(PublicKeyFromStrErr),
    #[error("{0}")]
    InvalidScript(dubp_client::documents_parser::TextParseError),
    #[error("{0}")]
    InvalidU31(U31Error),
    #[error("Invalid secret code type")]
    InvalidSecretCodeType,
    #[error("Missing external bool")]
    MissingExternalBool,
    #[error("this wallet is not an HD wallet")]
    NotHdWallet,
    #[error("A given parameter is null")]
    NullParamErr,
    #[error("Opaque account not loaded")]
    OpaqueAccountNotLoaded,
    #[error("Payment error: {0}")]
    PaymentError(String),
    #[error("Secret code too short: please change your secret code")]
    SecretCodeTooShort,
    #[error("The chaining address cannot be used to sign with opaque account")]
    TryToSignWithChainingAddress,
    #[error("The internal chaining address cannot be used to sign with semi-opaque account")]
    TryToSignWithInternalChainingAddress,
    #[error("fail to generate random bytes")]
    RandErr,
    #[error("Unknown currency name")]
    UnknownCurrencyName,
    #[error("Unknown language")]
    UnknownLanguage,
    //#[error("Unsupported DEWIF version")]
    //UnsupportedDewifVersion,
    #[error("{0}")]
    Utf8Error(std::str::Utf8Error),
    #[error("Wrong language")]
    WrongLanguage,
}

impl From<io::Error> for DubpError {
    fn from(e: io::Error) -> Self {
        Self::IoErr(e)
    }
}

impl From<InvalidAccountIndex> for DubpError {
    fn from(e: InvalidAccountIndex) -> Self {
        Self::InvalidAccountIndex(e)
    }
}

impl From<U31Error> for DubpError {
    fn from(e: U31Error) -> Self {
        Self::InvalidU31(e)
    }
}

pub(crate) struct DartRes(allo_isolate::ffi::DartCObject);
impl DartRes {
    pub(crate) fn err<E: ToString>(e: E) -> allo_isolate::ffi::DartCObject {
        vec![format!("DUBP_RS_ERROR: {}", e.to_string())].into_dart()
    }
}
impl IntoDart for DartRes {
    fn into_dart(self) -> allo_isolate::ffi::DartCObject {
        self.0.into_dart()
    }
}
impl<E> From<Result<(), E>> for DartRes
where
    E: ToString,
{
    fn from(res: Result<(), E>) -> Self {
        match res {
            Ok(()) => Self("".into_dart()),
            Err(e) => Self(format!("DUBP_RS_ERROR: {}", e.to_string()).into_dart()),
        }
    }
}
impl<E> From<Result<String, E>> for DartRes
where
    E: ToString,
{
    fn from(res: Result<String, E>) -> Self {
        match res {
            Ok(string) => Self(string.into_dart()),
            Err(e) => Self(format!("DUBP_RS_ERROR: {}", e.to_string()).into_dart()),
        }
    }
}
impl<E> From<Result<Vec<String>, E>> for DartRes
where
    E: ToString,
{
    fn from(res: Result<Vec<String>, E>) -> Self {
        match res {
            Ok(vec_string) => Self(vec_string.into_dart()),
            Err(e) => Self(vec![format!("DUBP_RS_ERROR: {}", e.to_string())].into_dart()),
        }
    }
}
