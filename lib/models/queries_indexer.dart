const String getNameByAddressQ = r'''
query ($address: String!) {
  account_by_pk(id: $address) {
    identity {
      name
    }
  }
}
''';
