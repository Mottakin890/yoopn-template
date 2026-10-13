import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yoopn_templates/core/errors/vpn_failures.dart';

void main() {
  group('VpnException', () {
    test('carries a typed code', () {
      const e = VpnException(VpnFailureCode.permissionDenied);
      expect(e.code, VpnFailureCode.permissionDenied);
      expect(resolveVpnFailureCode(e), VpnFailureCode.permissionDenied);
    });

    test('falls back to the canonical message of the code', () {
      const e = VpnException(VpnFailureCode.cancelled);
      expect(e.message, VpnFailureCode.cancelled.message);
      expect(e.message, 'Connection cancelled.');
    });

    test(
      'a detail overrides the canonical message without losing the code',
      () {
        const e = VpnException(
          VpnFailureCode.connectFailed,
          detail: 'VPN dropped during connect (add_routes).',
        );
        expect(e.message, 'VPN dropped during connect (add_routes).');
        expect(e.code, VpnFailureCode.connectFailed);
      },
    );

    test('retains the original cause for diagnostics', () {
      final cause = StateError('boom');
      final e = VpnException(VpnFailureCode.connectFailed, cause: cause);
      expect(e.cause, same(cause));
    });

    test('toString names the code, never leaks a stack or a raw message', () {
      const e = VpnException(VpnFailureCode.badConfig, detail: 'secret detail');
      expect(e.toString(), 'VpnException(badConfig)');
      expect(e.toString(), isNot(contains('secret detail')));
    });
  });

  group('resolveVpnFailureCode', () {
    test('passes a VpnException code through unchanged', () {
      for (final code in VpnFailureCode.values) {
        expect(resolveVpnFailureCode(VpnException(code)), code);
      }
    });

    test('every code resolves to itself, never collapsing to unknown', () {
      for (final code in VpnFailureCode.values) {
        if (code == VpnFailureCode.unknown) continue;
        expect(
          resolveVpnFailureCode(VpnException(code)),
          isNot(VpnFailureCode.unknown),
          reason: '${code.name} must not degrade to unknown',
        );
      }
    });

    test('maps TimeoutException to timeout', () {
      expect(
        resolveVpnFailureCode(TimeoutException('slow')),
        VpnFailureCode.timeout,
      );
    });

    test('maps a malformed payload to a cache/read failure, not unknown', () {
      expect(
        resolveVpnFailureCode(const FormatException('bad csv')),
        VpnFailureCode.cacheRead,
      );
    });

    test('maps a transport exception to network', () {
      expect(
        resolveVpnFailureCode(const SocketException('failed host lookup')),
        VpnFailureCode.network,
      );
      expect(
        resolveVpnFailureCode(const HandshakeException('bad cert')),
        VpnFailureCode.network,
      );
      expect(
        resolveVpnFailureCode(const HttpException('closed')),
        VpnFailureCode.network,
      );
    });

    test('maps an unrelated exception to unknown', () {
      expect(resolveVpnFailureCode(StateError('nope')), VpnFailureCode.unknown);
    });
  });

  group('vpnFailureMessage', () {
    test('every code yields a non-empty, distinct-enough user message', () {
      for (final code in VpnFailureCode.values) {
        expect(code.message, isNotEmpty, reason: '${code.name} has no copy');
      }
    });

    test('uses the exception detail when present', () {
      expect(
        vpnFailureMessage(
          const VpnException(
            VpnFailureCode.timeout,
            detail: 'Stuck at "assign_ip"',
          ),
        ),
        'Stuck at "assign_ip"',
      );
    });

    test('falls back to the code message for a foreign exception', () {
      expect(
        vpnFailureMessage(TimeoutException('slow')),
        VpnFailureCode.timeout.message,
      );
    });
  });

  group('mapVpnException', () {
    test('normalises a foreign error into a typed exception', () {
      final mapped = mapVpnException(TimeoutException('slow'), source: 'test');
      expect(mapped, isA<VpnException>());
      expect(mapped.code, VpnFailureCode.timeout);
      expect(mapped.message, VpnFailureCode.timeout.message);
    });

    test('preserves an existing code instead of re-wrapping it as unknown', () {
      final mapped = mapVpnException(
        const VpnException(VpnFailureCode.busy),
        source: 'test',
      );
      expect(mapped.code, VpnFailureCode.busy);
    });

    test('keeps the original error as the cause', () {
      final cause = StateError('boom');
      expect(mapVpnException(cause, source: 'test').cause, same(cause));
    });
  });
}
