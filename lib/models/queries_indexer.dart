const String getNameByAddressQ = r'''
query ($address: String!) {
  account_by_pk(id: $address) {
    identity {
      name
    }
  }
}
''';

const String searchAddressByNameQ = r'''
query ($name: String!) {
  search_identity(args: {name: $name}) {
    id
    name
  }
}
''';

const String getHistoryByAddressQ = r'''
query ($address: String!, $number: Int!, $cursor: String) {
  transaction_connection(where: 
  {_or: [
    {issuer_id: {_eq: $address}}, 
    {receiver_id: {_eq: $address}}
  ]}, 
  order_by: {created_at: desc},
  first: $number,
  after: $cursor) {
    edges {
      node {
        amount
        created_at
        issuer_id
        receiver_id
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

// To parse indexer date format
// log.d(DateTime.parse("2022-06-13T16:51:24.001+00:00").toString());
