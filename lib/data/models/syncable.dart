/// Common fields every synced record carries. `updatedAt` (epoch ms) decides
/// which side wins on conflict; `deleted` is a soft-delete tombstone.
abstract class Syncable {
  String get id;
  int get updatedAt;
  bool get deleted;

  Map<String, Object?> toMap();
}

bool intToBool(Object? v) => v == 1 || v == true;

int boolToInt(bool v) => v ? 1 : 0;

double? toDoubleOrNull(Object? v) => v == null ? null : (v as num).toDouble();

int nowMs() => DateTime.now().millisecondsSinceEpoch;
