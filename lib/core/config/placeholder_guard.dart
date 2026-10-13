library;

final RegExp _placeholderPattern = RegExp(
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

bool looksLikePlaceholder(String? value) {
  if (value == null) return true;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  return _placeholderPattern.hasMatch(trimmed);
}
