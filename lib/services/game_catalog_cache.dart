import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';

/// Regenerable downloads live in the app's private cache, never shared storage.
class GameCatalogCache {
  GameCatalogCache(this.namespace, {Future<Directory?> Function()? directory})
    : _directoryProvider = directory ?? _nativeDirectory;

  final String namespace;
  final Future<Directory?> Function() _directoryProvider;
  Future<Directory?>? _root;
  static const _channel = MethodChannel(
    'com.abrebostudio.consolegametranslator/ps5_registration',
  );

  static Future<Directory?> _nativeDirectory() async {
    try {
      final path = await _channel.invokeMethod<String>(
        'getGameCatalogCacheDirectory',
      );
      return path == null || path.isEmpty ? null : Directory(path);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<File?> _file(String name) async {
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(name) ||
        name == '.' ||
        name == '..') {
      throw ArgumentError.value(name, 'name');
    }
    final root = await (_root ??= _directoryProvider());
    if (root == null) return null;
    final key = crypto.sha256
        .convert(utf8.encode(namespace))
        .toString()
        .substring(0, 16);
    final directory = Directory('${root.path}${Platform.pathSeparator}$key');
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$name');
  }

  Future<Uint8List?> read(String name, int maxBytes, {String? sha256}) async {
    try {
      final file = await _file(name);
      if (file == null ||
          !await file.exists() ||
          await file.length() > maxBytes) {
        return null;
      }
      final bytes = await file.readAsBytes();
      if (sha256 != null && crypto.sha256.convert(bytes).toString() != sha256) {
        return null;
      }
      return bytes;
    } on FileSystemException {
      return null;
    }
  }

  /// The download badge needs file presence, not another full JSON/hash read.
  Future<bool> contains(String name, int expectedBytes) async =>
      await pathIfPresent(name, expectedBytes) != null;

  Future<String?> pathIfPresent(String name, int expectedBytes) async {
    try {
      final file = await _file(name);
      if (file == null) return null;
      final stat = await file.stat();
      return stat.type == FileSystemEntityType.file &&
              stat.size == expectedBytes
          ? file.path
          : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> write(String name, Uint8List bytes) async {
    try {
      final file = await _file(name);
      if (file == null) return;
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } on FileSystemException {
      // Storage failures must not prevent using a valid downloaded response.
    }
  }

  Future<void> remove(String name) async {
    for (final path in [name, '$name.tmp']) {
      final file = await _file(path);
      if (file == null) return;
      try {
        await file.delete();
      } on FileSystemException {
        // A missing file is already removed; real storage failures are reported.
        if (await file.exists()) rethrow;
      }
    }
  }
}
