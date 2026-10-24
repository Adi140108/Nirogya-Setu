import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/admin_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/health_repository.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../asha_portal/widgets/issue_map.dart';

/// Connects the signed-in user to cross-device notifications and asks for the
/// notification and location permissions once the app is on screen.
class NotificationSessionBinder extends StatefulWidget {
  final Widget child;

  const NotificationSessionBinder({super.key, required this.child});

  @override
  State<NotificationSessionBinder> createState() => _NotificationSessionBinderState();
}

class _NotificationSessionBinderState extends State<NotificationSessionBinder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().requestPermissions();
      await LocationService.ensurePermission();
    });
  }

  /// Every id notifications for this user may be addressed to.
  List<String> _recipientIds(AppUser? user, AdminRepository admin, HealthRepository repo) {
    if (user == null) return const [];
    final ids = <String>{user.uid};
    switch (user.role) {
      case UserRole.asha:
        ids.add(resolveAshaId(user, admin));
        break;
      case UserRole.patient:
        // Family members share one phone, so include everyone registered on it.
        final phone = AdminRepository.normalizeMobile(user.phoneNumber ?? '');
        for (final p in repo.patients) {
          final samePhone = phone.length == 10 && AdminRepository.normalizeMobile(p.contactNumber) == phone;
          if (p.id == user.uid || samePhone) ids.add(p.id);
        }
        for (final m in repo.getFamilyMembersForPatient(user.uid)) {
          ids.add(m.id);
        }
        break;
      case UserRole.doctor:
        break;
    }
    return ids.toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final admin = context.watch<AdminRepository>();
    final repo = context.watch<HealthRepository>();
    final ids = auth.isAuthenticated ? _recipientIds(auth.currentUser, admin, repo) : const <String>[];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ids.isEmpty) {
        NotificationService().stopListening();
      } else {
        NotificationService().startListening(ids);
      }
    });
    return widget.child;
  }
}
