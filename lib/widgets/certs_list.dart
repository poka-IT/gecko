import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/widgets/cert_tile.dart';

class CertDisplayItem {
  final String address;
  final String name;
  final String date;

  CertDisplayItem({required this.address, required this.name, required this.date});
}

class CertsList extends StatefulWidget {
  const CertsList({super.key, required this.address, this.direction = CertDirection.received});
  final String address;
  final CertDirection direction;

  @override
  State<CertsList> createState() => _CertsListState();
}

class _CertsListState extends State<CertsList> {
  late Future<List<CertDisplayItem>> _certsFuture;
  List<CertDisplayItem>? _cachedCerts;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _certsFuture = _loadCerts();
  }

  String formatNumber(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  Future<List<CertDisplayItem>> _loadCerts() async {
    try {
      List<CertDisplayItem> listCerts = [];

      if (widget.direction == CertDirection.received) {
        final certConnection = await SquidService.client.getCertsReceived(widget.address);
        if (certConnection == null) return [];

        // Use typed GraphQL objects directly
        for (final edge in certConnection.edges) {
          final cert = edge.node;
          if (!cert.isActive) continue;

          final String? personAddress = cert.issuer?.accountId;
          final String? personName = cert.issuer?.name;
          final String? timestampString = cert.updatedIn?.block?.timestamp;

          if (timestampString != null) {
            final timestamp = DateTime.parse(timestampString);
            final dp = DateTime(timestamp.year, timestamp.month, timestamp.day);
            final dateForm = '${formatNumber(dp.day)}-${formatNumber(dp.month)}-${dp.year}';

            // Check if we have a more recent certification, we skip
            if (!listCerts.any((existingCert) => existingCert.address == personAddress)) {
              listCerts.add(CertDisplayItem(address: personAddress ?? '', name: personName ?? '', date: dateForm));
            }
          }
        }
      } else {
        final certConnection = await SquidService.client.getCertsSent(widget.address);
        if (certConnection == null) return [];

        // Use typed GraphQL objects directly
        for (final edge in certConnection.edges) {
          final cert = edge.node;
          if (!cert.isActive) continue;

          final String? personAddress = cert.receiver?.accountId;
          final String? personName = cert.receiver?.name;
          final String? timestampString = cert.updatedIn?.block?.timestamp;

          if (personAddress != null && timestampString != null) {
            final timestamp = DateTime.parse(timestampString);
            final dp = DateTime(timestamp.year, timestamp.month, timestamp.day);
            final dateForm = '${formatNumber(dp.day)}-${formatNumber(dp.month)}-${dp.year}';

            // Check if we have a more recent certification, we skip
            if (!listCerts.any((existingCert) => existingCert.address == personAddress)) {
              listCerts.add(CertDisplayItem(address: personAddress, name: personName ?? '', date: dateForm));
            }
          }
        }
      }

      return listCerts;
    } catch (e) {
      log.e('Error loading certs: $e');
      return [];
    }
  }

  Future<void> _refreshCerts() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final newCerts = await _loadCerts();
      setState(() {
        _cachedCerts = newCerts;
        _certsFuture = Future.value(newCerts);
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      log.e('Error refreshing certs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final windowHeight = screenHeight - appBarHeight - (isTall ? 170 : 140);

    return FutureBuilder<List<CertDisplayItem>>(
      future: _certsFuture,
      builder: (context, snapshot) {
        // If we're refreshing and have cached data, show the cached data
        if (_isRefreshing && _cachedCerts != null) {
          return _buildContent(windowHeight, _cachedCerts!, context, isRefreshing: true);
        }

        // Initial loading state
        if (snapshot.connectionState == ConnectionState.waiting && _cachedCerts == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          log.e('Error loading certs: ${snapshot.error}');
          return Column(
            children: <Widget>[
              ScaledSizedBox(height: 50),
              Text("noNetworkNoHistory".tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 17)),
            ],
          );
        }

        final List<CertDisplayItem> listCerts = snapshot.data ?? [];

        // Cache the data for future refreshes
        if (listCerts.isNotEmpty) {
          _cachedCerts = listCerts;
        }

        if (listCerts.isEmpty) {
          return Column(
            children: <Widget>[
              ScaledSizedBox(height: 50),
              Text("noDataToDisplay".tr(), style: scaledTextStyle(fontSize: 17)),
            ],
          );
        }

        return _buildContent(windowHeight, listCerts, context);
      },
    );
  }

  Widget _buildContent(
    double windowHeight,
    List<CertDisplayItem> listCerts,
    BuildContext context, {
    bool isRefreshing = false,
  }) {
    return SizedBox(
      height: windowHeight,
      child: RefreshIndicator(
        color: context.colorScheme.primary,
        onRefresh: _refreshCerts,
        child: ListView(
          key: keyListTransactions,
          children: <Widget>[
            Column(children: <Widget>[CertTile(listCerts: listCerts)]),
            // Show a small loading indicator at the bottom when refreshing
            if (isRefreshing)
              Container(
                height: 30,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum CertDirection { received, sent }
