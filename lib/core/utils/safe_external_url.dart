/// Parses [url] and returns it only when it is a plain web URL.
///
/// Model-returned URLs (e.g. appraisal `sources[].url`) are untrusted
/// output: launching them unfiltered would hand `intent://`,
/// `javascript:` or `file:` URIs to the OS. Anything that is not
/// http/https yields `null` — callers simply don't launch.
Uri? safeExternalHttpUri(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}
