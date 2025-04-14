// lib/models/intervention_request.dart
class InterventionRequest {
  final String machineId;
  final String machineStatusId;
  final String probNatureId;
  final String description;
  final String risqueId;
  final String priorityId;
  final String? referredCollaborateurId;
  final bool closed;

  InterventionRequest({
    required this.machineId,
    required this.machineStatusId,
    required this.probNatureId,
    required this.description,
    required this.risqueId,
    required this.priorityId,
    this.referredCollaborateurId,
    required this.closed,
  });

  Map<String, dynamic> toJson() {
    return {
      'machine_id': machineId,
      'machine_status_id': machineStatusId,
      'prob_nature_id': probNatureId,
      'description': description,
      'risque_id': risqueId,
      'priority_id': priorityId,
      'referred_collaborateur_id': referredCollaborateurId,
      'closed': closed ? 1 : 0, // Convert boolean to 1/0 for PHP
    };
  }
}