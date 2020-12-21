const String getMyRepositories = r'''
  query ($pubkey: String!, $number: Int!) {
        txsHistoryBc(
            pubkeyOrScript: $pubkey
            pagination: { pageSize: $number, ord: DESC }
        ) {
            both {
                pageInfo {
                    hasPreviousPage
                    hasNextPage
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
  }
  ''';
