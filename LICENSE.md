# Licence

## GPL-3.0-or-later

This template is distributed under the **GNU General Public License, version 3
or (at your option) any later version**.

The full, authoritative licence text is published by the Free Software
Foundation and is not reproduced inline here:

> https://www.gnu.org/licenses/gpl-3.0.txt
> (`curl -fsSL https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE.gpl-3.0.txt`)

Drop the downloaded `LICENSE.gpl-3.0.txt` next to this file before you
distribute anything derived from this template.

## Why GPL

This is not a choice made in the abstract — it is forced by the dependency
chain:

| Package | Licence | Reached via |
|---|---|---|
| `openvpn_flutter` | GPL-3.0 | direct dependency |
| `ics-openvpn` | GPL-3.0 | native `.so` shipped by `openvpn_flutter` |
| `OpenVPNAdapter` | GPL-3.0 | iOS pod used by the Network Extension target |

Because the OpenVPN implementation is linked into the shipped binary, any
distributed derivative must itself be GPL-3.0, and the corresponding source
must be made available under the same terms.

There is no permissive drop-in: the alternative Flutter OpenVPN packages
(`axevpn_flutter`, `flutter_vpn_connection`) are GPL too. If a permissive
licence is a hard requirement, the tunnel layer is the part that has to be
replaced — `lib/features/dashboard/data/tunnel/` isolates it behind the
`VpnTunnel` interface, and `SimulatedVpnTunnel` is already a working
implementation to start from.

## Trademarks / attribution

"YooPN" and the organisation name behind it are not covered by the licence.
VPNGate is a third-party public relay service; the relays themselves are
volunteer-run and are not distributed as part of this software.
`assets/servers_snapshot.json` is a cached, generated listing of public
relay endpoints and is refreshed by `tool/fetch_snapshot.dart`.