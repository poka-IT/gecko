const getNameByAddressQ = r'''
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

const searchAddressByNameQ = r'''
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

const getHistoryByAddressRelayQ = r'''
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

const getCertsReceived = r'''
query ($address: String!) {
  certConnection(
    where: {receiver: {accountId: {_eq: $address}}}
    orderBy: {updatedOn: DESC}
  ) {
    edges {
      node {
        isActive
        updatedIn {
          block {
            timestamp
          }
        }
        issuer {
          accountId
          name
        }
      }
    }
  }
}
''';

const getCertsSent = r'''
query ($address: String!) {
  certConnection(
    where: {issuer: {accountId: {_eq: $address}}}
    orderBy: {updatedOn: DESC}
  ) {
    edges {
      node {
        isActive
        updatedIn {
          block {
            timestamp
          }
        }
        receiver {
          accountId
          name
        }
      }
    }
  }
}
''';

const isIdtyExistQ = r'''
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

const getBlockchainStartQ = r'''
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

const subscribeHistoryIssuedQ = r'''
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

const getBlockByHash = r'''
query ($hash: bytea!) {
  block(where: {hash: {_eq: $hash}}) {
    height
  }
}
''';
