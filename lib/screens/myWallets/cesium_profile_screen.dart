// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gecko/extensions.dart';
import 'package:latlong2/latlong.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:http/http.dart' as http;

class CesiumProfileScreen extends ConsumerStatefulWidget {
  const CesiumProfileScreen({super.key, required this.address});

  final String address;

  @override
  ConsumerState<CesiumProfileScreen> createState() => _CesiumProfileScreenState();
}

class _CesiumProfileScreenState extends ConsumerState<CesiumProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _tagController = TextEditingController();
  final MapController _mapController = MapController();

  Map<String, dynamic>? _profile;
  List<CesiumSocial> _socials = [];
  List<String> _tags = [];
  LatLng? _selectedLocation;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _cityController.dispose();
    _tagController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final cesiumPlus = ref.read(cesiumPlusServiceProvider);
      final profile = await cesiumPlus.getProfileByAddress(widget.address);

      if (profile != null) {
        _descriptionController.text = profile['description'] ?? '';
        _cityController.text = profile['city'] ?? '';

        if (profile['geoPoint'] != null) {
          final lat = double.tryParse(profile['geoPoint']['lat']?.toString() ?? '');
          final lon = double.tryParse(profile['geoPoint']['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            _selectedLocation = LatLng(lat, lon);
            // Center the map on the existing location after a small delay to ensure map is initialized
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _selectedLocation != null) {
                _mapController.move(_selectedLocation!, 13.0);
              }
            });
          }
        }

        if (profile['socials'] != null) {
          _socials =
              (profile['socials'] as List).map((s) => CesiumSocial.fromJson(s as Map<String, dynamic>)).toList();
        }

        if (profile['tags'] != null) {
          _tags = List<String>.from(profile['tags'] as List);
        }

        _profile = profile;
      }
    } catch (e) {
      log.e('Error loading Cesium+ profile: $e');
      if (mounted) {
        SnackbarService.showError(context, message: 'profileLoadFailed'.tr());
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final pinCode = await PinCodeService.askPinCode();
    if (!pinCode) {
      SnackbarService.showError(context, message: 'pinNeeded'.tr());
      return;
    }

    setState(() => _isSaving = true);

    try {
      final walletService = ref.read(walletServiceProvider);
      final keyPair = await walletService.getKeyPairFromAddress(
        address: widget.address,
        pinCode: PinCodeService.pinCode,
      );

      final cesiumPlus = ref.read(cesiumPlusServiceProvider);

      // Get current title or use wallet name as fallback
      String title = _profile?['title'] ?? 'Duniter Wallet';

      final success = await cesiumPlus.uploadProfile(
        address: widget.address,
        signFunction: keyPair.sign,
        title: title,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        geoPointLat: _selectedLocation?.latitude.toString(),
        geoPointLon: _selectedLocation?.longitude.toString(),
        socials: _socials.isEmpty ? null : _socials,
        tags: _tags.isEmpty ? null : _tags,
      );

      if (success) {
        SnackbarService.showSuccess(context, message: 'profileUpdated'.tr());
        if (mounted) Navigator.pop(context);
      } else {
        SnackbarService.showError(context, message: 'profileUpdateFailed'.tr());
      }
    } catch (e) {
      log.e('Error saving Cesium+ profile: $e');
      SnackbarService.showError(context, message: 'profileUpdateFailed'.tr());
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<List<Map<String, dynamic>>> _searchCities(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'Gecko-Wallet'});

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((r) => r as Map<String, dynamic>).toList();
      }
    } catch (e) {
      log.e('Error searching cities: $e');
    }
    return [];
  }

  void _onCitySelected(Map<String, dynamic> city) {
    final lat = double.tryParse(city['lat']?.toString() ?? '');
    final lon = double.tryParse(city['lon']?.toString() ?? '');

    if (lat != null && lon != null) {
      setState(() {
        _selectedLocation = LatLng(lat, lon);
      });
      _mapController.move(_selectedLocation!, 13.0);
    }
  }

  void _addSocial(String type, String url) {
    if (url.isEmpty) return;
    setState(() {
      _socials.add(CesiumSocial(type: type, url: url));
    });
  }

  void _removeSocial(int index) {
    setState(() {
      _socials.removeAt(index);
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cesiumProfile'.tr()), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      scaleSize(16),
                      scaleSize(16),
                      scaleSize(16),
                      scaleSize(80), // Extra padding for sticky button
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description Card
                          _buildSectionCard(
                            title: 'description'.tr(),
                            icon: Icons.person,
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: 'descriptionHint'.tr(),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: context.colorScheme.surfaceContainer,
                              ),
                              style: scaledTextStyle(fontSize: 14),
                            ),
                          ),

                          ScaledSizedBox(height: 20),

                          // City Autocomplete Card
                          _buildSectionCard(
                            title: 'city'.tr(),
                            icon: Icons.location_city,
                            child: TypeAheadField<Map<String, dynamic>>(
                              controller: _cityController,
                              suggestionsCallback: _searchCities,
                              builder: (context, controller, focusNode) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: 'cityHint'.tr(),
                                    prefixIcon: const Icon(Icons.search),
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: context.colorScheme.surfaceContainer,
                                  ),
                                  style: scaledTextStyle(fontSize: 14),
                                );
                              },
                              hideOnEmpty: true,
                              hideOnLoading: false,
                              hideOnSelect: true,
                              hideOnUnfocus: true,
                              hideOnError: true,
                              itemBuilder: (context, city) {
                                final name = city['display_name'] as String;
                                return ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: Text(name, style: scaledTextStyle(fontSize: 13)),
                                );
                              },
                              onSelected: (city) {
                                _cityController.text =
                                    (city['address']?['city'] ??
                                        city['address']?['town'] ??
                                        city['address']?['village'] ??
                                        city['name']) ??
                                    '';
                                _onCitySelected(city);
                                // Unfocus to prevent auto-refocus after dialog close
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),

                          ScaledSizedBox(height: 20),

                          // Map Card
                          _buildSectionCard(
                            title: 'geoCoordinates'.tr(),
                            icon: Icons.map,
                            tooltip: 'geoCoordinatesHelp'.tr(),
                            child: Column(
                              children: [
                                Container(
                                  height: scaleSize(200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _selectedLocation ?? LatLng(48.8566, 2.3522), // Paris by default
                                      initialZoom: 5.0,
                                      onTap: (_, latLng) {
                                        setState(() {
                                          _selectedLocation = latLng;
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'fr.axiomteam.gecko',
                                      ),
                                      if (_selectedLocation != null)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _selectedLocation!,
                                              width: scaleSize(40),
                                              height: scaleSize(40),
                                              child: Icon(
                                                Icons.location_on,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: scaleSize(40),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                ScaledSizedBox(height: 8),
                                if (_selectedLocation != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${'latitude'.tr()}: ${_selectedLocation!.latitude.toStringAsFixed(4)}',
                                        style: scaledTextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                      Text(
                                        '${'longitude'.tr()}: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                        style: scaledTextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () => setState(() => _selectedLocation = null),
                                        tooltip: 'Clear location',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          ScaledSizedBox(height: 20),

                          // Social Networks Card
                          _buildSectionCard(
                            title: 'socialNetworks'.tr(),
                            icon: Icons.share,
                            child: Column(
                              children: [
                                ..._socials.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final social = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: scaleSize(8)),
                                    child: Container(
                                      padding: EdgeInsets.all(scaleSize(12)),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(_getSocialIcon(social.type), size: scaleSize(20)),
                                          ScaledSizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  social.type,
                                                  style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  social.url,
                                                  style: scaledTextStyle(fontSize: 11, color: Colors.grey.shade700),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red.shade400, size: scaleSize(20)),
                                            onPressed: () => _removeSocial(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                ScaledSizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _showAddSocialDialog,
                                  icon: const Icon(Icons.add),
                                  label: Text('addSocialNetwork'.tr()),
                                  style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, scaleSize(44))),
                                ),
                              ],
                            ),
                          ),

                          ScaledSizedBox(height: 20),

                          // Tags Card
                          _buildSectionCard(
                            title: 'tags'.tr(),
                            icon: Icons.label,
                            child: Column(
                              children: [
                                if (_tags.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _tags.map((tag) {
                                      return Chip(
                                        label: Text(tag, style: scaledTextStyle(fontSize: 12)),
                                        deleteIcon: Icon(Icons.close, size: scaleSize(18)),
                                        onDeleted: () => _removeTag(tag),
                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      );
                                    }).toList(),
                                  ),
                                ScaledSizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _tagController,
                                        decoration: InputDecoration(
                                          hintText: 'tagHint'.tr(),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: context.colorScheme.surfaceContainer,
                                        ),
                                        style: scaledTextStyle(fontSize: 14),
                                        onFieldSubmitted: (_) => _addTag(),
                                      ),
                                    ),
                                    ScaledSizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                                      iconSize: scaleSize(32),
                                      onPressed: _addTag,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sticky Save Button
                Container(
                  padding: EdgeInsets.all(scaleSize(16)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, -2), blurRadius: 8),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: scaleSize(50),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: scaleSize(20),
                                height: scaleSize(20),
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'saveProfile'.tr(),
                                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, String? tooltip, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(scaleSize(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: scaleSize(20), color: Theme.of(context).colorScheme.primary),
                ScaledSizedBox(width: 8),
                Expanded(
                  child: Text(title, style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                if (tooltip != null)
                  GestureDetector(
                    onTap: () {
                      // Show dialog on tap for mobile
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                              ScaledSizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Information',
                                  style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          content: Text(tooltip, style: scaledTextStyle(fontSize: 14)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK', style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Tooltip(
                      message: tooltip,
                      padding: EdgeInsets.all(scaleSize(12)),
                      margin: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                      textStyle: scaledTextStyle(fontSize: 12, color: Colors.white),
                      preferBelow: false,
                      verticalOffset: scaleSize(10),
                      waitDuration: const Duration(milliseconds: 500),
                      child: Icon(Icons.info_outline, size: scaleSize(20), color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
            ScaledSizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  IconData _getSocialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'twitter':
      case 'x':
        return Icons.close; // X logo
      case 'facebook':
        return Icons.facebook;
      case 'diaspora':
      case 'mastodon':
        return Icons.public;
      case 'github':
        return Icons.code;
      case 'linkedin':
        return Icons.business;
      default:
        return Icons.link;
    }
  }

  void _showAddSocialDialog() {
    String selectedType = 'twitter';
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('addSocialNetwork'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: [
                'twitter',
                'facebook',
                'diaspora',
                'mastodon',
                'github',
                'linkedin',
                'other',
              ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) {
                if (value != null) selectedType = value;
              },
              decoration: InputDecoration(labelText: 'socialType'.tr(), border: const OutlineInputBorder()),
            ),
            ScaledSizedBox(height: 16),
            TextFormField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'url'.tr(),
                hintText: 'https://...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              _addSocial(selectedType, urlController.text);
              Navigator.pop(context);
              // Force unfocus after closing dialog to prevent city field from getting focus
              Future.delayed(const Duration(milliseconds: 100), () {
                FocusScope.of(context).unfocus();
              });
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    ).then((_) {
      // Also unfocus when dialog is dismissed
      Future.delayed(const Duration(milliseconds: 10), () {
        FocusScope.of(context).unfocus();
      });
    });
  }
}
