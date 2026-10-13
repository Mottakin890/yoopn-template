import 'dart:async';

import 'package:yoopn_templates/core/utils/app_logger.dart';

enum VpnFailureCode {
  network('No connection. Showing saved servers.'),
  timeout('This relay is too slow. Try another server.'),
  cancelled('Connection cancelled.'),
  permissionDenied(
    'VPN permission denied. Allow the VPN request and try again.',
  ),
  unsupported('Real VPN is only available on Android/iOS.'),
  authRejected('This relay rejected the login. Try another server.'),
  badConfig('This server has no usable VPN config. Pick a live relay.'),
  busy('A connection attempt is already running. Please wait.'),
  connectFailed('Could not connect. Try another server.'),
  engineInitFailed('Could not start the VPN engine.'),
  unreachable('VPNGate is unreachable. Tap Retry.'),
  cacheRead('Could not load saved servers.'),
  cacheWrite('Could not save servers offline.'),
  serverUnavailable('Selected VPN server is unavailable. Refresh the list.'),
  unknown('Something went wrong. Please try again.');

  const VpnFailureCode(this.message);

  final String message;
}

class VpnException implements Exception {
  const VpnException(this.code, {this.cause, this.detail});

  final VpnFailureCode code;
  final Object? cause;

  final String? detail;

  String get message => detail ?? code.message;

  @override
  String toString() => 'VpnException(${code.name})';
}

const Set<String> _transportTypeNames = {
  'SocketException',
  'HttpException',
  'HandshakeException',
  'TlsException',
  'ConnectionResetException',
  'ProtocolException',
  'CertException',
};

VpnFailureCode resolveVpnFailureCode(Object error) {
  if (error is VpnException) return error.code;
  if (error is TimeoutException) return VpnFailureCode.timeout;
  if (error is FormatException) return VpnFailureCode.cacheRead;
  if (_transportTypeNames.contains(error.runtimeType.toString())) {
    return VpnFailureCode.network;
  }
  return VpnFailureCode.unknown;
}

String vpnFailureMessage(Object error) => error is VpnException
    ? error.message
    : resolveVpnFailureCode(error).message;

VpnException mapVpnException(Object error, {required String source}) {
  final code = resolveVpnFailureCode(error);
  AppLogger.w('VPN', '$source mapped ${error.runtimeType} → ${code.name}');
  return VpnException(code, cause: error);
}
