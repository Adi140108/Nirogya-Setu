import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/location_service.dart';
import '../widgets/issue_map.dart';

/// Full-screen live map (OpenStreetMap) of open issues raised by the citizens
/// this ASHA worker looks after. Pins are coloured by time since the issue was
/// raised: green < 36 h, yellow 36–72 h, red after 72 h until attended.
class VillageHouseholdMapScreen extends StatefulWidget {
  const VillageHouseholdMapScreen({super.key});

  @override
  State<VillageHouseholdMapScreen> createState() => _VillageHouseholdMapScreenState();
}

class _VillageHouseholdMapScreenState extends State<VillageHouseholdMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _myLocation;
  LatLng? _districtCenter;
  String? _requestedDistrictKey;
  Timer? _ticker;
  bool _fittedOnce = false;

  /// With no open cases, open on the ASHA worker's district.
  void _ensureDistrictCenter(({String district, String state})? district, bool hasPins) {
    if (district == null) return;
    final key = '${district.district}|${district.state}';
    if (_requestedDistrictKey == key) return;
    _requestedDistrictKey = key;
    _districtCenter = DistrictLocator.cached(district.district, district.state);
    if (_districtCenter != null) return;
    DistrictLocator.locate(district.district, district.state).then((point) {
      if (!mounted || point == null) return;
      setState(() => _districtCenter = point);
      if (!hasPins) _mapController.move(point, 10);
    });
  }

  @override
  void initState() {
    super.initState();
    // Re-colour pins as time passes.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadMyLocation(moveCamera: false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadMyLocation({required bool moveCamera}) async {
    final pos = await LocationService.currentPosition();
    if (!mounted) return;
    if (pos == null) {
      if (moveCamera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location unavailable. Turn on location and allow access.')),
        );
      }
      return;
    }
    setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
    if (moveCamera) _mapController.move(_myLocation!, 16);
  }

  void _fitAll(List<IssuePin> pins) {
    if (pins.isEmpty) return;
    if (pins.length == 1) {
      _mapController.move(pins.first.point, 16);
      return;
    }
    _mapController.fitCamera(CameraFit.coordinates(
      coordinates: pins.map((p) => p.point).toList(),
      padding: const EdgeInsets.all(60),
      maxZoom: 16,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final admin = context.watch<AdminRepository>();
    final user = context.watch<AuthService>().currentUser;
    final ashaId = resolveAshaId(user, admin);
    final pins = pinsForAsha(ashaId, repo);
    _ensureDistrictCenter(ashaDistrict(ashaId, admin), pins.isNotEmpty);

    if (!_fittedOnce && pins.length > 1) {
      _fittedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitAll(pins);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Issue Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Open issues from your citizens', style: TextStyle(fontSize: 11, color: Color(0xFFD1FAE5))),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map_rounded),
            tooltip: 'Show all pins',
            onPressed: pins.isEmpty ? null : () => _fitAll(pins),
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'My location',
            onPressed: () => _loadMyLocation(moveCamera: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pins.isEmpty
                      ? 'No open issues with a location right now'
                      : '${pins.length} open issue${pins.length == 1 ? '' : 's'} • tap a pin for patient details',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                IssueMapLegend(pins: pins),
              ],
            ),
          ),
          Expanded(
            child: IssueMapView(
              pins: pins,
              controller: _mapController,
              interactive: true,
              center: pins.isEmpty ? (_districtCenter ?? _myLocation ?? kDefaultMapCenter) : focusPoint(pins),
              zoom: pins.isEmpty ? 10 : 15,
              myLocation: _myLocation,
              onPinTap: (pin) => showIssuePinDetails(context, pin),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet popup with the patient and issue details behind a map pin.
Future<void> showIssuePinDetails(BuildContext context, IssuePin pin) {
  final issue = pin.issue;
  final patient = pin.patient;
  final color = pin.stage.color;

  Widget row(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)))),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.location_on, color: color, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.citizenName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text(
                          '${pin.stage.label} • raised ${elapsedLabel(issue.createdAt)}',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                  ),
                  if (issue.urgency == 'Urgent')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('URGENT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.category,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(issue.description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.35)),
                    if (issue.hasVoiceNote && (issue.voiceTranscription ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('🎙️ ${issue.voiceTranscription}',
                          style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              row(Icons.person_outline_rounded, 'Patient',
                  patient != null ? '${patient.fullName} • ${patient.age} yrs • ${patient.gender}' : issue.citizenName),
              row(Icons.call_outlined, 'Contact', issue.contactNumber),
              row(Icons.house_outlined, 'Household', issue.householdId),
              row(Icons.location_city_outlined, 'Village', issue.villageName),
              if (patient != null && patient.isPregnant) row(Icons.pregnant_woman_rounded, 'ANC', 'Pregnant — under ANC tracking'),
              if (patient != null && patient.chronicConditions.isNotEmpty)
                row(Icons.medical_information_outlined, 'Conditions', patient.chronicConditions.join(', ')),
              row(Icons.schedule_rounded, 'Raised on', DateFormat('dd MMM yyyy, hh:mm a').format(issue.createdAt)),
              row(Icons.gps_fixed_rounded, 'Location',
                  '${issue.latitude!.toStringAsFixed(5)}, ${issue.longitude!.toStringAsFixed(5)}'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: issue.contactNumber.trim().isEmpty
                          ? null
                          : () => launchUrl(Uri(scheme: 'tel', path: issue.contactNumber.replaceAll(' ', ''))),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${issue.latitude},${issue.longitude}'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await ctx.read<HealthRepository>().resolveIssue(issue.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Mark as attended', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
