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

const String getHistoryByAddressRelayQ = r'''
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

const String getHistoryByAddressQ = r'''
query ($address: String!, $number: Int!, $offset: Int!) {
  transaction_aggregate(where: {_or: [{issuer_pubkey: {_eq: $address}}, {receiver_pubkey: {_eq: $address}}]}) {
    aggregate {
      count
    }
  }
  transaction(where: {_or: [{issuer_pubkey: {_eq: $address}}, {receiver_pubkey: {_eq: $address}}]}, order_by: {created_at: desc}, limit: $number, offset: $offset) {
    amount
    comment
    created_at
    issuer {
      pubkey
      identity {
        name
      }
    }
    receiver {
      pubkey
      identity {
        name
      }
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

const String isIdtyExistQ = r'''
query ($name: String!) {
  identity(where: {name: {_eq: $name}}) {
    name
  }
}
''';

const String getBlockchainStartQ = r'''
query {
  block(limit: 1) {
    created_at
    number
  }
}
''';

const String subscribeHistoryIssuedQ = r'''
subscription ($address: String!) {
  account_by_pk(pubkey: $address) {
    transactions_issued(limit: 1, order_by: {created_at: desc}) {
      receiver_pubkey
      amount
      created_at
    }
  }
}
''';
