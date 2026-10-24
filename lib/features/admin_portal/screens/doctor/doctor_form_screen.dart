import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../widgets/admin_ui.dart';

/// Add or edit a doctor. The hospital list only contains hospitals from the hospital database.
class DoctorFormScreen extends StatefulWidget {
  final DoctorModel? existing;

  const DoctorFormScreen({super.key, this.existing});

  @override
  State<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends State<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _qualification;
  late final TextEditingController _registration;
  late final TextEditingController _experience;

  String _gender = 'Male';
  String? _specialization;
  String? _hospitalId;
  bool _isBusy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? '');
    _age = TextEditingController(text: e != null && e.age > 0 ? '${e.age}' : '');
    _mobile = TextEditingController(text: e?.mobileNumber ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _qualification = TextEditingController(text: e?.qualification ?? '');
    _registration = TextEditingController(text: e?.registrationNumber ?? '');
    _experience = TextEditingController(text: e != null ? '${e.experienceYears}' : '');
    _gender = e?.gender ?? 'Male';
    _specialization = e != null && AdminRepository.doctorSpecializations.contains(e.specialization)
        ? e.specialization
        : null;
    _hospitalId = e?.hospitalId;
    _name.addListener(_refreshPreview);
    _mobile.addListener(_refreshPreview);
  }

  void _fillSampleDoctorData(List<HospitalModel> hospitals) {
    final rand = Random();
    final names = [
      'Dr. Ananya Rao, MD',
      'Dr. Vikram Sethi, MS',
      'Dr. Priya Nair, MD',
      'Dr. Arvind Deshmukh, MD',
      'Dr. Meenakshi Sundaram, DNB',
    ];
    final selectedName = names[rand.nextInt(names.length)];
    final age = 32 + rand.nextInt(26);
    final mobile = '9871${100000 + rand.nextInt(899999)}';
    final regNo = 'MCI-${rand.nextInt(89999) + 10000}';

    setState(() {
      _name.text = selectedName;
      _age.text = '$age';
      _gender = selectedName.contains('Ananya') || selectedName.contains('Priya') || selectedName.contains('Meenakshi')
          ? 'Female'
          : 'Male';
      _mobile.text = mobile;
      _email.text = '${selectedName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase()}@nirogyasetu.gov.in';
      _qualification.text = 'MBBS, MD (General Medicine)';
      _registration.text = regNo;
      _experience.text = '${4 + rand.nextInt(20)}';
      _specialization = AdminRepository.doctorSpecializations.contains('General Medicine')
          ? 'General Medicine'
          : AdminRepository.doctorSpecializations.first;
      if (hospitals.isNotEmpty && _hospitalId == null) {
        _hospitalId = hospitals.first.id;
      }
    });

    showAdminSnack(context, '⚡ Sample Doctor details filled.');
  }

  void _refreshPreview() {
    if (!_isEdit) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _mobile.dispose();
    _email.dispose();
    _qualification.dispose();
    _registration.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AdminRepository>();
    setState(() => _isBusy = true);
    try {
      if (_isEdit) {
        await repo.updateDoctor(widget.existing!.copyWith(
          fullName: _name.text.trim(),
          age: int.parse(_age.text.trim()),
          gender: _gender,
          mobileNumber: _mobile.text.trim(),
          email: _email.text.trim(),
          specialization: _specialization,
          qualification: _qualification.text.trim(),
          registrationNumber: _registration.text.trim(),
          experienceYears: int.tryParse(_experience.text.trim()) ?? 0,
          hospitalId: _hospitalId,
        ));
        if (!mounted) return;
        showAdminSnack(context, 'Doctor details updated');
        Navigator.pop(context);
      } else {
        final doctor = await repo.addDoctor(
          fullName: _name.text.trim(),
          age: int.parse(_age.text.trim()),
          gender: _gender,
          mobileNumber: _mobile.text.trim(),
          email: _email.text.trim(),
          specialization: _specialization!,
          qualification: _qualification.text.trim(),
          registrationNumber: _registration.text.trim(),
          experienceYears: int.tryParse(_experience.text.trim()) ?? 0,
          hospitalId: _hospitalId!,
        );
        if (!mounted) return;
        await showCredentialsDialog(
          context,
          title: 'Doctor added',
          name: doctor.fullName,
          mobile: AdminRepository.formatMobile(doctor.mobileNumber),
          password: doctor.password,
          color: AdminColors.doctor,
        );
        if (mounted) Navigator.pop(context, doctor);
      }
    } catch (e) {
      if (mounted) showAdminSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AdminRepository>();
    final hospitals = repo.hospitals;
    final selectedHospital = hospitals.any((h) => h.id == _hospitalId) ? _hospitalId : null;
    final previewPassword = _name.text.trim().isNotEmpty && AdminRepository.validateMobile(_mobile.text) == null
        ? AdminRepository.generatePassword(_name.text, _mobile.text)
        : null;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.ink,
        title: Text(_isEdit ? 'Edit Doctor' : 'Add Doctor',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AdminColors.doctor,
              backgroundColor: AdminColors.doctorSurface,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text('Sample Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _fillSampleDoctorData(hospitals),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: hospitals.isEmpty
          ? const AdminEmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'No hospitals available',
              message: 'Add a hospital from the Hospital tab first. Every doctor must be linked to a hospital.',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AdminFormSection(
                    title: 'Personal details',
                    icon: Icons.person_outline_rounded,
                    children: [
                      AdminField(
                        child: TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                              adminInput('Full name *', icon: Icons.badge_outlined, hint: 'e.g. Dr. Rajesh Sharma'),
                          validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the full name' : null,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AdminField(
                              child: TextFormField(
                                controller: _age,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                decoration: adminInput('Age *', icon: Icons.cake_outlined),
                                validator: (v) {
                                  final age = int.tryParse((v ?? '').trim());
                                  if (age == null) return 'Required';
                                  if (age < 22 || age > 80) return '22 – 80';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AdminField(
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                isExpanded: true,
                                decoration: adminInput('Gender *'),
                                items: const ['Male', 'Female', 'Other']
                                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                    .toList(),
                                onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AdminField(
                        child: TextFormField(
                          controller: _mobile,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: adminInput('Mobile number *', icon: Icons.call_outlined, prefixText: '+91 '),
                          validator: (v) {
                            final error = AdminRepository.validateMobile(v);
                            if (error != null) return error;
                            final usedBy = repo.mobileInUseBy(v!, excludeId: widget.existing?.id);
                            return usedBy != null ? 'Already registered to $usedBy' : null;
                          },
                        ),
                      ),
                      AdminField(
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: adminInput('Email (optional)', icon: Icons.mail_outline_rounded),
                          validator: (v) {
                            final email = (v ?? '').trim();
                            if (email.isEmpty) return null;
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? null : 'Enter a valid email';
                          },
                        ),
                      ),
                    ],
                  ),
                  AdminFormSection(
                    title: 'Professional details',
                    icon: Icons.workspace_premium_outlined,
                    children: [
                      AdminField(
                        child: DropdownButtonFormField<String>(
                          value: _specialization,
                          isExpanded: true,
                          decoration: adminInput('Specialization *', icon: Icons.medical_information_outlined),
                          items: AdminRepository.doctorSpecializations
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          validator: (v) => v == null ? 'Select a specialization' : null,
                          onChanged: (v) => setState(() => _specialization = v),
                        ),
                      ),
                      AdminField(
                        child: TextFormField(
                          controller: _qualification,
                          textCapitalization: TextCapitalization.characters,
                          decoration:
                              adminInput('Qualification *', icon: Icons.school_outlined, hint: 'e.g. MBBS, MD (Medicine)'),
                          validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the qualification' : null,
                        ),
                      ),
                      AdminField(
                        child: TextFormField(
                          controller: _registration,
                          textCapitalization: TextCapitalization.characters,
                          decoration: adminInput('Medical registration no. *',
                              icon: Icons.verified_outlined, hint: 'NMC / State Council number'),
                          validator: (v) {
                            final reg = (v ?? '').trim();
                            if (reg.length < 4) return 'Enter the registration number';
                            final duplicate = repo.doctors.any((d) =>
                                d.id != widget.existing?.id && d.registrationNumber.toLowerCase() == reg.toLowerCase());
                            return duplicate ? 'This registration number is already in use' : null;
                          },
                        ),
                      ),
                      AdminField(
                        child: TextFormField(
                          controller: _experience,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                          decoration: adminInput('Years of experience *', icon: Icons.timeline_rounded),
                          validator: (v) {
                            final years = int.tryParse((v ?? '').trim());
                            if (years == null) return 'Required';
                            final age = int.tryParse(_age.text.trim());
                            if (age != null && years > age - 20) return 'Not possible for the given age';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  AdminFormSection(
                    title: 'Hospital',
                    icon: Icons.local_hospital_outlined,
                    children: [
                      AdminField(
                        child: DropdownButtonFormField<String>(
                          value: selectedHospital,
                          isExpanded: true,
                          decoration: adminInput('Linked hospital *', icon: Icons.local_hospital_outlined),
                          items: hospitals
                              .map((h) => DropdownMenuItem(
                                    value: h.id,
                                    child: Text('${h.name} • ${h.villageTown}', overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          validator: (v) => v == null ? 'Select the hospital this doctor works at' : null,
                          onChanged: (v) => setState(() => _hospitalId = v),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AdminColors.accentSurface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.key_rounded, size: 18, color: AdminColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEdit
                                ? 'The login password does not change when you edit details. Use "Reset password" on the profile to issue a new one.'
                                : previewPassword != null
                                    ? 'Login password will be generated automatically: $previewPassword\nThe doctor signs in with the mobile number and this password.'
                                    : 'A simple login password will be generated automatically from the name and mobile number.',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF075985), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminPrimaryButton(
                    label: _isEdit ? 'Save Changes' : 'Add Doctor',
                    icon: _isEdit ? Icons.check_rounded : Icons.medical_services_rounded,
                    isBusy: _isBusy,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
