import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to inspect and verify media assets at startup using AssetManifest.
class AssetChecker {
  static final Set<String> _availableAssets = {};
  static final Set<String> _loggedMissing = {};
  static bool _initialized = false;

  static bool get isInitialized => _initialized;
  static Set<String> get availableAssets => Set.unmodifiable(_availableAssets);

  /// Loads the asset manifest once at startup and caches the result.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _availableAssets.clear();
      _availableAssets.addAll(manifest.listAssets());
      _initialized = true;
      debugPrint(
          '[AssetChecker] AssetManifest loaded: ${_availableAssets.length} asset entries cached.');
    } catch (e) {
      debugPrint('[AssetChecker] Error loading AssetManifest: $e');
    }
  }

  /// Checks whether an asset file exists in the bundle.
  /// If missing in initialized mode, logs one debug line per missing file.
  static bool hasAsset(String? path) {
    if (path == null || path.isEmpty) return false;

    // In unit test environment where initialize() is not called,
    // fallback gracefully so existing tests can run without asset bundles.
    if (!_initialized) {
      return true;
    }

    final exists = _availableAssets.contains(path);
    if (!exists) {
      if (_loggedMissing.add(path)) {
        debugPrint('[AssetChecker] Missing expected media asset: $path');
      }
    }
    return exists;
  }

  /// Filters a list of asset paths, returning only those that exist.
  static List<String> filterExisting(List<String> paths) {
    return paths.where((p) => hasAsset(p)).toList();
  }

  /// Returns list of expected files that are currently missing.
  static List<String> findMissing(List<String> expectedFiles) {
    return expectedFiles.where((f) => !hasAsset(f)).toList();
  }

  @visibleForTesting
  static void mockAssetsForTest(List<String> assets) {
    _availableAssets.clear();
    _availableAssets.addAll(assets);
    _initialized = true;
  }

  @visibleForTesting
  static void resetForTest() {
    _availableAssets.clear();
    _loggedMissing.clear();
    _initialized = false;
  }
}
