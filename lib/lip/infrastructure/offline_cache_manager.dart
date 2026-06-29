import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/cache_manager.dart';

class OfflineCacheManagerImpl implements OfflineCacheManager {
  Directory? _cacheDir;
  final Map<String, DateTime> _accessTimes = {};

  OfflineCacheManagerImpl();

  Future<Directory> _getDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    _cacheDir = Directory('${base.path}/lip_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  @override
  Future<void> cacheTile(String key, List<int> tileBytes) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/tile_${_sanitizeKey(key)}.png');
      await file.writeAsBytes(tileBytes);
      _accessTimes[key] = DateTime.now();
      await cleanExpiredCache();
    } catch (_) {}
  }

  @override
  Future<List<int>?> getCachedTile(String key) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/tile_${_sanitizeKey(key)}.png');
      if (await file.exists()) {
        _accessTimes[key] = DateTime.now();
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> cacheAddress(String query, String address) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/addr_${_sanitizeKey(query)}.txt');
      await file.writeAsString(address);
    } catch (_) {}
  }

  @override
  Future<String?> getCachedAddress(String query) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/addr_${_sanitizeKey(query)}.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> cacheRoute(String key, String routeJson) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/route_${_sanitizeKey(key)}.json');
      await file.writeAsString(routeJson);
    } catch (_) {}
  }

  @override
  Future<String?> getCachedRoute(String key) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/route_${_sanitizeKey(key)}.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> cleanExpiredCache() async {
    try {
      final dir = await _getDir();
      final files = dir.listSync();
      if (files.length > 500) {
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        for (var i = 0; i < 100 && i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    try {
      final dir = await _getDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _cacheDir = null;
    } catch (_) {}
  }
}
