class NoImagesSelectedException implements Exception {
  const NoImagesSelectedException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PermissionPermanentlyDeniedExeption implements Exception {
  const PermissionPermanentlyDeniedExeption(this.message);
  final String message;
  @override
  String toString() => message;
}

class AssetNotFoundException implements Exception {
  const AssetNotFoundException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AssetFailedToDownloadException implements Exception {
  const AssetFailedToDownloadException(this.message);
  final String message;
  @override
  String toString() => message;
}
