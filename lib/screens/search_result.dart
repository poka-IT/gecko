import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';

import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/providers_deprecated/search.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/search_result_list.dart';
import 'package:provider/provider.dart' as old_provider;

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProvider = old_provider.Provider.of<SearchProvider>(context, listen: false);
    final walletsProfilesClass = old_provider.Provider.of<WalletsProfilesProvider>(context, listen: false);

    final avatarSize = scaleSize(37);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('researchResults'.tr()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ScaledSizedBox(height: 20),
              Center(
                child: Column(
                  children: <Widget>[
                    Text("resultsFor".tr(), style: scaledTextStyle(color: Colors.grey[600], fontSize: 15)),
                    Text(
                      '"${searchProvider.searchController.text}"',
                      style: scaledTextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                    ),
                  ],
                ),
              ),
              ScaledSizedBox(height: 22),
              Text('inBlockchainResult'.tr(args: [Durt.i.network.symbol]), style: scaledTextStyle(fontSize: 15)),
              ScaledSizedBox(height: 13),
              SearchResult(
                searchProvider: searchProvider,
                avatarSize: avatarSize,
                walletsProfilesClass: walletsProfilesClass,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
