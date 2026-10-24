import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/app_locale.dart';
import 'register_villager_screen.dart';
import 'patient_detail_screen.dart';
import '../widgets/issue_map_preview.dart';

class AshaHouseholdsScreen extends StatefulWidget {
  final bool isEmbedded;

  const AshaHouseholdsScreen({super.key, this.isEmbedded = false});

  @override
  State<AshaHouseholdsScreen> createState() => _AshaHouseholdsScreenState();
}

class _AshaHouseholdsScreenState extends State<AshaHouseholdsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HealthRepository>();
    final householdsMap = repo.getHouseholds();

    final filteredHouseholds = householdsMap.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final hId = entry.key.toLowerCase();
      final memberMatches = entry.value.any((m) =>
          m.fullName.toLowerCase().contains(q) ||
          m.contactNumber.contains(q) ||
          m.villageName.toLowerCase().contains(q));
      return hId.contains(q) || memberMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aarogya Setu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Household & Family Registry', style: TextStyle(fontSize: 11, color: Color(0xFFE0F2F1))),
                ],
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      body: Column(
        children: [
          // Live map preview of open issues (tap for full-screen map)
          const AshaIssueMapPreview(),

          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.watch<AppLocale>().t('villageHouseholds'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '${householdsMap.length} ${context.watch<AppLocale>().t('families')}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: context.watch<AppLocale>().t('searchHouseholds'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredHouseholds.isEmpty
                ? Center(
                    child: Text(
                      context.watch<AppLocale>().t('noHouseholdsFound'),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: filteredHouseholds.length,
                    itemBuilder: (context, index) {
                      final entry = filteredHouseholds[index];
                      final householdId = entry.key;
                      final members = entry.value;
                      final head = members.first;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Household Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.home_rounded, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Household: $householdId',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Text(
                                    '${members.length} Members • ${head.villageName}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),

                            // Member List
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  ...members.map((m) {
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PatientDetailScreen(patientId: m.id),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppColors.primarySurface,
                                              child: Text(
                                                m.fullName.isNotEmpty ? m.fullName[0] : '?',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${m.fullName} (${m.displayRelationship})',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                                  ),
                                                  Text(
                                                    '${m.age}y, ${m.gender} • Contact: ${m.contactNumber}',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (m.isPregnant)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFCE7F3),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('ANC', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFBE185D))),
                                              ),
                                            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  const Divider(height: 16),

                                  // Add Member inside this Household
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                      label: const Text('Add Family Member to this Household', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () => _openAddMemberDialog(context, repo, householdId, head),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_rounded),
        label: const Text('New Household', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterVillagerScreen()),
          );
        },
      ),
    );
  }

  void _openAddMemberDialog(BuildContext context, HealthRepository repo, String householdId, PatientModel head) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: head.contactNumber);
    final passwordCtrl = TextEditingController();
    String gender = 'Female';
    String relationship = 'Wife';
    bool isPregnant = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Member to Household ($householdId)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Village: ${head.villageName} • Head: ${head.fullName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() {
                                  gender = v;
                                  if (gender != 'Female') isPregnant = false;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: relationship,
                            decoration: const InputDecoration(
                              labelText: 'Relationship to Head',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Wife', child: Text('Wife')),
                              DropdownMenuItem(value: 'Husband', child: Text('Husband')),
                              DropdownMenuItem(value: 'Son', child: Text('Son')),
                              DropdownMenuItem(value: 'Daughter', child: Text('Daughter')),
                              DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                              DropdownMenuItem(value: 'Father', child: Text('Father')),
                              DropdownMenuItem(value: 'Grandparent', child: Text('Grandparent')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) {
                              if (v != null) setSheetState(() => relationship = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        border: OutlineInputBorder(),
                        hintText: '+91 98765 00000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Citizen Password (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 123456 (For Citizen Portal login)',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    if (gender == 'Female') ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Is Pregnant? (Maternal Care)', style: TextStyle(fontSize: 13)),
                        value: isPregnant,
                        onChanged: (v) => setSheetState(() => isPregnant = v ?? false),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final age = int.tryParse(ageCtrl.text.trim()) ?? 0;
                        final phone = phoneCtrl.text.trim();

                        if (name.isEmpty || age <= 0 || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please provide valid name, age and phone number.')),
                          );
                          return;
                        }

                        // Duplicate Protection Check
                        final duplicate = repo.findDuplicateCitizen(fullName: name, contactNumber: phone);
                        if (duplicate != null) {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppColors.riskRed),
                                  SizedBox(width: 8),
                                  Text('Duplicate Citizen Detected', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: Text(
                                'A citizen named "${duplicate.fullName}" is already registered with contact "${duplicate.contactNumber}" in ${duplicate.villageName}. Duplicate entries cannot be created.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
                              ],
                            ),
                          );
                          return;
                        }

                        try {
                          final newMember = await repo.addFamilyMember(
                            householdId: householdId,
                            fullName: name,
                            age: age,
                            gender: gender,
                            relationship: relationship,
                            villageId: head.villageId,
                            villageName: head.villageName,
                            contactNumber: phone,
                            isPregnant: isPregnant,
                            password: passwordCtrl.text.trim().isNotEmpty ? passwordCtrl.text.trim() : null,
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.riskGreen,
                                content: Text('✓ ${newMember.fullName} enrolled into household $householdId.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: AppColors.riskRed, content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Save & Enroll Member', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
