const String getHistory = r'''
  query ($pubkey: String!, $number: Int!, $cursor: String) {
        txsHistoryBc(
            script: $pubkey
            pagination: { pageSize: $number, ord: DESC, cursor: $cursor }
        ) {
            both {
                pageInfo {
                    hasPreviousPage
                    hasNextPage
                    startCursor
                    endCursor
                }
                edges {
                    direction
                    node {
                        currency
                        issuers
                        outputs
                        comment
                        writtenTime
                    }
                }
            }
        }
        txsHistoryMp(pubkey: $pubkey) {
            receiving {
                currency
                issuers
                comment
                outputs
                writtenTime
            }
            sending {
                currency
                issuers
                comment
                outputs
                writtenTime
            }
      }
      currentUd {
        amount
        base
      }
      balance(script: $pubkey) {
        amount
        base
    }
  }
  ''';

const String getBalance = r'''
  query ($pubkey: String!) {
      balance(script: $pubkey) {
        amount
        base
      }
      currentUd {
        amount
        base
      }
    }
  ''';

const String getWallets = r'''
query ($number: Int!, $cursor: String) {
  wallets(pagination: {ord: ASC, pageSize: $number, cursor: $cursor}) {
    pageInfo {
      hasNextPage
      endCursor
    }
    edges {
      node {
        script
        balance {
          amount
          base
        }
        idty {
          isMember
          username
        }
      }
    }
  }
}
''';
