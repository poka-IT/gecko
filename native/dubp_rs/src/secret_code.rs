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

pub(crate) fn gen_secret_code(
    member_wallet: bool,
    secret_code_type: SecretCodeType,
    log_n: u8,
) -> Result<String, DubpError> {
    match secret_code_type {
        SecretCodeType::Digits => {
            if member_wallet {
                Err(DubpError::DigitsCodeForbidForMemberWallet)
            } else if log_n >= 15 {
                gen_random_digits(7)
            } else {
                gen_random_digits(8)
            }
        }
        SecretCodeType::Letters => {
            if member_wallet {
                gen_random_letters(10)
            } else if log_n >= 15 {
                gen_random_letters(5)
            } else {
                gen_random_letters(6)
            }
        }
    }
}

fn gen_random_digits(n: usize) -> Result<String, DubpError> {
    let mut digits_string = dup_crypto::rand::gen_u32()
        .map_err(|_| DubpError::RandErr)?
        .to_string();
    digits_string.truncate(n);

    if digits_string.len() == n {
        Ok(digits_string)
    } else {
        let missing_digits = n - digits_string.len();
        let mut digits_string_ = String::with_capacity(n);
        for _ in 0..missing_digits {
            digits_string_.push('0');
        }
        digits_string_.push_str(&digits_string);
        Ok(digits_string_)
    }
}

fn gen_random_letters(mut n: usize) -> Result<String, DubpError> {
    let mut letters = String::with_capacity(n);
    while n >= 6 {
        letters.push_str(&gen_random_letters_inner(6)?);
        n -= 6;
    }
    letters.push_str(&gen_random_letters_inner(n)?);

    Ok(letters)
}

fn gen_random_letters_inner(n: usize) -> Result<String, DubpError> {
    let mut i = dup_crypto::rand::gen_u32().map_err(|_| DubpError::RandErr)?;
    let mut letters = String::new();

    for _ in 0..n {
        letters.push(to_char(i));
        i /= 26;
    }

    Ok(letters)
}

fn to_char(i: u32) -> char {
    match i % 26 {
        0 => 'A',
        1 => 'B',
        2 => 'C',
        3 => 'D',
        4 => 'E',
        5 => 'F',
        6 => 'G',
        7 => 'H',
        8 => 'I',
        9 => 'J',
        10 => 'K',
        11 => 'L',
        12 => 'M',
        13 => 'N',
        14 => 'O',
        15 => 'P',
        16 => 'Q',
        17 => 'R',
        18 => 'S',
        19 => 'T',
        20 => 'U',
        21 => 'V',
        22 => 'W',
        23 => 'X',
        24 => 'Y',
        25 => 'Z',
        _ => unreachable!(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gen_random_digits() -> Result<(), DubpError> {
        assert_eq!(gen_random_digits(8)?.len(), 8);
        //println!("TMP: {}", gen_random_digits(8)?);
        Ok(())
    }
    #[test]
    fn test_gen_random_letters() -> Result<(), DubpError> {
        assert_eq!(gen_random_letters(6)?.len(), 6);
        //println!("TMP: {}", gen_random_letters(6)?);
        Ok(())
    }
}
