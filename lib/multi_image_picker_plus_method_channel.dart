import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'multi_image_picker_plus.dart';
import 'multi_image_picker_plus_platform_interface.dart';

/// An implementation of [MultiImagePickerPlatform] that uses method channels.
class MethodChannelMultiImagePicker extends MultiImagePickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('multi_image_picker_plus');

  @override
  Future<List<Asset>> pickImages({
    List<Asset> selectedAssets = const [],
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) async {
    try {
      final List<dynamic> images = await methodChannel.invokeMethod(
        'pickImages',
        <String, dynamic>{
          'iosOptions': cupertinoOptions.toJson(),
          'androidOptions': materialOptions.toJson(),
          'selectedAssets': selectedAssets
              .map(
                (Asset asset) => asset.identifier,
              )
              .toList(),
        },
      );
      final List<Asset> assets = <Asset>[];
      for (var item in images) {
        final Asset asset = Asset(
          item['identifier'],
          item['name'],
          item['width'],
          item['height'],
        );
        assets.add(asset);
      }
      return assets;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "CANCELLED":
          throw NoImagesSelectedException(e.message ?? 'CANCELLED');
        default:
          rethrow;
      }
    }
  }

  @override
  Future<bool> requestThumbnail(
    String identifier,
    int width,
    int height,
    int quality,
  ) async {
    if (width < 0) {
      throw ArgumentError.value(width, 'width cannot be negative');
    }

    if (height < 0) {
      throw ArgumentError.value(height, 'height cannot be negative');
    }

    if (quality > 100) {
      throw ArgumentError.value(quality, 'quality should be in range 0-100');
    }

    try {
      final bool ret = await methodChannel.invokeMethod(
          "requestThumbnail", <String, dynamic>{
        "identifier": identifier,
        "width": width,
        "height": height,
        "quality": quality
      });
      return ret;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "ASSET_DOES_NOT_EXIST":
          throw AssetNotFoundException(e.message ?? 'ASSET_DOES_NOT_EXIST');
        case "PERMISSION_DENIED":
          throw PermissionDeniedException(e.message ?? 'PERMISSION_DENIED');
        case "PERMISSION_PERMANENTLY_DENIED":
          throw PermissionPermanentlyDeniedExeption(
              e.message ?? 'PERMISSION_PERMANENTLY_DENIED');
        default:
          rethrow;
      }
    }
  }

  @override
  Future<bool> requestOriginal(String identifier, quality) async {
    try {
      final bool ret =
          await methodChannel.invokeMethod("requestOriginal", <String, dynamic>{
        "identifier": identifier,
        "quality": quality,
      });
      return ret;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "ASSET_DOES_NOT_EXIST":
          throw AssetNotFoundException(e.message ?? 'ASSET_DOES_NOT_EXIST');
        default:
          rethrow;
      }
    }
  }

  // Requests image metadata for a given [identifier]
  @override
  Future<Metadata> requestMetadata(String identifier) async {
    final Map<dynamic, dynamic> map = await methodChannel.invokeMethod(
      "requestMetadata",
      <String, dynamic>{
        "identifier": identifier,
      },
    );

    Map<String, dynamic> metadata = Map<String, dynamic>.from(map);
    if (Platform.isIOS) {
      metadata = _normalizeMetadata(metadata);
    }

    return Metadata.fromMap(metadata);
  }

  /// Normalizes the meta data returned by iOS.
  Map<String, dynamic> _normalizeMetadata(Map<String, dynamic> json) {
    final Map<String, dynamic> map = <String, dynamic>{};

    json.forEach((String metaKey, dynamic metaValue) {
      if (metaKey == '{Exif}' || metaKey == '{TIFF}') {
        map.addAll(Map<String, dynamic>.from(metaValue));
      } else if (metaKey == '{GPS}') {
        final Map<String, dynamic> gpsMap = <String, dynamic>{};
        final Map<String, dynamic> metaMap =
            Map<String, dynamic>.from(metaValue);
        metaMap.forEach((String key, dynamic value) {
          if (key == 'GPSVersion') {
            gpsMap['GPSVersionID'] = value;
          } else {
            gpsMap['GPS$key'] = value;
          }
        });
        map.addAll(gpsMap);
      } else {
        map[metaKey] = metaValue;
      }
    });

    return map;
  }
}
