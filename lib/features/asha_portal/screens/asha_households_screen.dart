import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/health_repository.dart';
import '../../shared/widgets/network_banner.dart';
import '../../shared/widgets/ui.dart';
import 'register_villager_screen.dart';
import 'patient_detail_screen.dart';

/// Icon chip / avatar size, matching the shared ActionTile chip (44).
const double _chipSize = AppSizes.minTouch - AppSpacing.xs;

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
      appBar: widget.isEmbedded ? null : AppBar(title: const Text('Households')),
      body: Column(
        children: [
          const NetworkBanner(),
          _buildSearchHeader(context, householdsMap.length),
          Expanded(
            child: filteredHouseholds.isEmpty
                ? SingleChildScrollView(
                    child: householdsMap.isEmpty
                        ? const EmptyState(
                            icon: Icons.home_outlined,
                            title: 'No households yet',
                            message: 'Tap "Add household" to register a family.',
                          )
                        : const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matching households',
                            message: 'Try a different name, phone number, village or household ID.',
                          ),
                  )
                : ListView.separated(
                    // Extra bottom space so the last card is not hidden behind the button.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl * 3,
                    ),
                    itemCount: filteredHouseholds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final entry = filteredHouseholds[index];
                      return _HouseholdCard(
                        householdId: entry.key,
                        members: entry.value,
                        onOpenMember: (m) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientDetailScreen(patientId: m.id),
                            ),
                          );
                        },
                        onAddMember: () =>
                            _openAddMemberDialog(context, repo, entry.key, entry.value.first),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_home_rounded),
        label: const Text('Add household'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterVillagerScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, int familyCount) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: AppSpacing.screen,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Village households', style: textTheme.titleMedium)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                familyCount == 1 ? '1 family' : '$familyCount families',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search name, phone, village or ID',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ],
      ),
    );
  }

  void _openAddMemberDialog(BuildContext context, HealthRepository repo, String householdId, PatientModel head) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: head.contactNumber);
    String gender = 'Female';
    String relationship = 'Wife';
    bool isPregnant = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final textTheme = Theme.of(context).textTheme;
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Add family member', style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Household $householdId · ${head.villageName} · Head: ${head.fullName}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              helperText: 'In years',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: gender,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Gender'),
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
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: relationship,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Relation to head of family'),
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
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+91 98765 00000',
                      ),
                    ),
                    if (gender == 'Female') ...[
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('She is pregnant'),
                        subtitle: const Text('Adds her to pregnancy care (ANC) visits'),
                        value: isPregnant,
                        onChanged: (v) => setSheetState(() => isPregnant = v ?? false),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Save member',
                      icon: Icons.check_rounded,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final age = int.tryParse(ageCtrl.text.trim()) ?? 0;
                        final phone = phoneCtrl.text.trim();

                        if (name.isEmpty || age <= 0 || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a name, age and phone number.')),
                          );
                          return;
                        }

                        // Duplicate protection check
                        final duplicate = repo.findDuplicateCitizen(fullName: name, contactNumber: phone);
                        if (duplicate != null) {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              icon: const Icon(Icons.warning_amber_rounded, color: AppColors.secondary),
                              title: const Text('Already registered'),
                              content: Text(
                                '${duplicate.fullName} is already registered with phone ${duplicate.contactNumber} '
                                'in ${duplicate.villageName}. The same person cannot be added twice.',
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
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${newMember.fullName} added to household $householdId.'),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Add family member failed: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not save member. Please try again.')),
                            );
                          }
                        }
                      },
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

/// One household: header (ID, size, village), tappable members, add-member action.
class _HouseholdCard extends StatelessWidget {
  final String householdId;
  final List<PatientModel> members;
  final ValueChanged<PatientModel> onOpenMember;
  final VoidCallback onAddMember;

  const _HouseholdCard({
    required this.householdId,
    required this.members,
    required this.onOpenMember,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final head = members.first;
    final memberCount = members.length == 1 ? '1 member' : '${members.length} members';

    return InfoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: _chipSize,
                  height: _chipSize,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Household $householdId', style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text('$memberCount · ${head.villageName}', style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ...members.map((m) => _MemberRow(member: m, onTap: () => onOpenMember(m))),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add family member'),
              onPressed: onAddMember,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single family member row. Opens the patient's detail screen.
class _MemberRow extends StatelessWidget {
  final PatientModel member;
  final VoidCallback onTap;

  const _MemberRow({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final m = member;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              InitialAvatar(m.fullName, size: _chipSize),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m.fullName} (${m.displayRelationship})', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      '${m.age} yrs · ${m.gender} · ${m.contactNumber}',
                      style: textTheme.bodySmall,
                    ),
                    if (m.isPregnant) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const StatusTag('Pregnant', icon: Icons.pregnant_woman_rounded),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
