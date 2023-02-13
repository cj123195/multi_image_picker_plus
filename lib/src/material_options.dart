import 'dart:ui' show Color;

class MaterialOptions {
  const MaterialOptions({
    this.maxImages,
    this.enableCamera,
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
  });

  final int? maxImages;
  final bool? enableCamera;
  final Color? actionBarColor;
  final Color? statusBarColor;
  final bool? lightStatusBar;
  final Color? actionBarTitleColor;
  final String? allViewTitle;
  final String? actionBarTitle;
  final bool? startInAllView;
  final bool? useDetailsView;
  final Color? selectCircleStrokeColor;
  final String? selectionLimitReachedText;
  final String? textOnNothingSelected;
  final String? backButtonDrawable;
  final String? okButtonDrawable;
  final bool? autoCloseOnSelectionLimit;

  String _parseColor(Color? color) {
    return color == null
        ? ''
        : '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  Map<String, String> toJson() {
    return {
      "maxImages": (maxImages ?? 300).toString(),
      "enableCamera": enableCamera == true ? "true" : "false",
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
          autoCloseOnSelectionLimit == true ? "true" : "false"
    };
  }
}
