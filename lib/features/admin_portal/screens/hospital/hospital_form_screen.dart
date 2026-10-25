import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/admin_models.dart';
import '../../../../core/services/admin_repository.dart';
import '../../widgets/admin_ui.dart';

class HospitalFormScreen extends StatefulWidget {
  final HospitalModel? existing;

  const HospitalFormScreen({super.key, this.existing});

  @override
  State<HospitalFormScreen> createState() => _HospitalFormScreenState();
}

class _HospitalFormScreenState extends State<HospitalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _villageTown;
  late final TextEditingController _district;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _contact;
  late final TextEditingController _totalBeds;
  late final TextEditingController _availableBeds;
  late final TextEditingController _icuBeds;

  String? _type;
  bool _hasEmergency = false;
  bool _hasMaternity = false;
  bool _isBusy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _villageTown = TextEditingController(text: e?.villageTown ?? '');
    _district = TextEditingController(text: e?.district ?? '');
    _state = TextEditingController(text: e?.state ?? '');
    _pincode = TextEditingController(text: e?.pincode ?? '');
    _contact = TextEditingController(text: e?.contactNumber ?? '');
    _totalBeds = TextEditingController(text: e != null ? '${e.totalBeds}' : '');
    _availableBeds = TextEditingController(text: e != null ? '${e.availableBeds}' : '');
    _icuBeds = TextEditingController(text: e != null ? '${e.icuBeds}' : '0');
    _type = e != null && AdminRepository.hospitalTypes.contains(e.type) ? e.type : null;
    _hasEmergency = e?.hasEmergency ?? false;
    _hasMaternity = e?.hasMaternityWard ?? false;
  }

  void _fillSampleHospitalData() {
    final rand = Random();
    final names = [
      'Nelamangala Taluk General Hospital',
      'Community Health Centre (CHC) Anandpur',
      'Varanasi Rural Sub-District Hospital',
      'Primary Health Centre (PHC) Khed',
      'District Civil Hospital Shivpur',
    ];
    final selectedName = names[rand.nextInt(names.length)];
    final total = 60 + rand.nextInt(140);
    final avail = 12 + rand.nextInt(35);
    final icu = 4 + rand.nextInt(12);

    setState(() {
      _name.text = selectedName;
      _type = AdminRepository.hospitalTypes.contains('Sub-District Hospital')
          ? 'Sub-District Hospital'
          : AdminRepository.hospitalTypes.first;
      _address.text = 'Near Main Bus Stand, Station Road';
      _villageTown.text = 'Nelamangala';
      _district.text = 'Bengaluru Rural';
      _state.text = 'Karnataka';
      _pincode.text = '562123';
      _contact.text = '9845${100000 + rand.nextInt(899999)}';
      _totalBeds.text = '$total';
      _availableBeds.text = '$avail';
      _icuBeds.text = '$icu';
      _hasEmergency = true;
      _hasMaternity = true;
    });

    showAdminSnack(context, '⚡ Sample hospital details filled.');
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _address,
      _villageTown,
      _district,
      _state,
      _pincode,
      _contact,
      _totalBeds,
      _availableBeds,
      _icuBeds,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<AdminRepository>();
    setState(() => _isBusy = true);
    try {
      if (_isEdit) {
        await repo.updateHospital(widget.existing!.copyWith(
          name: _name.text.trim(),
          type: _type,
          address: _address.text.trim(),
          villageTown: _villageTown.text.trim(),
          district: _district.text.trim(),
          state: _state.text.trim(),
          pincode: _pincode.text.trim(),
          contactNumber: _contact.text.trim(),
          totalBeds: _int(_totalBeds),
          availableBeds: _int(_availableBeds),
          icuBeds: _int(_icuBeds),
          hasEmergency: _hasEmergency,
          hasMaternityWard: _hasMaternity,
        ));
        if (!mounted) return;
        showAdminSnack(context, 'Hospital details updated');
      } else {
        await repo.addHospital(
          name: _name.text.trim(),
          type: _type ?? AdminRepository.hospitalTypes.first,
          address: _address.text.trim(),
          villageTown: _villageTown.text.trim(),
          district: _district.text.trim(),
          state: _state.text.trim(),
          pincode: _pincode.text.trim(),
          contactNumber: _contact.text.trim(),
          totalBeds: _int(_totalBeds),
          availableBeds: _int(_availableBeds),
          icuBeds: _int(_icuBeds),
          hasEmergency: _hasEmergency,
          hasMaternityWard: _hasMaternity,
        );
        if (!mounted) return;
        showAdminSnack(context, 'Hospital added. You can now link doctors and ASHA workers to it.');
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showAdminSnack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String? _required(String? v, String label) => (v ?? '').trim().isEmpty ? 'Enter $label' : null;

  Widget _number(TextEditingController c, String label, IconData icon, {String? Function(String?)? validator}) {
    return AdminField(
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        decoration: adminInput(label, icon: icon),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B6634),
        foregroundColor: const Color(0xFFFBF4E8),
        title: Text(_isEdit ? 'Edit Hospital' : 'Add Hospital',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AdminColors.hospital,
              backgroundColor: AdminColors.hospitalSurface,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text('Sample Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _fillSampleHospitalData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminFormSection(
              title: 'Hospital information',
              icon: Icons.local_hospital_outlined,
              children: [
                AdminField(
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: adminInput('Hospital name *',
                        icon: Icons.apartment_rounded, hint: 'e.g. Primary Health Centre, Khed'),
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the hospital name' : null,
                  ),
                ),
                AdminField(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    isExpanded: true,
                    decoration: adminInput('Facility type *', icon: Icons.category_outlined),
                    items: AdminRepository.hospitalTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    validator: (v) => v == null ? 'Select the facility type' : null,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
                AdminField(
                  child: TextFormField(
                    controller: _contact,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 +\-]')), LengthLimitingTextInputFormatter(15)],
                    decoration: adminInput('Contact number *', icon: Icons.call_outlined),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      return digits.length < 10 ? 'Enter a valid phone number (10+ digits)' : null;
                    },
                  ),
                ),
              ],
            ),
            AdminFormSection(
              title: 'Address',
              icon: Icons.location_on_outlined,
              children: [
                AdminField(
                  child: TextFormField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: adminInput('Street address *', icon: Icons.signpost_outlined),
                    validator: (v) => _required(v, 'the street address'),
                  ),
                ),
                AdminField(
                  child: TextFormField(
                    controller: _villageTown,
                    textCapitalization: TextCapitalization.words,
                    decoration: adminInput('Village / Town *', icon: Icons.holiday_village_outlined),
                    validator: (v) => _required(v, 'the village or town'),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(
                        child: TextFormField(
                          controller: _district,
                          textCapitalization: TextCapitalization.words,
                          decoration: adminInput('District *'),
                          validator: (v) => _required(v, 'district'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AdminField(
                        child: TextFormField(
                          controller: _pincode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          decoration: adminInput('PIN code *'),
                          validator: (v) => (v ?? '').trim().length != 6 ? '6 digits' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                AdminField(
                  child: TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    decoration: adminInput('State *', icon: Icons.map_outlined),
                    validator: (v) => _required(v, 'state'),
                  ),
                ),
              ],
            ),
            AdminFormSection(
              title: 'Beds & facilities',
              icon: Icons.bed_outlined,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _number(_totalBeds, 'Total beds *', Icons.bed_rounded, validator: (v) {
                        return int.tryParse((v ?? '').trim()) == null ? 'Required' : null;
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _number(_availableBeds, 'Available *', Icons.event_available_rounded, validator: (v) {
                        final available = int.tryParse((v ?? '').trim());
                        if (available == null) return 'Required';
                        if (available > _int(_totalBeds)) return 'More than total';
                        return null;
                      }),
                    ),
                  ],
                ),
                _number(_icuBeds, 'ICU beds', Icons.monitor_heart_outlined, validator: (v) {
                  final icu = int.tryParse((v ?? '').trim()) ?? 0;
                  return icu > _int(_totalBeds) ? 'Cannot exceed total beds' : null;
                }),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _hasEmergency,
                  activeColor: AdminColors.hospital,
                  title: const Text('24×7 Emergency services',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  onChanged: (v) => setState(() => _hasEmergency = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _hasMaternity,
                  activeColor: AdminColors.hospital,
                  title: const Text('Maternity / Labour ward',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  onChanged: (v) => setState(() => _hasMaternity = v),
                ),
              ],
            ),
            AdminPrimaryButton(
              label: _isEdit ? 'Save Changes' : 'Add Hospital',
              icon: _isEdit ? Icons.check_rounded : Icons.add_business_rounded,
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
