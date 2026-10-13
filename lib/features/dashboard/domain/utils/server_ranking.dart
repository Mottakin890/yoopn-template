import '../entities/vpn_server.dart';

int compareServersByQuality(VpnServer a, VpnServer b) {
  final score = b.score.compareTo(a.score);
  if (score != 0) return score;
  final ap = a.ping < 0 ? 1 << 30 : a.ping;
  final bp = b.ping < 0 ? 1 << 30 : b.ping;
  return ap.compareTo(bp);
}

bool serverMatchesQuery(VpnServer s, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return s.name.toLowerCase().contains(q) ||
      s.hostName.toLowerCase().contains(q) ||
      s.ip.contains(q) ||
      s.countryShort.toLowerCase().contains(q) ||
      s.countryLong.toLowerCase().contains(q);
}
