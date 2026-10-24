import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/health_repository.dart';
import 'patient_detail_screen.dart';

class VillageHouseholdMapScreen extends StatefulWidget {
  const VillageHouseholdMapScreen({super.key});

  @override
  State<VillageHouseholdMapScreen> createState() => _VillageHouseholdMapScreenState();
}

class _VillageHouseholdMapScreenState extends State<VillageHouseholdMapScreen> {
  String _selectedFilter = 'All';
  String? _selectedHouseholdId;

  // Mock geo-coordinates and metadata for village households
  final List<Map<String, dynamic>> _householdLocations = [
    {
      'id': 'HH-042',
      'x': 0.28,
      'y': 0.35,
      'sector': 'North Rampura (Near Canal)',
      'priority': 'Normal',
      'hasPendingIssue': true,
    },
    {
      'id': 'HH-088',
      'x': 0.65,
      'y': 0.25,
      'sector': 'East Rampura (Panchayat Road)',
      'priority': 'High',
      'hasPendingIssue': true,
    },
    {
      'id': 'HH-104',
      'x': 0.45,
      'y': 0.62,
      'sector': 'Central Village (Market Square)',
      'priority': 'Moderate',
      'hasPendingIssue': false,
    },
    {
      'id': 'HH-112',
      'x': 0.78,
      'y': 0.70,
      'sector': 'South Rampura (School Road)',
      'priority': 'Normal',
      'hasPendingIssue': false,
    },
    {
      'id': 'HH-019',
      'x': 0.20,
      'y': 0.75,
      'sector': 'West Rampura (Well Area)',
      'priority': 'Normal',
      'hasPendingIssue': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final householdsMap = repo.getHouseholds();

    final filteredPins = _householdLocations.where((loc) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'High Risk') return loc['priority'] == 'High';
      if (_selectedFilter == 'Issues Pending') return loc['hasPendingIssue'] == true;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Village Household Geo-Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center on Rampura Village',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Centered on Village Rampura • GPS Precision: 4m'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', Icons.map_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('High Risk', Icons.warning_amber_rounded,
                      activeColor: Colors.red),
                  const SizedBox(width: 8),
                  _buildFilterChip('Issues Pending', Icons.mark_email_unread_rounded,
                      activeColor: Colors.orange),
                ],
              ),
            ),
          ),

          // Interactive Map Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Stylized Village Topography Canvas
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _VillageTopographyPainter(),
                    ),

                    // Household Pins
                    ...filteredPins.map((loc) {
                      final hId = loc['id'] as String;
                      final isSelected = _selectedHouseholdId == hId;
                      final isHigh = loc['priority'] == 'High';
                      final hasIssue = loc['hasPendingIssue'] == true;

                      final pinLeft = loc['x'] * constraints.maxWidth - 20;
                      final pinTop = loc['y'] * constraints.maxHeight - 20;

                      return Positioned(
                        left: pinLeft.clamp(10.0, constraints.maxWidth - 50),
                        top: pinTop.clamp(10.0, constraints.maxHeight - 60),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedHouseholdId = hId);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.black
                                            : (isHigh
                                                ? Colors.red
                                                : (hasIssue
                                                    ? Colors.amber.shade800
                                                    : AppColors.primaryGreen)),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.home_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    if (hasIssue)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    hId,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.black : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Map Legend overlay
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildLegendItem(AppColors.primaryGreen, 'Normal'),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.red, 'High Risk'),
                            const SizedBox(width: 8),
                            _buildLegendItem(Colors.amber.shade800, 'Issue Raised'),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info sheet when a household is selected
                    if (_selectedHouseholdId != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _buildHouseholdDetailCard(
                          householdsMap[_selectedHouseholdId] ?? [],
                          _householdLocations.firstWhere(
                            (l) => l['id'] == _selectedHouseholdId,
                            orElse: () => {},
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {Color? activeColor}) {
    final isSelected = _selectedFilter == label;
    final color = activeColor ?? AppColors.primaryGreen;

    return ChoiceChip(
      selected: isSelected,
      selectedColor: color.withOpacity(0.18),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? color : Colors.grey.shade600,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
        ),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = label);
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHouseholdDetailCard(
      List<PatientModel> members, Map<String, dynamic> loc) {
    final head = members.isNotEmpty
        ? members.firstWhere((m) => m.relationship == 'Self',
            orElse: () => members.first)
        : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Household: ${_selectedHouseholdId ?? ""}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() => _selectedHouseholdId = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sector: ${loc['sector'] ?? "Rampura Village"}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (head != null) ...[
              const SizedBox(height: 4),
              Text(
                'Head of House: ${head.fullName} • ${members.length} Registered Members',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (head != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => PatientDetailScreen(patientId: head.id),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.visibility_rounded,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Open Household Members',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VillageTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Village background field
    final bgPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green fields & crop patches
    final fieldPaint = Paint()..color = const Color(0xFFDCFCE7).withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.08, size.width * 0.4,
            size.height * 0.25),
        const Radius.circular(16),
      ),
      fieldPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.5, size.width * 0.4,
            size.height * 0.35),
        const Radius.circular(16),
      ),
      fieldPaint,
    );

    // Water canal / pond
    final waterPaint = Paint()..color = const Color(0xFFBAE6FD);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.45, size.width * 0.22,
          size.height * 0.14),
      waterPaint,
    );

    // Village Road paths
    final roadPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPath = Path();
    roadPath.moveTo(size.width * 0.1, size.height * 0.1);
    roadPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4,
      size.width * 0.9,
      size.height * 0.85,
    );
    roadPath.moveTo(size.width * 0.5, size.height * 0.4);
    roadPath.lineTo(size.width * 0.2, size.height * 0.8);

    canvas.drawPath(roadPath, roadPaint);

    final roadCenterPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roadPath, roadCenterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
