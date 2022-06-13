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
query ($address: String!) {
  account_by_pk(id: "5CQ8T4qpbYJq7uVsxGPQ5q2df7x3Wa4aRY6HUWMBYjfLZhnn") {
    transactions_issued {
      receiver_id
      amount
      created_at
      created_on
    }
    transactions_received {
      issuer_id
      amount
      created_at
      created_on
    }
  }
}
''';

const String getHistoryByAddressQ2 = r'''
query ($address: String!) {
  {
    transaction(where: {_or: [{issuer_id: {_eq: $address}}, 
      {receiver_id: {_eq: $address}}]}, order_by: {created_at: desc})
  {
      amount
      created_at
      issuer_id
      receiver_id
    }
  }
}
''';

const String getHistoryByAddressQ3 = r'''
query ($address: String!) {
  transaction_connection(where: 
  {_or: [
    {issuer_id: {_eq: $address}}, 
    {receiver_id: {_eq: $address}}
  ]}, 
  order_by: {created_at: desc}) {
    edges {
      node {
        amount
        created_at
        issuer_id
        receiver_id
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
