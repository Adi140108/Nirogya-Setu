import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/india_locations.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';

class RegisterVillagerScreen extends StatefulWidget {
  final String? initialHouseholdId;
  const RegisterVillagerScreen({super.key, this.initialHouseholdId});

  @override
  State<RegisterVillagerScreen> createState() => _RegisterVillagerScreenState();
}

class _RegisterVillagerScreenState extends State<RegisterVillagerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianController = TextEditingController();
  late final TextEditingController _householdController;
  final _notesController = TextEditingController();
  final _passwordController = TextEditingController();
  final _abhaController = TextEditingController();
  bool _obscurePassword = true;

  String _gender = 'Female';
  String _selectedState = 'Uttar Pradesh';
  String _selectedDistrict = 'Varanasi';
  String _villageId = 'village-rampura-01';
  String _villageName = 'Rampura';
  bool _isPregnant = false;
  final List<String> _selectedAllergies = [];
  final List<String> _selectedConditions = [];

  bool _isSubmitting = false;

  final _commonConditions = const [
    'Hypertension',
    'Type 2 Diabetes',
    'Asthma / Respiratory',
    'Mild Anemia',
    'Thyroid Disorder',
    'None',
  ];

  @override
  void initState() {
    super.initState();
    _householdController = TextEditingController(text: widget.initialHouseholdId ?? '');
    // If a household ID is provided, inherit state, district, and village from existing household members
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = context.read<HealthRepository>();
      if (widget.initialHouseholdId != null) {
        final existingMember = repo.patients
            .where((p) => p.householdId == widget.initialHouseholdId)
            .firstOrNull;
        if (existingMember != null) {
          setState(() {
            _selectedState = existingMember.state ?? 'Uttar Pradesh';
            _selectedDistrict = existingMember.district ?? 'Varanasi';
            _villageName = existingMember.villageName;
            _villageId = existingMember.villageId;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _guardianController.dispose();
    _householdController.dispose();
    _notesController.dispose();
    _passwordController.dispose();
    _abhaController.dispose();
    super.dispose();
  }

  Future<void> _showAddVillageDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Add New Village',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a new village to $_selectedDistrict, $_selectedState. It will be saved into the database and available across portals.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Village Name *',
                hintText: 'e.g. Anandpur or Rampur Kalan',
                prefixIcon: Icon(Icons.holiday_village_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final repo = context.read<HealthRepository>();
      await repo.addVillage(
        name: result,
        district: _selectedDistrict,
        state: _selectedState,
      );
      setState(() {
        _villageName = result;
        _villageId = 'village-${result.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}-${DateTime.now().millisecondsSinceEpoch % 1000}';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.riskGreen,
          content: Text('✓ Village "$result" added to $_selectedDistrict and database.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<HealthRepository>();
    final ashaUser = context.read<AuthService>().currentUser;
    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // Check duplicate citizen registration
    final duplicate = repo.findDuplicateCitizen(fullName: fullName, contactNumber: phone);
    if (duplicate != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.riskRed),
              SizedBox(width: 8),
              Text('Duplicate Registration Blocked', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'A citizen named "${duplicate.fullName}" is already registered with contact "${duplicate.contactNumber}" in ${duplicate.villageName}. Multiple registrations for the same citizen are not allowed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newPatient = await repo.registerPatient(
        ashaId: ashaUser?.uid ?? 'asha-shanti-01',
        fullName: fullName,
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        villageId: _villageId,
        villageName: _villageName,
        householdId: _householdController.text.trim().isNotEmpty ? _householdController.text.trim() : 'HH-General',
        contactNumber: phone,
        guardianName: _guardianController.text.trim().isNotEmpty ? _guardianController.text.trim() : null,
        isPregnant: _isPregnant,
        knownAllergies: _selectedAllergies,
        chronicConditions: _selectedConditions,
        notes: _notesController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null,
        abhaNumber: _abhaController.text.trim().isNotEmpty ? _abhaController.text.trim() : null,
        district: _selectedDistrict,
        state: _selectedState,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.riskGreen,
          content: Text('✓ ${newPatient.fullName} registered successfully.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.riskRed, content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register Citizen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Audio guidance for registration',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'Citizen Registration',
                hindiText: 'Enter citizen full name, age, gender, household ID, and pre-existing medical conditions.',
                englishText: 'Enter citizen full name, age, gender, household ID, and pre-existing medical conditions.',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Demographics Card
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.person_add_alt_1_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age *',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter age';
                            final n = int.tryParse(v);
                            if (n == null || n < 0 || n > 120) return 'Valid age (0-120)';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender *',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Female', child: Text('Female', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Male', child: Text('Male', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Other', child: Text('Other', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _gender = v;
                                if (_gender != 'Female') _isPregnant = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone *',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+91 98765 00000',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter mobile number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guardianController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian / Family Head',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                      hintText: 'e.g. Ramesh Kumar (Husband / Father)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _abhaController,
                    decoration: const InputDecoration(
                      labelText: 'ABHA ID / Health Number (Optional)',
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: '14-digit ABHA (e.g. 14-1234-5678-9012) or name@abdm',
                      helperText: 'Displayed on Citizen Digital Health Card and OPD card',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Custom Password for Citizen Login',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      hintText: 'e.g. 123456 or Pass@123',
                      helperText: 'Citizen uses their contact phone and this password to log into the Citizen Portal',
                      helperMaxLines: 2,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location & Household Card
              _buildSectionCard(
                title: 'Village & Household',
                icon: Icons.location_on_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedState,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: IndiaLocations.states.map((st) {
                            return DropdownMenuItem(
                              value: st,
                              child: Text(st, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null && v != _selectedState) {
                              setState(() {
                                _selectedState = v;
                                final districts = IndiaLocations.districtsOf(v);
                                _selectedDistrict = districts.isNotEmpty ? districts.first : 'Varanasi';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: IndiaLocations.districtsOf(_selectedState).contains(_selectedDistrict)
                              ? _selectedDistrict
                              : (IndiaLocations.districtsOf(_selectedState).isNotEmpty
                                  ? IndiaLocations.districtsOf(_selectedState).first
                                  : null),
                          decoration: const InputDecoration(
                            labelText: 'District *',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          items: IndiaLocations.districtsOf(_selectedState).map((dist) {
                            return DropdownMenuItem(
                              value: dist,
                              child: Text(dist, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedDistrict = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx) {
                      final repo = ctx.watch<HealthRepository>();
                      final villages = repo.getVillagesFor(state: _selectedState, district: _selectedDistrict);
                      if (!villages.contains(_villageName)) {
                        if (villages.isNotEmpty) {
                          _villageName = villages.first;
                          _villageId = 'village-${_villageName.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
                        }
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: villages.contains(_villageName) ? _villageName : (villages.isNotEmpty ? villages.first : null),
                              decoration: const InputDecoration(
                                labelText: 'Assigned Village *',
                                prefixIcon: Icon(Icons.home_work_outlined),
                                helperText: 'Filtered by state & district',
                              ),
                              items: villages.map((vName) {
                                return DropdownMenuItem(
                                  value: vName,
                                  child: Text(vName, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _villageName = v;
                                    _villageId = 'village-${v.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showAddVillageDialog,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('+ Add Village', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _householdController,
                    decoration: const InputDecoration(
                      labelText: 'Household ID',
                      prefixIcon: Icon(Icons.tag_rounded),
                      hintText: 'e.g. HH-042',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Health History & Conditions
              _buildSectionCard(
                title: 'Medical Profile',
                icon: Icons.medical_information_outlined,
                children: [
                  if (_gender == 'Female') ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Is Pregnant?'),
                      subtitle: const Text('Enroll in Antenatal Care (ANC) tracking'),
                      value: _isPregnant,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isPregnant = val),
                    ),
                    const Divider(),
                  ],
                  const Text(
                    'Pre-existing Chronic Conditions:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _commonConditions.map((cond) {
                      final isSelected = _selectedConditions.contains(cond);
                      return FilterChip(
                        label: Text(cond),
                        selected: isSelected,
                        selectedColor: AppColors.primarySurface,
                        checkmarkColor: AppColors.primary,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (cond == 'None') {
                                _selectedConditions.clear();
                              } else {
                                _selectedConditions.remove('None');
                              }
                              _selectedConditions.add(cond);
                            } else {
                              _selectedConditions.remove(cond);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ASHA Field Notes',
                      hintText: 'Notes regarding diet, disability, or living conditions...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isSubmitting ? 'Registering...' : 'Save & Register Citizen',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
