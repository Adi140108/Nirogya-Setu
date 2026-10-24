import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/issue_model.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/services/health_repository.dart';

/// Pin colour stages by time elapsed since the issue was raised (while unattended).
enum IssueAgeStage { fresh, aging, overdue }

extension IssueAgeStageX on IssueAgeStage {
  Color get color {
    switch (this) {
      case IssueAgeStage.fresh:
        return const Color(0xFF16A34A);
      case IssueAgeStage.aging:
        return const Color(0xFFEAB308);
      case IssueAgeStage.overdue:
        return const Color(0xFFDC2626);
    }
  }

  String get label {
    switch (this) {
      case IssueAgeStage.fresh:
        return 'Under 36 hrs';
      case IssueAgeStage.aging:
        return '36 – 72 hrs';
      case IssueAgeStage.overdue:
        return 'Over 72 hrs';
    }
  }
}

IssueAgeStage stageFor(IssueModel issue, [DateTime? now]) {
  final hours = (now ?? DateTime.now()).difference(issue.createdAt).inMinutes / 60;
  if (hours < 36) return IssueAgeStage.fresh;
  if (hours < 72) return IssueAgeStage.aging;
  return IssueAgeStage.overdue;
}

String elapsedLabel(DateTime from) {
  final d = DateTime.now().difference(from);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 48) return '${d.inHours} hrs ago';
  return '${d.inDays} days ago';
}

class IssuePin {
  final IssueModel issue;
  final PatientModel? patient;
  final LatLng point;
  final IssueAgeStage stage;

  IssuePin({required this.issue, required this.patient, required this.point, required this.stage});
}

/// Default view (Varanasi district) when there are no pins to focus on.
const LatLng kDefaultMapCenter = LatLng(25.3176, 82.9739);
/// Esri World Street Map: free, no API key, served from a fast CDN with good
/// village-level detail for India. Falls back to OpenStreetMap for any tile
/// that fails. Tiles are cached on the device by flutter_map.
const String kMapTileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
const String kMapFallbackTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kMapUserAgent = 'com.aarogyasetu.aarogya_setu';

/// The ASHA worker record behind the signed-in user: matched by mobile number
/// (works for admin-issued logins and bypass logins), else the user id.
String resolveAshaId(AppUser? user, AdminRepository admin) {
  if (user == null) return '';
  final phone = AdminRepository.normalizeMobile(user.phoneNumber ?? '');
  if (phone.length == 10) {
    for (final a in admin.ashaWorkers) {
      if (AdminRepository.normalizeMobile(a.mobileNumber) == phone) return a.id;
    }
  }
  return user.uid;
}

/// District and state of the ASHA worker (falls back to their linked hospital's).
({String district, String state})? ashaDistrict(String ashaId, AdminRepository admin) {
  final asha = admin.ashaById(ashaId);
  if (asha == null) return null;
  if (asha.district.trim().isNotEmpty) return (district: asha.district, state: asha.state);
  final hospital = admin.hospitalById(asha.hospitalId);
  if (hospital != null && hospital.district.trim().isNotEmpty) {
    return (district: hospital.district, state: hospital.state);
  }
  return null;
}

/// Looks up the centre of an Indian district once (OpenStreetMap Nominatim)
/// and caches it on the device, so later map opens are instant and offline-safe.
class DistrictLocator {
  static final Map<String, LatLng> _memory = {};

  static String _key(String district, String state) => 'district_center_v1|$district|$state'.toLowerCase();

  static LatLng? cached(String district, String state) => _memory[_key(district, state)];

  static Future<LatLng?> locate(String district, String state) async {
    final key = _key(district, state);
    if (_memory.containsKey(key)) return _memory[key];
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(key);
      if (stored != null) {
        final parts = stored.split(',');
        final point = LatLng(double.parse(parts[0]), double.parse(parts[1]));
        _memory[key] = point;
        return point;
      }
      final cleanDistrict = district.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$cleanDistrict district, $state, India',
        'format': 'json',
        'limit': '1',
        'countrycodes': 'in',
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'AarogyaSetu/1.0 ($kMapUserAgent)'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>;
      final point = LatLng(double.parse(first['lat'].toString()), double.parse(first['lon'].toString()));
      _memory[key] = point;
      await prefs.setString(key, '${point.latitude},${point.longitude}');
      return point;
    } catch (e) {
      debugPrint('District location lookup skipped: $e');
      return null;
    }
  }
}

/// Open issues with a location that belong to citizens under [ashaId].
List<IssuePin> pinsForAsha(String ashaId, HealthRepository repo) {
  final now = DateTime.now();
  final pins = <IssuePin>[];
  for (final issue in repo.issues) {
    if (issue.isResolved || !issue.hasLocation) continue;
    final patient = repo.getPatientById(issue.citizenId);
    final owner = issue.ashaId ?? patient?.ashaId;
    if (owner != ashaId) continue;
    pins.add(IssuePin(
      issue: issue,
      patient: patient,
      point: LatLng(issue.latitude!, issue.longitude!),
      stage: stageFor(issue, now),
    ));
  }
  return pins;
}

/// Centre on the area with the most cases (within ~2 km); if no area has more
/// than one case, centre on the most recent case.
LatLng focusPoint(List<IssuePin> pins) {
  if (pins.isEmpty) return kDefaultMapCenter;
  const distance = Distance();
  IssuePin best = pins.reduce((a, b) => a.issue.createdAt.isAfter(b.issue.createdAt) ? a : b);
  var bestCount = 1;
  for (final p in pins) {
    final neighbours = pins.where((q) => distance.as(LengthUnit.Meter, p.point, q.point) <= 2000).toList();
    if (neighbours.length > bestCount) {
      bestCount = neighbours.length;
      final lat = neighbours.map((n) => n.point.latitude).reduce((a, b) => a + b) / neighbours.length;
      final lng = neighbours.map((n) => n.point.longitude).reduce((a, b) => a + b) / neighbours.length;
      best = IssuePin(issue: p.issue, patient: p.patient, point: LatLng(lat, lng), stage: p.stage);
    }
  }
  return best.point;
}

/// OpenStreetMap view with colour-coded issue pins.
class IssueMapView extends StatelessWidget {
  final List<IssuePin> pins;
  final MapController? controller;
  final bool interactive;
  final LatLng? center;
  final double zoom;
  final LatLng? myLocation;
  final ValueChanged<IssuePin>? onPinTap;

  const IssueMapView({
    super.key,
    required this.pins,
    this.controller,
    this.interactive = true,
    this.center,
    this.zoom = 14,
    this.myLocation,
    this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    final markerSize = interactive ? 46.0 : 34.0;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center ?? focusPoint(pins),
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: kMapTileUrl,
          fallbackUrl: kMapFallbackTileUrl,
          userAgentPackageName: kMapUserAgent,
          maxNativeZoom: 19,
          keepBuffer: 4,
          panBuffer: 1,
        ),
        if (myLocation != null)
          MarkerLayer(markers: [
            Marker(
              point: myLocation!,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
          ]),
        MarkerLayer(
          markers: [
            for (final pin in pins)
              Marker(
                point: pin.point,
                width: markerSize,
                height: markerSize,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onPinTap == null ? null : () => onPinTap!(pin),
                  child: _PinIcon(color: pin.stage.color, urgent: pin.issue.urgency == 'Urgent', size: markerSize),
                ),
              ),
          ],
        ),
        if (interactive)
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
              const TextSourceAttribution('Tiles © Esri — Esri, HERE, Garmin, USGS'),
            ],
          ),
      ],
    );
  }
}

class _PinIcon extends StatelessWidget {
  final Color color;
  final bool urgent;
  final double size;

  const _PinIcon({required this.color, required this.urgent, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(Icons.location_on, size: size, color: Colors.white),
        Padding(
          padding: EdgeInsets.only(top: size * 0.04),
          child: Icon(Icons.location_on, size: size * 0.9, color: color),
        ),
        if (urgent)
          Positioned(
            top: size * 0.18,
            child: Icon(Icons.priority_high_rounded, size: size * 0.32, color: Colors.white),
          ),
      ],
    );
  }
}

/// Legend: Green / Yellow / Red by time since the issue was raised.
class IssueMapLegend extends StatelessWidget {
  final List<IssuePin> pins;

  const IssueMapLegend({super.key, required this.pins});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final stage in IssueAgeStage.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 18, color: stage.color),
              const SizedBox(width: 2),
              Text(
                '${stage.label} (${pins.where((p) => p.stage == stage).length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ),
      ],
    );
  }
}
