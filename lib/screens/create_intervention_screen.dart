import 'package:flutter/material.dart';
import '../models/intervention_request.dart';
import '../services/api_service.dart';
import '../widgets/priority_selector.dart';
import '../widgets/dropdown_field.dart';

class CreateInterventionScreen extends StatefulWidget {
  const CreateInterventionScreen({Key? key}) : super(key: key);

  @override
  _CreateInterventionScreenState createState() => _CreateInterventionScreenState();
}

class _CreateInterventionScreenState extends State<CreateInterventionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  // Selection values
  String? _selectedMachineStatusId;
  String? _selectedProbNatureId;
  String? _selectedRisqueId;
  String? _selectedPriorityId;
  String? _selectedCollaborateurId;
  
  bool _isLoading = false;

  // Example data for dropdowns - In a real app, these would come from your API
  final List<Map<String, dynamic>> _machineStatuses = [
    {'id': 'status1', 'status': 'État 1'},
    {'id': 'status2', 'status': 'État 2'},
    {'id': 'status3', 'status': 'État 3'},
  ];

  final List<Map<String, dynamic>> _probNatures = [
    {'id': 'nature1', 'nature': 'Gamme 1'},
    {'id': 'nature2', 'nature': 'Gamme 2'},
    {'id': 'nature3', 'nature': 'Gamme 3'},
  ];

  final List<Map<String, dynamic>> _collaborateurs = [
    {'id': 'collab1', 'name': 'Utilisateur 1'},
    {'id': 'collab2', 'name': 'Utilisateur 2'},
    {'id': 'collab3', 'name': 'Utilisateur 3'},
  ];

  // Standard values for this form
  final String _risqueId = 'standard_risk'; // You would get this from API
  final bool _closed = false;
  // We'll use a default machine ID since it's required by the backend but not shown in UI
  final String _defaultMachineId = 'default_machine';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create the intervention request object
        final intervention = InterventionRequest(
          machineId: _defaultMachineId, // Use default machine ID
          machineStatusId: _selectedMachineStatusId ?? '',
          probNatureId: _selectedProbNatureId ?? '',
          description: _descriptionController.text,
          risqueId: _risqueId,
          priorityId: _selectedPriorityId ?? '1', // Default to priority 1
          referredCollaborateurId: _selectedCollaborateurId,
          closed: _closed,
        );

        // Send to API
        final result = await ApiService().createInterventionRequest(
          intervention,
          [], // Empty list for documents since we've removed the functionality
        );

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande d\'intervention créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _descriptionController.clear();
        setState(() {
          _selectedMachineStatusId = null;
          _selectedProbNatureId = null;
          _selectedPriorityId = null;
          _selectedCollaborateurId = null;
        });
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Demande d\'Intervention'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description field
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Description',
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Priority selector
                    const Text(
                      'Priorité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrioritySelector(
                      onChanged: (priorityId) {
                        setState(() {
                          _selectedPriorityId = priorityId;
                        });
                      },
                      selectedPriorityId: _selectedPriorityId,
                    ),
                    const SizedBox(height: 24),

                    // Machine state dropdown
                    const Text(
                      'Etat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownField(
                      icon: Image.asset('assets/icons/state_icon.png', width: 24, height: 24),
                      items: _machineStatuses.map((status) {
                        return DropdownMenuItem(
                          value: status['id'],
                          child: Text(status['status']),
                        );
                      }).toList(),
                      hint: 'Sélectionner',
                      value: _selectedMachineStatusId,
                      onChanged: (value) {
                        setState(() {
                          _selectedMachineStatusId = value as String;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un état';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Problem nature dropdown
                    const Text(
                      'Gamme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownField(
                      icon: Image.asset('assets/icons/gamme_icon.png', width: 24, height: 24),
                      items: _probNatures.map((nature) {
                        return DropdownMenuItem(
                          value: nature['id'],
                          child: Text(nature['nature']),
                        );
                      }).toList(),
                      hint: 'Sélectionner',
                      value: _selectedProbNatureId,
                      onChanged: (value) {
                        setState(() {
                          _selectedProbNatureId = value as String;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner une gamme';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Collaborateur dropdown
                    const Text(
                      'Utilisateur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownField(
                      icon: Image.asset('assets/icons/user_icon.png', width: 24, height: 24),
                      items: _collaborateurs.map((collab) {
                        return DropdownMenuItem(
                          value: collab['id'],
                          child: Text(collab['name']),
                        );
                      }).toList(),
                      hint: 'Sélectionner',
                      value: _selectedCollaborateurId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCollaborateurId = value as String;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un utilisateur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit button - centered
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submitForm,
                          child: const Text(
                            'Créer',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}