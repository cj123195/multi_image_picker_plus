# multi_image_picker_plus

Flutter plugin that allows you to display multi image picker on iOS and Android.

Thanks to [Sh1d0w](https://github.com/Sh1d0w/), this plugin was first created by him, but he stopped updating it a long time ago, and now [pub.dev](https://pub.dev/) can't find this plugin, but I think it is very useful for me, so I upgraded it to the latest version and re-issued it. For previously used multi_ image_ For the developers of picker, the use of Android is not much different from that before, but many configurations have been modified on IOS. These configurations can be found in the [BSImagePicker](https://github.com/mikaoj/BSImagePicker) document.

## Key Features

- Pick multiple images
- Native performance
- Photos sorted by albums
- Take a picture option in the grid view
- Restrict the maximum count of images the user can pick
- Customizable UI and localizations
- Thumbnail support
- Specify the image quality of the original image or thumbnails
- Read image meta data

## Screenshot
Pick image

<img src="https://github.com/cj123195/screenshot/blob/main/image_ios.gif" width="350">

Pick video

<img src="https://github.com/cj123195/screenshot/blob/main/video_ios.gif" width="350">

## **Installation**

### IOS

Add the following keys to your *Info.plist* file, located in `<project root>/ios/Runner/Info.plist`:

- `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called *Privacy - Photo Library Usage Description* in the visual editor.
    - This permission is not required for image picking on iOS 11+ if you pass `false` for `requestFullMetadata`.

### Android

Add the following permissions to your `AndroidManifest.xml`, located in `<project root>/android/app/src/main/AndroidManifest.xml`

```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

## Usage

```dart
resultList = await MultiImagePicker.pickImages(
  selectedAssets: images,
  cupertinoOptions: CupertinoOptions(
    doneButton: UIBarButtonItem(title: 'Confirm', tintColor: colorScheme.primary),
    cancelButton: UIBarButtonItem(title: 'Cancel', tintColor: colorScheme.primary),
    albumButtonColor: Theme.of(context).colorScheme.primary,
  ),
  materialOptions: const MaterialOptions(
		maxImages: 300,
	  enableCamera: true,
    actionBarColor: "#abcdef",
    actionBarTitle: "Example App",
    allViewTitle: "All Photos",
    useDetailsView: false,
    selectCircleStrokeColor: "#000000",
  ),
);
```

## Credits

This software uses the following open source packages:

- [BSImagePicker](https://github.com/mikaoj/BSImagePicker) - iOS
- [FishBun](https://github.com/sangcomz/FishBun) - Android

## Related

[image_picker](https://pub.dartlang.org/packages/image_picker) - Official Flutter image picker plugin`

## Contribution

Users are encouraged to become active participants in its continued development — by fixing any bugs that they encounter, or by improving the documentation wherever it’s found to be lacking.

If you wish to make a change, [open a Pull Request](https://github.com/mikaoj/BSImagePicker/pull/new) — even if it just contains a draft of the changes you’re planning, or a test that reproduces an issue — and we can discuss it further from there.

## License

MIT

---

> GitHub @cj123195  ·
>
