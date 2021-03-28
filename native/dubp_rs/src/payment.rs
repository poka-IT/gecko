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
use dubp_client::wallet::prelude::*;
use dubp_client::{GvaClient, NaiveGvaClient};

#[allow(clippy::too_many_arguments)]
pub(super) fn simple_payment(
    account_index: u32,
    amount: f64,
    currency: Currency,
    dewif: &str,
    gva_endpoint: &str,
    secret_code: &str,
    recipient: &str,
    tx_comment: Option<String>,
) -> Result<(), DubpError> {
    let keypair = crate::dewif::bip32::get_bip32_keypair(
        account_index,
        None,
        currency,
        dewif,
        None,
        secret_code,
    )?;

    let gva_client = NaiveGvaClient::new(gva_endpoint).expect("invalid' endpoint");

    let amount = dubp_client::Amount::Uds(amount);

    let recipient = if let Ok(pubkey) = PublicKey::from_base58(recipient) {
        WalletScriptV10::single_sig(pubkey)
    } else {
        dubp_client::documents_parser::wallet_script_from_str(recipient)
            .map_err(DubpError::InvalidScript)?
    };

    let res = match keypair.generate_signator() {
        dubp_client::crypto::keys::SignatorEnum::Ed25519(signator) => gva_client
            .simple_payment(amount, &signator, recipient, tx_comment, None)
            .map_err(DubpError::GvaClientError)?,
        dubp_client::crypto::keys::SignatorEnum::Schnorr() => unreachable!(),
        dubp_client::crypto::keys::SignatorEnum::Bip32Ed25519(signator) => gva_client
            .simple_payment(amount, &signator, recipient, tx_comment, None)
            .map_err(DubpError::GvaClientError)?,
    };

    if let dubp_client::PaymentResult::Errors(errors) = res {
        Err(DubpError::PaymentError(format!("{:?}", errors)))
    } else {
        Ok(())
    }
}
