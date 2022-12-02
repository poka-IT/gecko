const String getNameByAddressQ = r'''
query ($address: String!) {
  account_by_pk(pubkey: $address) {
    identity {
      name
    }
    pubkey
  }
}
''';

const String searchAddressByNameQ = r'''
query ($name: String!) {
  search_identity(args: {name: $name}) {
    pubkey
    name
  }
}
''';

const String getHistoryByAddressQ = r'''
query ($address: String!, $number: Int!, $cursor: String) {
  transaction_connection(where: 
  {_or: [
    {issuer_pubkey: {_eq: $address}}, 
    {receiver_pubkey: {_eq: $address}}
  ]}, 
  order_by: {created_at: desc},
  first: $number,
  after: $cursor) {
    edges {
      node {
        amount
        created_at
        issuer_pubkey
        receiver_pubkey
        issuer {
          identity {
            name
          }
        }
        receiver {
          identity {
            name
          }
        }
      }
    }
    pageInfo {
      endCursor
      hasNextPage
      hasPreviousPage
      startCursor
    }
  }
}
''';

const String getCertsReceived = r'''
query ($address: String!) {
  certification(where: {receiver: {pubkey: {_eq: $address}}}) {
    issuer {
      pubkey
      name
    }
    created_at
  }
}
''';

const String getCertsSent = r'''
query ($address: String!) {
  certification(where: {issuer: {pubkey: {_eq: $address}}}) {
    receiver {
      pubkey
      name
    }
    created_at
  }
}
''';
