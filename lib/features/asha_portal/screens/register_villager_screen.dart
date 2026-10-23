import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';

class RegisterVillagerScreen extends StatefulWidget {
  const RegisterVillagerScreen({super.key});

  @override
  State<RegisterVillagerScreen> createState() => _RegisterVillagerScreenState();
}

class _RegisterVillagerScreenState extends State<RegisterVillagerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianController = TextEditingController();
  final _householdController = TextEditingController();
  final _notesController = TextEditingController();

  String _gender = 'Female';
  String _villageId = 'village-rampura-01';
  String _villageName = 'Rampura';
  bool _isPregnant = false;
  final List<String> _selectedAllergies = [];
  final List<String> _selectedConditions = [];

  bool _isSubmitting = false;

  final _allVillages = const [
    {'id': 'village-rampura-01', 'name': 'Rampura'},
    {'id': 'village-khed-02', 'name': 'Khed Buzurg'},
    {'id': 'village-bhopal-03', 'name': 'Sundarpur'},
  ];

  final _commonConditions = const [
    'Hypertension',
    'Type 2 Diabetes',
    'Asthma / Respiratory',
    'Mild Anemia',
    'Thyroid Disorder',
    'None',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _guardianController.dispose();
    _householdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = context.read<HealthRepository>();
    final ashaUser = context.read<AuthService>().currentUser;

    try {
      final newPatient = await repo.registerPatient(
        ashaId: ashaUser?.uid ?? 'asha-shanti-01',
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        villageId: _villageId,
        villageName: _villageName,
        householdId: _householdController.text.trim().isNotEmpty ? _householdController.text.trim() : null,
        contactNumber: _phoneController.text.trim(),
        guardianName: _guardianController.text.trim().isNotEmpty ? _guardianController.text.trim() : null,
        isPregnant: _isPregnant,
        knownAllergies: _selectedAllergies,
        chronicConditions: _selectedConditions,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.riskGreen,
          content: Text('✓ ${newPatient.fullName} registered successfully (Saved locally).'),
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
        title: const Text('नागरिक पंजीकरण / Register Citizen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Voice guide for registration',
            onPressed: () {
              VoiceService().speakPrompt(
                context,
                title: 'पंजीकरण सहायता / Registration Help',
                hindiText: 'नागरिक का नाम, आयु, लिंग, गांव और स्वास्थ्य इतिहास दर्ज करें।',
                englishText: 'Enter citizen name, age, gender, village and known medical conditions.',
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
                title: 'व्यक्तिगत जानकारी / Basic Information',
                icon: Icons.person_add_alt_1_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name / पूरा नाम *',
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
                            labelText: 'Age / उम्र *',
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
                            labelText: 'Gender / लिंग *',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Female', child: Text('Female / महिला', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Male', child: Text('Male / पुरुष', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Other', child: Text('Other / अन्य', overflow: TextOverflow.ellipsis)),
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
                      labelText: 'Contact Phone / मोबाइल नंबर *',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+91 98765 00000',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter mobile number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guardianController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian / Relative / अभिभावक',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                      hintText: 'e.g. Ramesh (Husband / Father)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location & Household Card
              _buildSectionCard(
                title: 'गाँव और पता / Village & Household',
                icon: Icons.location_on_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _villageId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Village / गाँव *',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                    items: _allVillages.map((v) {
                      return DropdownMenuItem(
                        value: v['id'],
                        child: Text(v['name']!, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _villageId = v;
                          _villageName = _allVillages.firstWhere((x) => x['id'] == v)['name']!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _householdController,
                    decoration: const InputDecoration(
                      labelText: 'Household ID / घर संख्या',
                      prefixIcon: Icon(Icons.tag_rounded),
                      hintText: 'HH-042',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Health History & Conditions
              _buildSectionCard(
                title: 'स्वास्थ्य इतिहास / Medical Profile',
                icon: Icons.medical_information_outlined,
                children: [
                  if (_gender == 'Female') ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Is Pregnant? / क्या गर्भवती हैं?'),
                      subtitle: const Text('Antenatal care and tracking flag'),
                      value: _isPregnant,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isPregnant = val),
                    ),
                    const Divider(),
                  ],
                  const Text(
                    'Pre-existing Chronic Conditions / पुरानी बीमारियां:',
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
                      labelText: 'ASHA Field Notes / अतिरिक्त टिप्पणियां',
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
                  _isSubmitting ? 'पंजीकरण हो रहा है...' : 'Save & Register Citizen',
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
