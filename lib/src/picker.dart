import 'dart:async';

import '../multi_image_picker_plus.dart';
import '../multi_image_picker_plus_platform_interface.dart';

class MultiImagePicker {
  /// Invokes the multi image picker selector.
  ///
  /// On iOS you can pass also [cupertinoOptions] parameter which should be
  /// an instance of [CupertinoOptions] class. It allows you
  /// to customize the look of the image picker. On Android
  /// you can pass the [materialOptions] parameter, which should
  /// be an instance of [MaterialOptions] class.
  ///
  /// If you would like to present the picker with pre selected
  /// photos, you can pass [selectedAssets] with List of Asset
  /// objects picked previously from the picker.
  ///
  /// This method returns list of [Asset] objects. Because
  /// they are just placeholders containing the actual
  /// identifier to the image, not the image itself you can
  /// pick thousands of images at a time, with no performance
  /// penalty. How to request the original image or a thumb
  /// you can refer to the docs for the Asset class.
  static Future<List<Asset>> pickImages({
    List<Asset> selectedAssets = const [],
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) =>
      MultiImagePickerPlatform.instance.pickImages(
        selectedAssets: selectedAssets,
        cupertinoOptions: cupertinoOptions,
        materialOptions: materialOptions,
      );

  /// Requests a thumbnail with [width], [height]
  /// and [quality] for a given [identifier].
  ///
  /// This method is used by the asset class, you
  /// should not invoke it manually. For more info
  /// refer to [Asset] class docs.
  ///
  /// The actual image data is sent via BinaryChannel.
  static Future<bool> requestThumbnail(
    String identifier,
    int width,
    int height,
    int quality,
  ) =>
      MultiImagePickerPlatform.instance
          .requestThumbnail(identifier, width, height, quality);

  /// Requests the original image data for a given
  /// [identifier].
  ///
  /// This method is used by the asset class, you
  /// should not invoke it manually. For more info
  /// refer to [Asset] class docs.
  ///
  /// The actual image data is sent via BinaryChannel.
  static Future<bool> requestOriginal(String identifier, int quality) =>
      MultiImagePickerPlatform.instance.requestOriginal(identifier, quality);

  // Requests image metadata for a given [identifier]
  static Future<Metadata> requestMetadata(String identifier) =>
      MultiImagePickerPlatform.instance.requestMetadata(identifier);
}
