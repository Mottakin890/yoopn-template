/// Detection of *unfilled* configuration values.
///
/// `.env.example` and `docs/` legitimately contain strings shaped like
/// credentials (`YOUR_SUPABASE_ANON_KEY`, `https://YOUR-PROJECT-REF…`). If
/// those are passed through as if they were real, the app fails much later
/// with a DNS failure or an opaque `401` from a non-existent Supabase
/// project. This check converts that into an immediate, named error at the
/// point of use.
///
/// Kept separate from [SupabaseConfig] so it is a pure function and can be
/// unit-tested without touching `dotenv` or `String.fromEnvironment`.
library;

final RegExp _placeholderPattern = RegExp(
  // YOUR_SUPABASE_KEY, your-project, changeme, REPLACE_ME, xxxxxxxxxxxx,
  // <project-ref>, ${VAR} — the shapes people actually leave behind.
  r'YOUR_[A-Z0-9_]+'
  r'|your[-_][a-z0-9_-]+'
  r'|change[-_]?me'
  r'|replace[-_]?me'
  r'|x{8,}'
  r'|<[^>]*project[^>]*>'
  r'|\$\{[^}]+\}'
  r'|\bdummy\b',
  caseSensitive: false,
);

/// Whether [value] is empty or looks like a documented placeholder rather
/// than a real credential.
///
/// Real values must be allowed through: a genuine Supabase publishable key
/// (`sb_publishable_…`), a JWT, or a real `https://<ref>.supabase.co` URL all
/// match none of the patterns above.
bool looksLikePlaceholder(String? value) {
  if (value == null) return true;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  return _placeholderPattern.hasMatch(trimmed);
}
