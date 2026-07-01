import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Applies the sqlite3 open workaround needed on old Android versions.
Future<void> applySqlite3WorkaroundIfNeeded() =>
    applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
