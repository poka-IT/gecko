# Universal Dividends Integration

This document explains how to use the new universal dividends (UD) integration feature in the Gecko wallet.

## Overview

The wallet now supports displaying universal dividends alongside regular transactions in the account history. This feature allows users to see a complete picture of their account activity, including both peer-to-peer transfers and universal dividend payments.

## New Features

### 1. Extended Transaction Display Model

The `TransactionDisplayItem` class now supports both transactions and universal dividends:

```dart
enum TransactionType { transfer, universalDividend }

class TransactionDisplayItem {
  final TransactionType type;
  // ... other fields
  
  bool get isUniversalDividend => type == TransactionType.universalDividend;
  String get displayType => isUniversalDividend ? "Universal Dividend" : "Transfer";
}
```

### 2. Enhanced Transaction History Provider

The `TransactionHistoryNotifier` now includes methods to control universal dividend display:

```dart
// Toggle universal dividends on/off
historyNotifier.toggleUniversalDividends();

// Set universal dividends display explicitly
historyNotifier.setIncludeUniversalDividends(true);

// Get statistics about current loaded data
final stats = historyNotifier.getTransactionStats();
```

### 3. New GraphQL Query

A new GraphQL query `GetUdHistory` has been added to fetch universal dividend history:

```graphql
query GetUdHistory($identityRow: identity_scalar!, $after: String, $first: Int = 20) {
  getUdHistory_connection(
    args: { identity_row: $identityRow }
    after: $after
    first: $first
    orderBy: { timestamp: DESC }
  ) {
    edges {
      node {
        id
        amount
        timestamp
        blockNumber
        identityId
        identity {
          name
          accountId
        }
      }
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
```

### 4. Combined Service Method

A new service method `getCombinedAccountHistory` fetches and combines both transaction and UD data:

```dart
final result = await d.SquidService.client.getCombinedAccountHistory(
  address, 
  number: 20, 
  cursor: null, 
  includeUniversalDividends: true,
);
```

## Usage Examples

### Basic Usage in Widget

```dart
class AccountHistoryWidget extends ConsumerWidget {
  final String address;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(transactionHistoryProvider(address));
    final historyNotifier = ref.read(transactionHistoryProvider(address).notifier);
    
    return Column(
      children: [
        // Toggle button for universal dividends
        ElevatedButton(
          onPressed: () => historyNotifier.toggleUniversalDividends(),
          child: Text(historyState.includeUniversalDividends 
            ? 'Hide Universal Dividends' 
            : 'Show Universal Dividends'),
        ),
        
        // Display transaction list
        Expanded(
          child: ListView.builder(
            itemCount: historyState.transactions.length,
            itemBuilder: (context, index) {
              final transaction = historyState.transactions[index];
              return ListTile(
                leading: Icon(transaction.isUniversalDividend 
                  ? Icons.savings 
                  : Icons.swap_horiz),
                title: Text(transaction.displayType),
                subtitle: Text(transaction.amount.toString()),
                trailing: Text(transaction.timestamp.toString()),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

### Advanced Usage with Statistics

```dart
class AccountStatsWidget extends ConsumerWidget {
  final String address;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyNotifier = ref.read(transactionHistoryProvider(address).notifier);
    final stats = historyNotifier.getTransactionStats();
    
    return Card(
      child: Column(
        children: [
          Text('Total Items: ${stats['total_items']}'),
          Text('Transfers: ${stats['transfers']}'),
          Text('Universal Dividends: ${stats['universal_dividends']}'),
          Text('UDs Enabled: ${stats['include_uds_enabled']}'),
        ],
      ),
    );
  }
}
```

## Data Flow

1. **User toggles UD display** → `toggleUniversalDividends()` called
2. **Provider refreshes data** → `getCombinedAccountHistory()` called with `includeUniversalDividends` flag
3. **Service fetches data** → Both transfer and UD GraphQL queries executed
4. **Data combined and sorted** → Items sorted by timestamp, newest first
5. **UI updated** → `TransactionDisplayItem` objects created for both types

## Key Points

- Universal dividends are always marked as "received" since they are always credited to the account
- Universal dividends don't have comments (unlike transfers)
- The feature is backward compatible - existing code continues to work
- Pagination works across both data types
- Real-time updates via subscriptions are maintained

## Implementation Details

- **GraphQL Schema**: Uses `getUdHistory_connection` with `identity_scalar` parameter
- **Type Safety**: Strong typing with `TransactionType` enum
- **Performance**: Data is fetched in parallel and combined client-side
- **Pagination**: Simplified pagination using transfer connection's page info
- **Error Handling**: Graceful fallback if UD queries fail

This integration provides a comprehensive view of account activity while maintaining the existing functionality and performance characteristics of the wallet. 