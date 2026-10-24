import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/voice_service.dart';
import '../../shared/widgets/ui.dart';

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

  final _genders = const ['Female', 'Male', 'Other'];

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
  }

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
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.secondary, size: 28),
          title: const Text('Already registered'),
          content: Text(
            '"${duplicate.fullName}" is already registered with phone ${duplicate.contactNumber} in ${duplicate.villageName}. The same person cannot be registered twice.',
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
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('${newPatient.fullName} is registered.')),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('RegisterVillagerScreen: registerPatient failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Could not save. Please try again.')),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register citizen'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen'),
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('About the person'),
              ..._buildBasicFields(),
              const SectionHeader('Village and household'),
              ..._buildLocationFields(),
              const SectionHeader('Health history'),
              ..._buildHealthFields(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: AppButton(
            label: 'Save citizen',
            icon: Icons.check_circle_rounded,
            loading: _isSubmitting,
            loadingLabel: 'Saving…',
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBasicFields() {
    return [
      TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Full name *',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Age *',
          helperText: 'In years',
          prefixIcon: Icon(Icons.cake_outlined),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter age';
          final n = int.tryParse(v);
          if (n == null || n < 0 || n > 120) return 'Enter an age between 0 and 120';
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      const _FieldLabel('Gender *'),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _genders.map((g) {
          return ChoiceChip(
            label: Text(g),
            selected: _gender == g,
            onSelected: (_) {
              setState(() {
                _gender = g;
                if (_gender != 'Female') _isPregnant = false;
              });
            },
          );
        }).toList(),
      ),
      const SizedBox(height: AppSpacing.lg),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Phone number *',
          prefixIcon: Icon(Icons.phone_outlined),
          hintText: '+91 98765 00000',
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter mobile number' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _guardianController,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Guardian or family head',
          prefixIcon: Icon(Icons.family_restroom_outlined),
          hintText: 'e.g. Ramesh Kumar (husband)',
        ),
      ),
    ];
  }

  List<Widget> _buildLocationFields() {
    return [
      const _FieldLabel('Village *'),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _allVillages.map((v) {
          return ChoiceChip(
            label: Text(v['name']!),
            selected: _villageId == v['id'],
            onSelected: (_) {
              setState(() {
                _villageId = v['id']!;
                _villageName = v['name']!;
              });
            },
          );
        }).toList(),
      ),
      const SizedBox(height: AppSpacing.lg),
      TextFormField(
        controller: _householdController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Household ID',
          prefixIcon: Icon(Icons.tag_rounded),
          hintText: 'e.g. HH-042',
        ),
      ),
    ];
  }

  List<Widget> _buildHealthFields() {
    return [
      if (_gender == 'Female') ...[
        InfoCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: SwitchListTile(
            title: const Text('Pregnant'),
            subtitle: const Text('Track pregnancy check-ups (ANC)'),
            value: _isPregnant,
            onChanged: (val) => setState(() => _isPregnant = val),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      const _FieldLabel('Long-term illness (tap all that apply)'),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _commonConditions.map((cond) {
          final isSelected = _selectedConditions.contains(cond);
          return FilterChip(
            label: Text(cond),
            selected: isSelected,
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
      const SizedBox(height: AppSpacing.lg),
      TextFormField(
        controller: _notesController,
        maxLines: 3,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(
          labelText: 'Notes',
          hintText: 'Diet, disability or living conditions',
          alignLabelWithHint: true,
        ),
      ),
    ];
  }
}

/// Small label shown above chip groups.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
