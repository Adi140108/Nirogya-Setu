import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/india_locations.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../widgets/admin_ui.dart';

/// Add or edit an ASHA worker. A login password is generated automatically on add.
class AshaFormScreen extends StatefulWidget {
  final AshaWorkerModel? existing;

  const AshaFormScreen({super.key, this.existing});

  @override
  State<AshaFormScreen> createState() => _AshaFormScreenState();
}

class _AshaFormScreenState extends State<AshaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _mobile;
  late final TextEditingController _ashaId;
  late final TextEditingController _address;
  late final TextEditingController _village;

  String _gender = 'Female';
  String? _education;
  String? _state;
  String? _district;
  String? _hospitalId;
  DateTime? _joiningDate;
  bool _isBusy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? '');
    _age = TextEditingController(text: e != null && e.age > 0 ? '${e.age}' : '');
    _mobile = TextEditingController(text: e?.mobileNumber ?? '');
    _ashaId = TextEditingController(
      text: e?.ashaIdNumber ?? 'ASHA-${DateTime.now().year}-${1000 + Random().nextInt(9000)}',
    );
    _address = TextEditingController(text: e?.address ?? '');
    _gender = e?.gender ?? 'Female';
    _education = e != null && AdminRepository.ashaEducationLevels.contains(e.education) ? e.education : null;
    _village = TextEditingController(text: e?.villageName ?? '');
    _state = (e?.state ?? '').isNotEmpty ? e!.state : null;
    _district = (e?.district ?? '').isNotEmpty ? e!.district : null;
    _hospitalId = e?.hospitalId;
    _joiningDate = e?.joiningDate ?? (e == null ? DateTime.now() : null);

    _name.addListener(_refreshPreview);
    _mobile.addListener(_refreshPreview);
  }

  void _refreshPreview() {
    if (!_isEdit) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _mobile.dispose();
    _ashaId.dispose();
    _address.dispose();
    _village.dispose();
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _joiningDate = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<AdminRepository>();
    final villageName = _village.text.trim();

    setState(() => _isBusy = true);
    try {
      if (_isEdit) {
        await repo.updateAshaWorker(widget.existing!.copyWith(
          fullName: _name.text.trim(),
          age: int.parse(_age.text.trim()),
          gender: _gender,
          mobileNumber: _mobile.text.trim(),
          villageId: AdminRepository.villageIdFor(villageName, district: _district!),
          villageName: villageName,
          district: _district,
          state: _state,
          hospitalId: _hospitalId,
          clearHospital: _hospitalId == null,
          ashaIdNumber: _ashaId.text.trim(),
          education: _education ?? '',
          joiningDate: _joiningDate,
          address: _address.text.trim(),
        ));
        if (!mounted) return;
        showAdminSnack(context, 'ASHA worker details updated');
        Navigator.pop(context);
      } else {
        final worker = await repo.addAshaWorker(
          fullName: _name.text.trim(),
          age: int.parse(_age.text.trim()),
          gender: _gender,
          mobileNumber: _mobile.text.trim(),
          villageName: villageName,
          district: _district!,
          state: _state!,
          hospitalId: _hospitalId,
          ashaIdNumber: _ashaId.text.trim(),
          education: _education ?? '',
          joiningDate: _joiningDate,
          address: _address.text.trim(),
        );
        if (!mounted) return;
        await showCredentialsDialog(
          context,
          title: 'ASHA worker added',
          name: worker.fullName,
          mobile: AdminRepository.formatMobile(worker.mobileNumber),
          password: worker.password,
          color: AdminColors.asha,
        );
        if (mounted) Navigator.pop(context, worker);
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
        title: Text(_isEdit ? 'Edit ASHA Worker' : 'Add ASHA Worker',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: Form(
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
                    decoration: adminInput('Full name *', icon: Icons.badge_outlined, hint: 'e.g. Shanti Devi'),
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the full name (min 3 letters)' : null,
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                          decoration: adminInput('Age *', icon: Icons.cake_outlined),
                          validator: (v) {
                            final age = int.tryParse((v ?? '').trim());
                            if (age == null) return 'Required';
                            if (age < 18 || age > 70) return '18 – 70';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AdminField(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          isExpanded: true,
                          decoration: adminInput('Gender *'),
                          items: const ['Female', 'Male', 'Other']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _gender = v ?? 'Female'),
                        ),
                      ),
                    ),
                  ],
                ),
                AdminField(
                  child: TextFormField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
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
                  child: DropdownButtonFormField<String>(
                    initialValue: _education,
                    isExpanded: true,
                    decoration: adminInput('Education', icon: Icons.school_outlined),
                    items: AdminRepository.ashaEducationLevels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _education = v),
                  ),
                ),
                AdminField(
                  child: TextFormField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: adminInput('Residential address', icon: Icons.home_outlined),
                  ),
                ),
              ],
            ),
            AdminFormSection(
              title: 'Work assignment',
              icon: Icons.work_outline_rounded,
              children: [
                AdminField(
                  child: TextFormField(
                    controller: _village,
                    textCapitalization: TextCapitalization.words,
                    decoration: adminInput('Village name *', icon: Icons.location_on_outlined, hint: 'e.g. Rampura'),
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the village this ASHA worker serves' : null,
                  ),
                ),
                AdminField(
                  child: AdminSearchSelectField(
                    label: 'State / UT *',
                    icon: Icons.map_outlined,
                    value: _state,
                    options: IndiaLocations.states,
                    validator: (_) => _state == null ? 'Select the state' : null,
                    onChanged: (v) => setState(() {
                      if (v != _state) _district = null;
                      _state = v;
                    }),
                  ),
                ),
                AdminField(
                  child: AdminSearchSelectField(
                    label: 'District *',
                    icon: Icons.location_city_outlined,
                    value: _district,
                    options: IndiaLocations.districtsOf(_state),
                    enabled: _state != null,
                    disabledHint: 'Select the state first',
                    allowCustom: true,
                    validator: (_) => _district == null ? 'Select the district' : null,
                    onChanged: (v) => setState(() => _district = v),
                  ),
                ),
                AdminField(
                  child: DropdownButtonFormField<String?>(
                    initialValue: selectedHospital,
                    isExpanded: true,
                    decoration: adminInput('Linked hospital / PHC', icon: Icons.local_hospital_outlined),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Not linked yet')),
                      ...hospitals.map((h) => DropdownMenuItem<String?>(
                            value: h.id,
                            child: Text('${h.name} • ${h.villageTown}', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setState(() => _hospitalId = v),
                  ),
                ),
                AdminField(
                  child: TextFormField(
                    controller: _ashaId,
                    textCapitalization: TextCapitalization.characters,
                    decoration: adminInput('ASHA ID number *', icon: Icons.numbers_rounded),
                    validator: (v) {
                      final id = (v ?? '').trim();
                      if (id.length < 4) return 'Enter the ASHA ID number';
                      final duplicate = repo.ashaWorkers.any((a) =>
                          a.id != widget.existing?.id && a.ashaIdNumber.toLowerCase() == id.toLowerCase());
                      return duplicate ? 'This ASHA ID is already in use' : null;
                    },
                  ),
                ),
                AdminField(
                  child: InkWell(
                    onTap: _pickJoiningDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: adminInput('Date of joining', icon: Icons.event_outlined),
                      child: Text(
                        _joiningDate != null ? DateFormat('dd MMM yyyy').format(_joiningDate!) : 'Select date',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.accentSurface,
                borderRadius: BorderRadius.circular(12),
              ),
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
                              ? 'Login password will be generated automatically: $previewPassword\nThe ASHA worker signs in with the mobile number and this password.'
                              : 'A simple login password will be generated automatically from the name and mobile number.',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF075985), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            AdminPrimaryButton(
              label: _isEdit ? 'Save Changes' : 'Add ASHA Worker',
              icon: _isEdit ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
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
