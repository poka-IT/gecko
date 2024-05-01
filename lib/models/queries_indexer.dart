const String getNameByAddressQ = r'''
query ($address: String!) {
  identityConnection(
    where: { accountId: { _eq: $address } }
    orderBy: { name: ASC }
  ) {
    edges {
      node {
        name
        accountId
      }
    }
  }
}
''';

const String searchAddressByNameQ = r'''
query ($name: String!) {
  identityConnection(
    where: { name: { _ilike: $name } }
    orderBy: { name: ASC }
  ) {
    edges {
      node {
        name
        accountId
      }
    }
  }
}
''';

const String getHistoryByAddressRelayQ = r'''
query ($address: String!, $first: Int!, $after: String) {
  transferConnection(
    after: $after
    first: $first
    orderBy: { timestamp: DESC }
    where: { _or: [{ fromId: { _eq: $address } }, { toId: { _eq: $address } }] }
  ) {
    edges {
      node {
        amount
        timestamp
        fromId
        from {
          identity {
            name
          }
        }
        toId
        to {
          identity {
            name
          }
        }
      }
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
''';

const String getCertsReceived = r'''
query ($address: String!) {
  certConnection(
    where: {receiver: {accountId: {_eq: $address}}}
  ) {
    edges {
      node {
        isActive
        createdOn
        issuer {
          accountId
          name
        }
      }
    }
  }
}
''';

const String getCertsSent = r'''
query ($address: String!) {
  certConnection(
    where: {issuer: {accountId: {_eq: $address}}}
  ) {
    edges {
      node {
        isActive
        createdOn
        receiver {
          accountId
          name
        }
      }
    }
  }
}
''';

const String isIdtyExistQ = r'''
query ($name: String!) {
  identityConnection(where: {name: {_eq: ""}}) {
    edges {
      node {
        name
      }
    }
  }
}
''';

const String getBlockchainStartQ = r'''
query {
  blockConnection(first: 1) {
    edges {
      node {
        height
        timestamp
      }
    }
  }
}
''';

const String subscribeHistoryIssuedQ = r'''
subscription ($address: String!) {
  accountConnection(
    where: {id: {_eq: $address}}
  ) {
    edges {
      node {
        transfersIssued(limit: 1, orderBy: {timestamp: DESC}) {
          toId
          amount
          timestamp
          blockNumber
        }
      }
    }
  }
}
''';
