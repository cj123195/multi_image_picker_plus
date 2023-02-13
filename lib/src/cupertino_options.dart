import 'package:flutter/material.dart' show Color, Rect;

class CupertinoOptions {
  const CupertinoOptions({
    this.doneButton,
    this.cancelButton,
    this.albumButtonColor,
    this.settings,
  });

  /// Text on done button.
  final UIBarButtonItem? doneButton;

  /// Text on cancel button.
  final UIBarButtonItem? cancelButton;

  /// Color of text on album button.
  final Color? albumButtonColor;

  /// Picker settings.
  final CupertinoSettings? settings;

  Map<String, dynamic> toJson() {
    return {
      "doneButton": doneButton?.toJson(),
      "cancelButton": cancelButton?.toJson(),
      "albumButtonColor": albumButtonColor?.value,
      "settings": settings?.toJson(),
    };
  }
}

class CupertinoSettings {
  const CupertinoSettings({
    this.theme,
    this.selection,
    this.list,
    this.previewEnabled,
    this.dismiss,
    this.fetch,
  });

  /// Theme settings
  final ThemeSetting? theme;

  /// Selection settings
  final SelectionSetting? selection;

  /// List settings
  final ListSetting? list;

  /// Fetch settings
  final FetchSetting? fetch;

  /// Dismiss settings
  final DismissSetting? dismiss;

  /// Is preview enabled?
  ///
  /// Defaults to true.
  final bool? previewEnabled;

  Map<String, dynamic> toJson() {
    return {
      'theme': theme?.toJson(),
      'selection': selection?.toJson(),
      'list': list?.toJson(),
      'fetch': fetch?.toJson(),
      'dismiss': dismiss?.toJson(),
      'previewEnabled': previewEnabled ?? true,
    };
  }
}

enum SelectionStyle {
  /// Selected item will show a done icon.
  checked,

  /// Selected item will show it's index.
  numbered,
}

/// Move all theme related stuff to UIAppearance
class ThemeSetting {
  /// Create a ThemeSetting.
  const ThemeSetting({
    this.backgroundColor,
    this.selectionFillColor,
    this.selectionStrokeColor,
    this.selectionShadowColor,
    this.selectionStyle,
    this.previewTitleAttributes,
    this.previewSubtitleAttributes,
    this.albumTitleAttributes,
  });

  /// Main background color
  final Color? backgroundColor;

  /// What color to fill the circle with
  final Color? selectionFillColor;

  /// Color for the actual checkmark
  final Color? selectionStrokeColor;

  /// Shadow color for the circle
  final Color? selectionShadowColor;

  /// The icon to display inside the selection oval
  final SelectionStyle? selectionStyle;

  /// The style for the title of preview.
  final TitleAttribute? previewTitleAttributes;

  /// The style for the subtitle of preview.
  final TitleAttribute? previewSubtitleAttributes;

  /// The style for the title of album.
  final TitleAttribute? albumTitleAttributes;

  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor?.value,
      'selectionFillColor': selectionFillColor?.value,
      'selectionStrokeColor': selectionStrokeColor?.value,
      'selectionShadowColor': selectionShadowColor?.value,
      'selectionStyle': selectionStyle?.name,
      'previewTitleAttributes': previewTitleAttributes?.toJson(),
      'previewSubtitleAttributes': previewSubtitleAttributes?.toJson(),
      'albumTitleAttributes': albumTitleAttributes?.toJson(),
    };
  }
}

class UIBarButtonItem {
  const UIBarButtonItem({this.title, this.tintColor});

  /// Text to display on the button.
  final String? title;

  ///  Color of [title]
  final Color? tintColor;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'tintColor': tintColor?.value,
    };
  }
}

/// Title style
class TitleAttribute {
  /// Create a TitleAttribute.
  const TitleAttribute({this.fontSize, this.foregroundColor});

  /// Size of text of title.
  final double? fontSize;

  /// What color for the child on the title.
  final Color? foregroundColor;

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'foregroundColor': foregroundColor?.value,
    };
  }
}

/// Selection settings for the picker.
class SelectionSetting {
  /// Create a ListSetting.
  const SelectionSetting({
    this.max,
    this.min,
    this.unselectOnReachingMax,
  });

  /// Max number of selections allowed
  final int? max;

  /// Min number of selections you have to make
  final int? min;

  /// If it reaches the max limit, unselect the first selection, and allow the
  /// new selection
  final bool? unselectOnReachingMax;

  Map<String, dynamic> toJson() {
    return {
      'max': max,
      'min': min,
      'unselectOnReachingMax': unselectOnReachingMax,
    };
  }
}

/// List Settings for the picker.
class ListSetting {
  /// Create a ListSetting.
  const ListSetting({this.spacing, this.cellsPerRow});

  /// How much spacing between cells
  final double? spacing;

  /// How many cells per row
  final int? cellsPerRow;

  Map<String, dynamic> toJson() => {
        'spacing': spacing,
        'cellsPerRow': cellsPerRow,
      };
}

enum MediaTypes {
  image,
  video,
}

/// Dismiss settings for the picker.
class DismissSetting {
  /// Create a DismissSetting.
  const DismissSetting({this.enabled, this.allowSwipe});

  /// Should the image picker dismiss when done/cancelled
  ///
  /// Defaults to true.
  final bool? enabled;

  /// Allow the user to dismiss the image picker by swiping down
  ///
  /// Defaults to false.
  final bool? allowSwipe;

  Map<String, bool> toJson() => {
        'enabled': enabled ?? true,
        'allowSwipe': allowSwipe ?? false,
      };
}

class FetchSetting {
  const FetchSetting({this.album, this.assets, this.preview});

  /// Album fetch settings.
  final AlbumSetting? album;

  /// Asset fetch settings.
  final AssetsSetting? assets;

  /// Preview fetch settings,
  final PreviewSetting? preview;

  Map<String, Map<String, dynamic>?> toJson() {
    return {
      'album': album?.toJson(),
      'assets': assets?.toJson(),
      'preview': preview?.toJson(),
    };
  }
}

class AlbumSetting {
  const AlbumSetting({this.options, this.fetchResults});

  /// Fetch options for albums/collections
  final PHFetchOptions? options;

  /// Fetch results for asset collections you want to present to the user.
  final Set<PHFetchResult>? fetchResults;

  Map<String, dynamic> toJson() {
    return {
      'options': options?.toJson(),
      'fetchResults': fetchResults?.map((e) => e.toJson()).toList(),
    };
  }
}

/// Fetch options for assets
class AssetsSetting {
  const AssetsSetting({this.options, this.supportedMediaTypes});

  final PHFetchOptions? options;

  /// Simple wrapper around PHAssetMediaType to ensure we only expose the
  /// supported types.
  final Set<MediaTypes>? supportedMediaTypes;

  Map<String, dynamic> toJson() {
    return {
      'options': options?.toJson(),
      'supportedMediaTypes': supportedMediaTypes?.map((e) => e.name).toList(),
    };
  }
}

class PreviewSetting {
  const PreviewSetting({
    this.photoOptions,
    this.livePhotoOptions,
    this.videoOptions,
  });

  final PHImageRequestOptions? photoOptions;
  final PHLivePhotoRequestOptions? livePhotoOptions;
  final PHVideoRequestOptions? videoOptions;

  Map<String, Map<String, dynamic>?> toJson() {
    return {
      'photoOptions': photoOptions?.toJson(),
      'livePhotoOptions': livePhotoOptions?.toJson(),
      'videoRequestOptions': videoOptions?.toJson(),
    };
  }
}

class PHFetchOptions {
  const PHFetchOptions({
    this.predicate,
    this.sortDescriptors,
    this.includeHiddenAssets,
    this.includeAllBurstAssets,
    this.includeAssetSourceTypes,
    this.fetchLimit,
    this.wantsIncrementalChangeDetails,
  });

  /// Some predicates / sorts may be suboptimal and we will log
  final NSPredicate? predicate;

  final List<NSSortDescriptor>? sortDescriptors;

  /// Whether hidden assets are included in fetch results.
  ///
  /// Defaults to false
  final bool? includeHiddenAssets;

  /// Whether hidden burst assets are included in fetch results.
  ///
  /// Defaults to false
  final bool? includeAllBurstAssets;

  /// The asset source types included in the fetch results.
  ///
  /// If set to PHAssetSourceTypeNone the asset source types included in the
  /// fetch results are inferred from the type of query performed.
  ///
  /// Defaults to PHAssetSourceTypeNone.
  final Set<PHAssetSourceType>? includeAssetSourceTypes;

  /// Limits the maximum number of objects returned in the fetch result,
  /// a value of 0 means no limit.
  ///
  /// Defaults to 0.
  final int? fetchLimit;

  /// Whether the owner of this object is interested in incremental change
  /// details for the results of this fetch (see PHChange)
  ///
  /// Defaults to true
  final bool? wantsIncrementalChangeDetails;

  Map<String, dynamic> toJson() {
    return {
      "predicate": predicate?.toJson(),
      'sortDescriptors': sortDescriptors?..map((e) => e.toJson()).toList(),
      'includeHiddenAssets': includeHiddenAssets,
      'includeAllBurstAssets': includeAllBurstAssets,
      'includeAssetSourceTypes':
          includeAssetSourceTypes?.map((e) => e.index).toList(),
      'fetchLimit': fetchLimit,
      'wantsIncrementalChangeDetails': wantsIncrementalChangeDetails,
    };
  }
}

class NSPredicate {
  const NSPredicate({required this.format, required this.arguments});

  final String format;
  final List<dynamic> arguments;

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'arguments': arguments,
    };
  }
}

class NSSortDescriptor {
  const NSSortDescriptor({required this.ascending, this.key});

  final String? key;
  final bool ascending;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'ascending': ascending,
    };
  }
}

/// Fetch asset collections of a single type and subtype provided
/// (use PHAssetCollectionSubtypeAny to match all subtypes)
class PHFetchResult {
  const PHFetchResult({
    required this.type,
    required this.subtype,
    this.options,
  });

  final PHAssetCollectionType type;
  final PHAssetCollectionSubtype subtype;
  final PHFetchOptions? options;

  Map<String, dynamic> toJson() {
    return {
      'type': type.code,
      'subtype': subtype.code,
      'options': options?.toJson(),
    };
  }
}

class PHImageRequestOptions {
  const PHImageRequestOptions({
    this.version,
    this.deliveryMode,
    this.resizeMode,
    this.normalizedCropRect,
    this.isNetworkAccessAllowed,
    this.isSynchronous,
  });

  /// version
  final PHImageRequestOptionsVersion? version;

  /// delivery mode.
  /// Defaults to [PHImageRequestOptionsDeliveryMode.opportunistic]
  final PHImageRequestOptionsDeliveryMode? deliveryMode;

  /// resize mode. Does not apply when size is PHImageManagerMaximumSize.
  ///
  /// Defaults to [PHImageRequestOptionsResizeMode.fast]
  final PHImageRequestOptionsResizeMode? resizeMode;

  /// specify crop rectangle in unit coordinates of the original image, such as
  /// a face.
  ///
  /// Defaults to CGRectZero (not applicable)
  final Rect? normalizedCropRect;

  /// if necessary will download the image from iCloud (client can monitor or
  /// cancel using progressHandler).
  ///
  /// Defaults to true (see start/stopCachingImagesForAssets)
  final bool? isNetworkAccessAllowed;

  /// return only a single result, blocking until available (or failure).
  ///
  /// Defaults to false
  final bool? isSynchronous;

  Map<String, dynamic> toJson() {
    return {
      'version': version?.index,
      'deliveryMode': deliveryMode?.index,
      'resizeMode': resizeMode?.index,
      'normalizedCropRect': normalizedCropRect == null
          ? null
          : <String, double>{
              'x': normalizedCropRect!.left,
              'y': normalizedCropRect!.top,
              'width': normalizedCropRect!.width,
              'height': normalizedCropRect!.height,
            },
      'isNetworkAccessAllowed': isNetworkAccessAllowed,
      'isSynchronous': isSynchronous,
    };
  }
}

class PHLivePhotoRequestOptions {
  const PHLivePhotoRequestOptions({
    this.version,
    this.deliveryMode,
    this.isNetworkAccessAllowed,
  });

  final PHImageRequestOptionsVersion? version;
  final PHImageRequestOptionsDeliveryMode? deliveryMode;
  final bool? isNetworkAccessAllowed;

  Map<String, dynamic> toJson() {
    return {
      'version': version?.index,
      'deliveryMode': deliveryMode?.index,
      'isNetworkAccessAllowed': isNetworkAccessAllowed,
    };
  }
}

class PHVideoRequestOptions {
  const PHVideoRequestOptions({
    this.version,
    this.deliveryMode,
    this.isNetworkAccessAllowed,
  });

  final PHVideoRequestOptionsVersion? version;
  final PHVideoRequestOptionsDeliveryMode? deliveryMode;
  final bool? isNetworkAccessAllowed;

  Map<String, dynamic> toJson() {
    return {
      'version': version?.index,
      'deliveryMode': deliveryMode?.index,
      'isNetworkAccessAllowed': isNetworkAccessAllowed,
    };
  }
}

enum PHAssetCollectionType {
  album(1),
  smartAlbum(2);

  const PHAssetCollectionType(this.code);

  final int code;
}

enum PHAssetCollectionSubtype {
  /// PHAssetCollectionTypeAlbum regular subtypes
  albumRegular(2),
  albumSyncedEvent(3),
  albumSyncedFaces(4),
  albumSyncedAlbum(5),
  albumImported(6),

  /// PHAssetCollectionTypeAlbum shared subtypes
  albumMyPhotoStream(100),
  albumCloudShared(101),

  /// PHAssetCollectionTypeSmartAlbum subtypes
  smartAlbumGeneric(200),
  smartAlbumPanoramas(201),
  smartAlbumVideos(202),
  smartAlbumFavorites(203),
  smartAlbumTimelapses(204),
  smartAlbumAllHidden(205),
  smartAlbumRecentlyAdded(206),
  smartAlbumBursts(207),
  smartAlbumSlomoVideos(208),
  smartAlbumUserLibrary(209),
  smartAlbumSelfPortraits(210),
  smartAlbumScreenshots(211),
  smartAlbumDepthEffect(212),
  smartAlbumLivePhotos(213),
  smartAlbumAnimated(214),
  smartAlbumLongExposures(215),
  smartAlbumUnableToUpload(216),
  smartAlbumRAW(217),

  /// Used for fetching, if you don't care about the exact subtype
  any(9223372036854775807);

  const PHAssetCollectionSubtype(this.code);

  final int code;
}

enum PHAssetSourceType {
  typeUserLibrary,
  typeCloudShared,
  typeiTunesSynced,
}

enum PHImageRequestOptionsVersion {
  /// version with edits (aka adjustments) rendered or unadjusted version if
  /// there is no edits.
  current,

  /// original version without any adjustments.
  unadjusted,

  /// original version, in the case of a combined format the highest fidelity
  /// format will be returned (e.g. RAW for a RAW+JPG source image)
  original,
}

enum PHImageRequestOptionsDeliveryMode {
  /// client may get several image results when the call is asynchronous or
  /// will get one result when the call is.
  opportunistic,

  /// client will get one result only and it will be as asked or better than
  /// asked.
  highQualityFormat,

  /// client will get one result only and it may be degraded.
  fastFormat;
}

enum PHImageRequestOptionsResizeMode {
  /// no resize
  none,

  /// use targetSize as a hint for optimal decoding when the source image is a
  /// compressed format (i.e. subsampling), the delivered image may be larger
  /// than targetSize
  fast,

  /// same as above but also guarantees the delivered image is exactly
  /// targetSize (must be set when a normalizedCropRect is specified)
  exact;
}

enum PHVideoRequestOptionsVersion {
  /// version with edits (aka adjustments) rendered or unadjusted version if
  /// there is no edits.
  current,

  /// original version.
  original,
}

enum PHVideoRequestOptionsDeliveryMode {
  /// only apply with [PHVideoRequestOptionsVersion.current].
  ///
  /// let us pick the quality (typ.
  /// [PHVideoRequestOptionsDeliveryMode.mediumQualityFormat] for streamed
  /// AVPlayerItem or AVAsset, or
  /// [PHVideoRequestOptionsDeliveryMode.highQualityFormat] for
  /// AVAssetExportSession)
  automatic,

  /// best quality
  highQualityFormat,

  /// medium quality (typ. 720p), currently only supported for AVPlayerItem or
  /// AVAsset when streaming from iCloud (will systematically default to
  /// [PHVideoRequestOptionsDeliveryMode.highQualityFormat] if locally
  /// available)
  mediumQualityFormat,

  /// fastest available (typ. 360p MP4), currently only supported for
  /// AVPlayerItem or AVAsset when streaming from iCloud (will systematically
  /// default to [PHVideoRequestOptionsDeliveryMode.highQualityFormat] if
  /// locally available)
  fastFormat,
}
