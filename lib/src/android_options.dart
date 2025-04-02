import 'dart:ui' show Color;

enum MimeType {
  GIF("image/gif"),
  PNG("image/png"),
  JPEG("image/jpeg"),
  BMP("image/bmp"),
  WEBP("image/webp");

  const MimeType(this.type);

  final String type;
}

class AndroidOptions {
  const AndroidOptions({
    this.maxImages,
    this.hasCameraInPickerPage,
    this.actionBarColor,
    this.actionBarTitle,
    this.lightStatusBar,
    this.statusBarColor,
    this.actionBarTitleColor,
    this.allViewTitle,
    this.startInAllView,
    this.useDetailsView,
    this.selectCircleStrokeColor,
    this.selectionLimitReachedText,
    this.textOnNothingSelected,
    this.backButtonDrawable,
    this.okButtonDrawable,
    this.autoCloseOnSelectionLimit,
    this.exceptMimeType,
  });

  /// Maximum number of selectable images.
  ///
  /// Defaults to 300.
  final int? maxImages;

  /// Is the camera displayed on the selection page.
  ///
  /// Defaults to false.
  final bool? hasCameraInPickerPage;

  /// The Background color of action bar.
  final Color? actionBarColor;

  /// The Color of status bar.
  final Color? statusBarColor;

  /// Is the status bar light mode.
  final bool? lightStatusBar;

  /// The color of the title text.
  final Color? actionBarTitleColor;

  /// Title text for 'all' view.
  final String? allViewTitle;

  /// Title text for action bar.
  final String? actionBarTitle;

  /// Whether start in 'all' view.
  final bool? startInAllView;

  /// Whether can view image detail.
  final bool? useDetailsView;

  /// The color of selected circle.
  final Color? selectCircleStrokeColor;

  /// Prompt text for reaching the selection limit.
  final String? selectionLimitReachedText;

  /// Text without any selected images.
  final String? textOnNothingSelected;

  /// Back button image resources.
  final String? backButtonDrawable;

  /// Ok button image resources.
  final String? okButtonDrawable;

  /// Whether automatically close after reaching the selection limit.
  final bool? autoCloseOnSelectionLimit;

  /// Filtered mime type
  final Set<MimeType>? exceptMimeType;

  String _parseColor(Color? color) {
    return color == null
        ? ''
        // ignore: deprecated_member_use
        : '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  Map<String, String> toJson() {
    return {
      "maxImages": (maxImages ?? 300).toString(),
      "hasCameraInPickerPage": hasCameraInPickerPage == true ? "true" : "false",
      "actionBarColor": _parseColor(actionBarColor),
      "actionBarTitle": actionBarTitle ?? "",
      "actionBarTitleColor": _parseColor(actionBarTitleColor),
      "allViewTitle": allViewTitle ?? "",
      "lightStatusBar": lightStatusBar == true ? "true" : "false",
      "statusBarColor": _parseColor(statusBarColor),
      "startInAllView": startInAllView == true ? "true" : "false",
      "useDetailsView": useDetailsView == true ? "true" : "false",
      "selectCircleStrokeColor": _parseColor(selectCircleStrokeColor),
      "selectionLimitReachedText": selectionLimitReachedText ?? "",
      "textOnNothingSelected": textOnNothingSelected ?? "",
      "backButtonDrawable": backButtonDrawable ?? "",
      "okButtonDrawable": okButtonDrawable ?? "",
      "autoCloseOnSelectionLimit":
          autoCloseOnSelectionLimit == true ? "true" : "false",
      "exceptMimeType":
          exceptMimeType?.map((e) => e.type).toList().join(',') ?? '',
    };
  }
}
