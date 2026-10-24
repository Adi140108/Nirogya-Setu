import 'dart:convert';
import '../models/patient_model.dart';

/// Citizen QR code: identifies the citizen's account so an ASHA worker or
/// doctor can open it by scanning instead of searching by name/phone.
///
/// Format (kept short so even the small QR on the card scans reliably):
///   AAROGYASETU|P|<patientId>|<abhaNumber>
class PatientQr {
  static const String _prefix = 'AAROGYASETU';

  static String encode(PatientModel patient) => '$_prefix|P|${patient.id}|${patient.computedAbhaNumber}';

  /// Parses a scanned value. Also understands the older JSON card payload
  /// (which only carried the ABHA number). Returns null for unrelated codes.
  static ({String? patientId, String? abhaNumber})? decode(String raw) {
    final value = raw.trim();
    if (value.startsWith('$_prefix|')) {
      final parts = value.split('|');
      if (parts.length >= 3 && parts[1] == 'P' && parts[2].isNotEmpty) {
        return (patientId: parts[2], abhaNumber: parts.length > 3 ? parts[3] : null);
      }
      return null;
    }
    if (value.startsWith('{')) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        final id = map['id']?.toString();
        final abha = map['abha']?.toString();
        if ((id ?? '').isNotEmpty || (abha ?? '').isNotEmpty) {
          return (patientId: id, abhaNumber: abha);
        }
      } catch (_) {}
    }
    return null;
  }
}
