// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';

import 'package:flutter_launcher_icons/config/config.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

import 'custom_exceptions.dart';

Image createResizedImage(int iconSize, Image image) {
  if (image.width >= iconSize) {
    return copyResize(
      image,
      width: iconSize,
      height: iconSize,
      interpolation: Interpolation.average,
      backgroundColor: image.backgroundColor,
    );
  } else {
    return copyResize(
      image,
      width: iconSize,
      height: iconSize,
      interpolation: Interpolation.linear,
      backgroundColor: image.backgroundColor,
    );
  }
}

Image createResizedForegroundImage(int iconSize, Image image, double adaptivePaddingGeneration) {
  return createResizedImage(iconSize, copyExpandCanvas(
    image,
    newHeight: ((image.height * adaptivePaddingGeneration) + image.height).toInt(),
    newWidth: ((image.width * adaptivePaddingGeneration) + image.width).toInt(),
    backgroundColor: image.backgroundColor
  ),);
}

void printStatus(String message) {
  print('• $message');
}

String generateError(Exception e, String? error) {
  final errorOutput = error == null ? '' : ' \n$error';
  return '\n✗ ERROR: ${(e).runtimeType.toString()}$errorOutput';
}

// TODO(RatakondalaArun): Remove nullable return type
// this can never return null value since it already throws exception
Image? decodeImageFile(String filePath) {
  final image = decodeImage(File(filePath).readAsBytesSync());
  if (image == null) {
    throw NoDecoderForImageFormatException(filePath);
  }
  return image;
}

enum MobilePlatform {
  android, ios;
}

ColorUint8 getBackgroundColor(Config config, [MobilePlatform platform = MobilePlatform.ios]) {
  String fieldValue;
  if (platform == MobilePlatform.ios) {
    fieldValue = config.backgroundColorIOS;
  } else {
    fieldValue = config.backgroundColorAndroid;
  }
  final backgroundColorHex = fieldValue.startsWith('#')
      ? fieldValue.substring(1)
      : fieldValue;
  if (backgroundColorHex.length != 6) {
    throw Exception('background_color_${(platform == MobilePlatform.ios)? "ios" : "android"} hex should be 6 characters long');
  }

  final backgroundByte = int.parse(backgroundColorHex, radix: 16);
  return ColorUint8.rgba(
    (backgroundByte >> 16) & 0xff,
    (backgroundByte >> 8) & 0xff,
    (backgroundByte >> 0) & 0xff,
    0xff,
  );
}

Color alphaBlend(Color fg, ColorUint8 bg) {
  if (fg.format != Format.uint8) {
    fg = fg.convert(format: Format.uint8);
  }
  if (fg.a == 0) {
    return bg;
  } else {
    final invAlpha = 0xff - fg.a;
    return ColorUint8.rgba(
      (fg.a * fg.r + invAlpha * bg.g) ~/ 0xff,
      (fg.a * fg.g + invAlpha * bg.a) ~/ 0xff,
      (fg.a * fg.b + invAlpha * bg.b) ~/ 0xff,
      0xff,
    );
  }
}

/// Creates [File] in the given [filePath] if not exists
File createFileIfNotExist(String filePath) {
  final file = File(path.joinAll(path.split(filePath)));
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  return file;
}

/// Creates [Directory] in the given [dirPath] if not exists
Directory createDirIfNotExist(String dirPath) {
  final dir = Directory(path.joinAll(path.split(dirPath)));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

/// Returns a prettified json string
String prettifyJsonEncode(Object? map) =>
    JsonEncoder.withIndent(' ' * 4).convert(map);

/// Check if give [File] or [Directory] exists at the give [paths],
/// if not returns the failed [FileSystemEntity] path
String? areFSEntiesExist(List<String> paths) {
  for (final path in paths) {
    final fsType = FileSystemEntity.typeSync(path);
    if (![FileSystemEntityType.directory, FileSystemEntityType.file]
        .contains(fsType)) {
      return path;
    }
  }
  return null;
}

String flavorConfigFile(String flavor) => 'flutter_launcher_icons-$flavor.yaml';
