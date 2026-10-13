/// Backend the app syncs with. Rows use the same column names as the local
/// tables. Plug in a Firebase/REST implementation to enable cloud sync.
abstract class RemoteStore {
  Future<void> push(String collection, List<Map<String, Object?>> rows);

  Future<List<Map<String, Object?>>> pullSince(String collection, int sinceMs);
}
