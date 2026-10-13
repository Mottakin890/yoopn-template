import 'package:flutter_test/flutter_test.dart';
import 'package:yoopn_templates/core/config/placeholder_guard.dart';

void main() {
  group('looksLikePlaceholder', () {
    // The exact strings that ship in .env.example must be rejected, otherwise
    // a fresh clone would talk to a non-existent Supabase project.
    test('rejects the .env.example values verbatim', () {
      expect(
        looksLikePlaceholder('https://YOUR-PROJECT-REF.supabase.co'),
        isTrue,
      );
      expect(
        looksLikePlaceholder('YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY'),
        isTrue,
      );
      expect(looksLikePlaceholder('your_supabase_anon_key'), isTrue);
      expect(looksLikePlaceholder('your-project.supabase.co'), isTrue);
    });

    test('rejects null, empty and whitespace-only', () {
      expect(looksLikePlaceholder(null), isTrue);
      expect(looksLikePlaceholder(''), isTrue);
      expect(looksLikePlaceholder('   '), isTrue);
    });

    test('rejects the other common "fill me in" shapes', () {
      expect(looksLikePlaceholder('changeme'), isTrue);
      expect(looksLikePlaceholder('change-me'), isTrue);
      expect(looksLikePlaceholder('REPLACE_ME'), isTrue);
      expect(looksLikePlaceholder('xxxxxxxxxxxxxxxx'), isTrue);
      expect(looksLikePlaceholder('<project-ref>.supabase.co'), isTrue);
      expect(looksLikePlaceholder('\${SUPABASE_URL}'), isTrue);
      expect(looksLikePlaceholder('dummy-key'), isTrue);
    });

    // The guard must never reject a real value — that would break a working
    // production build, which is a far worse failure than a late error.
    // The strings below are structurally realistic but synthetic. Each sits on
    // its own `const` line with a `gitleaks:allow` marker because the scanner
    // (and CI) reads these as leaked credentials otherwise — a test fixture
    // must not weaken the guard for every other file.
    test('accepts a real Supabase publishable key', () {
      const real = 'sb_publishable_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'; // gitleaks:allow
      expect(looksLikePlaceholder(real), isFalse);
    });

    test('accepts a real project URL', () {
      const real = 'https://abcdefghij0123456789.supabase.co'; // gitleaks:allow
      expect(looksLikePlaceholder(real), isFalse);
    });

    test('accepts a real deep-link redirect', () {
      expect(
        looksLikePlaceholder('io.supabase.example://login-callback'),
        isFalse,
      );
    });

    test('accepts Google AdMob demo ids (no lookalike token inside)', () {
      expect(
        looksLikePlaceholder('ca-app-pub-3940256099942544/6300978111'),
        isFalse,
      );
    });
  });
}
