import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';

import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/search_result_list.dart';

class SearchResultScreen extends ConsumerWidget {
  const SearchResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = ref.watch(searchTextProvider);

    final avatarSize = scaleSize(37);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('researchResults'.tr()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                        Text('"$searchText"', style: scaledTextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: 22),
                  Text('inBlockchainResult'.tr(args: [Durt.i.network.symbol]), style: scaledTextStyle(fontSize: 15)),
                  ScaledSizedBox(height: 13),
                  SearchResult(avatarSize: avatarSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
