import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MultiImagePicker', () {
    const MethodChannel channel = MethodChannel('multi_image_picker');

    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestOriginal' ||
            methodCall.method == 'requestThumbnail') {
          return true;
        }
        return [
          {'identifier': 'SOME_ID_1'},
          {'identifier': 'SOME_ID_2'}
        ];
      });

      log.clear();
    });

    group('#pickImages', () {
      test('passes max images argument correctly', () async {
        await MultiImagePicker.pickImages();

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImages', arguments: <String, dynamic>{
              'maxImages': 5,
              'enableCamera': false,
              'iosOptions': const CupertinoOptions().toJson(),
              'androidOptions': const MaterialOptions().toJson(),
              'selectedAssets': [],
            }),
          ],
        );
      });

      test('passes selected assets correctly', () async {
        final Asset asset = Asset("test", "test.jpg", 100, 100);
        await MultiImagePicker.pickImages(
          selectedAssets: [asset],
        );

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImages', arguments: <String, dynamic>{
              'maxImages': 5,
              'enableCamera': false,
              'iosOptions': const CupertinoOptions().toJson(),
              'androidOptions': const MaterialOptions().toJson(),
              'selectedAssets': [asset.identifier],
            }),
          ],
        );
      });

      test('passes cuppertino options argument correctly', () async {
        const CupertinoOptions cupertinoOptions = CupertinoOptions(
          settings: CupertinoSettings(
            theme: ThemeSetting(
              backgroundColor: Colors.blue,
              selectionFillColor: Colors.blue,
              selectionShadowColor: Colors.blue,
              selectionStrokeColor: Colors.white,
            ),
          ),
        );

        await MultiImagePicker.pickImages(cupertinoOptions: cupertinoOptions);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImages', arguments: <String, dynamic>{
              'maxImages': 5,
              'enableCamera': false,
              'iosOptions': cupertinoOptions.toJson(),
              'androidOptions': const MaterialOptions().toJson(),
              'selectedAssets': [],
            }),
          ],
        );
      });

      test('passes meterial options argument correctly', () async {
        const MaterialOptions materialOptions = MaterialOptions(
          actionBarTitle: "Aciton bar",
          allViewTitle: "All view title",
          actionBarColor: Colors.black,
          actionBarTitleColor: Colors.white,
          lightStatusBar: false,
          statusBarColor: Colors.red,
          startInAllView: true,
          useDetailsView: true,
          selectCircleStrokeColor: Colors.green,
        );
        await MultiImagePicker.pickImages(materialOptions: materialOptions);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImages', arguments: <String, dynamic>{
              'maxImages': 5,
              'enableCamera': false,
              'androidOptions': materialOptions.toJson(),
              'iosOptions': const CupertinoOptions().toJson(),
              'selectedAssets': [],
            }),
          ],
        );
      });

      test('does not accept a negative images count', () {
        expect(
          MultiImagePicker.pickImages(),
          throwsArgumentError,
        );
      });
    });

    test('requestOriginal accepts correct params', () async {
      const String id = 'SOME_ID';
      const int quality = 100;
      await MultiImagePicker.requestOriginal(id, quality);

      expect(
        log,
        <Matcher>[
          isMethodCall('requestOriginal', arguments: <String, dynamic>{
            'identifier': id,
            'quality': quality,
          }),
        ],
      );
    });

    group('#requestThumbnail', () {
      const String id = 'SOME_ID';
      const int width = 100;
      const int height = 200;
      const int quality = 100;
      test('accepts correct params', () async {
        await MultiImagePicker.requestThumbnail(id, width, height, quality);

        expect(
          log,
          <Matcher>[
            isMethodCall('requestThumbnail', arguments: <String, dynamic>{
              'identifier': id,
              'width': width,
              'height': height,
              'quality': quality,
            }),
          ],
        );
      });

      test('does not accept a negative width or height', () {
        expect(
          MultiImagePicker.requestThumbnail(id, -100, height, quality),
          throwsArgumentError,
        );

        expect(
          MultiImagePicker.requestThumbnail(id, width, -100, quality),
          throwsArgumentError,
        );
      });
      test('does not accept invalid quality', () {
        expect(
          MultiImagePicker.requestThumbnail(id, -width, height, -100),
          throwsArgumentError,
        );

        expect(
          MultiImagePicker.requestThumbnail(id, width, height, 200),
          throwsArgumentError,
        );
      });
    });
  });
}
