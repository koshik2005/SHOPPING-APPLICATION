abstract class OfflineCacheManager {
  Future<void> cacheTile(String key, List<int> tileBytes);
  Future<List<int>?> getCachedTile(String key);
  Future<void> cacheAddress(String query, String address);
  Future<String?> getCachedAddress(String query);
  Future<void> cacheRoute(String key, String routeJson);
  Future<String?> getCachedRoute(String key);
  Future<void> cleanExpiredCache();
  Future<void> clearAll();
}
