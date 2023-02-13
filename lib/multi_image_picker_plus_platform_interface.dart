import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'multi_image_picker_plus.dart';
import 'multi_image_picker_plus_method_channel.dart';

abstract class MultiImagePickerPlatform extends PlatformInterface {
  /// Constructs a MultiImagePickerPlatform.
  MultiImagePickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static MultiImagePickerPlatform _instance = MethodChannelMultiImagePicker();

  /// The default instance of [MultiImagePickerPlatform] to use.
  ///
  /// Defaults to [MethodChannelMultiImagePicker].
  static MultiImagePickerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MultiImagePickerPlatform] when
  /// they register themselves.
  static set instance(MultiImagePickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<Asset>> pickImages({
    List<Asset> selectedAssets = const [],
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) {
    throw UnimplementedError('pickImages has not been implemented.');
  }

  Future<bool> requestThumbnail(
    String identifier,
    int width,
    int height,
    int quality,
  ) {
    throw UnimplementedError('requestThumbnail has not been implemented.');
  }

  Future<bool> requestOriginal(String identifier, int quality) {
    throw UnimplementedError('requestOriginal has not been implemented.');
  }

  Future<Metadata> requestMetadata(String identifier) {
    throw UnimplementedError('requestMetadata has not been implemented.');
  }
}
