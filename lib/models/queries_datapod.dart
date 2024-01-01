const String updateProfileQ = r'''
mutation ($address: String!, $hash: String!, $signature: String!, $title: String, $description: String, $avatar: String, $geoloc: GeolocInput, $city: String, $socials: [SocialInput!]) {
  updateProfile(address: $address, hash: $hash, signature: $signature, title: $title, description: $description, avatarBase64: $avatar, geoloc: $geoloc, city: $city, socials: $socials) {
    message
    success
  }
}
''';

const String deleteProfileQ = r'''
mutation ($address: String!, $hash: String!, $signature: String!) {
  deleteProfile(address: $address, hash: $hash, signature: $signature) {
    message
    success
  }
}
''';

const String migrateProfileQ = r'''
mutation ($addressOld: String!, $addressNew: String!, $hash: String!, $signature: String!) {
  migrateProfile(addressOld: $addressOld, addressNew: $addressNew, hash: $hash, signature: $signature) {
    message
    success
  }
}
''';
