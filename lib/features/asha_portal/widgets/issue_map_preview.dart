import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../screens/village_household_map_screen.dart';
import 'issue_map.dart';

/// Live mini-map shown on the Households tab. With open cases it focuses on the
/// area with the most cases (or the latest case); otherwise on the ASHA
/// worker's district. Tapping it opens the full-screen map.
class AshaIssueMapPreview extends StatefulWidget {
  const AshaIssueMapPreview({super.key});

  @override
  State<AshaIssueMapPreview> createState() => _AshaIssueMapPreviewState();
}

class _AshaIssueMapPreviewState extends State<AshaIssueMapPreview> {
  String? _requestedDistrictKey;
  LatLng? _districtCenter;

  void _ensureDistrictCenter(({String district, String state})? district) {
    if (district == null) return;
    final key = '${district.district}|${district.state}';
    if (_requestedDistrictKey == key) return;
    _requestedDistrictKey = key;
    _districtCenter = DistrictLocator.cached(district.district, district.state);
    if (_districtCenter != null) return;
    DistrictLocator.locate(district.district, district.state).then((point) {
      if (mounted && point != null && _requestedDistrictKey == key) setState(() => _districtCenter = point);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final admin = context.watch<AdminRepository>();
    final user = context.watch<AuthService>().currentUser;
    final ashaId = resolveAshaId(user, admin);
    final pins = pinsForAsha(ashaId, repo);
    final overdue = pins.where((p) => p.stage == IssueAgeStage.overdue).length;
    _ensureDistrictCenter(ashaDistrict(ashaId, admin));
    final focus = pins.isNotEmpty ? focusPoint(pins) : (_districtCenter ?? kDefaultMapCenter);

    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => const VillageHouseholdMapScreen()));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: IssueMapView(
                // Rebuild the preview when the focus area changes.
                key: ValueKey('${focus.latitude.toStringAsFixed(4)},${focus.longitude.toStringAsFixed(4)},${pins.length}'),
                pins: pins,
                interactive: false,
                center: focus,
                zoom: pins.isEmpty ? 10 : 14,
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: open),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_rounded, color: Color(0xFF34D399), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        pins.isEmpty ? 'Live Map • no open cases' : 'Live Map • ${pins.length} open case${pins.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (overdue > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: IssueAgeStage.overdue.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$overdue overdue',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full_rounded, size: 14, color: Color(0xFF064E3B)),
                      SizedBox(width: 4),
                      Text('Tap to open full map',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
