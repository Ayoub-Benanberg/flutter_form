import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/intervention_request.dart';
import '../services/api_service.dart';
import '../widgets/priority_selector.dart';
import '../widgets/dropdown_field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intervention Requests',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CombinedInterventionForm(),
    );
  }
}

class CombinedInterventionForm extends StatefulWidget {
  const CombinedInterventionForm({Key? key}) : super(key: key);

  @override
  _CombinedInterventionFormState createState() =>
      _CombinedInterventionFormState();
}

class _CombinedInterventionFormState extends State<CombinedInterventionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  // Form data from first form
  String? selectedMachineId;
  String? scannedCode;
  String? selectedProbNatureId;
  List<File> uploadedFiles = [];

  // Form data from second form
  String? _selectedMachineStatusId;
  String? _selectedPriorityId;
  String? _selectedCollaborateurId;

  // Dropdown data from first form
  List<Map<String, dynamic>> machines = [];
  List<Map<String, dynamic>> probNatures = [];

  // Dropdown data from second form
  final List<Map<String, dynamic>> _machineStatuses = [
    {'id': 'status1', 'status': 'État 1'},
    {'id': 'status2', 'status': 'État 2'},
    {'id': 'status3', 'status': 'État 3'},
  ];

  final List<Map<String, dynamic>> _collaborateurs = [
    {'id': 'collab1', 'name': 'Utilisateur 1'},
    {'id': 'collab2', 'name': 'Utilisateur 2'},
    {'id': 'collab3', 'name': 'Utilisateur 3'},
  ];

  // Standard values for this form
  final String _risqueId = 'standard_risk'; // from API
  final bool _closed = false;
  final String _defaultMachineId = 'default_machine';

  // Loading states
  bool isLoading = true;
  bool isSubmitting = false;

  // Audio recording
  final _audioRecorder = Record();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // For development purposes, let's create mock data
      machines = [
        {'id': 'machine1', 'label': 'Machine 1', 'code': 'M001'},
        {'id': 'machine2', 'label': 'Machine 2', 'code': 'M002'},
        {'id': 'machine3', 'label': 'Machine 3', 'code': 'M003'},
      ];

      probNatures = [
        {'id': 'nature1', 'nature': 'Gamme 1'},
        {'id': 'nature2', 'nature': 'Gamme 2'},
        {'id': 'nature3', 'nature': 'Gamme 3'},
      ];

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading form data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      final scanned = result.rawContent;

      // Check if the scanned code exists in your machines list
      final machineWithCode =
          machines.where((m) => m['code'] == scanned).toList();

      setState(() {
        if (machineWithCode.isNotEmpty) {
          scannedCode = scanned;
          // Also set the machine
          selectedMachineId = machineWithCode.first['id'];
        } else {
          // Handle invalid code
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Code QR non reconnu dans la liste des machines')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning code: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        uploadedFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        uploadedFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        uploadedFiles.addAll(result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList());
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(path: path);

        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording audio: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        if (path != null) {
          uploadedFiles.add(File(path));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Widget _buildFilePreview(File file) {
    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    IconData iconData;
    Color iconColor;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case 'mp4':
      case 'mov':
      case '3gp':
        iconData = Icons.videocam;
        iconColor = Colors.red;
        break;
      case 'mp3':
      case 'm4a':
      case 'wav':
        iconData = Icons.audiotrack;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.orange;
    }

    return ListTile(
      leading: Icon(iconData, color: iconColor),
      title: Text(fileName),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          setState(() {
            uploadedFiles.remove(file);
          });
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true;
      });

      try {
        // Create the intervention request object
        final intervention = InterventionRequest(
          machineId: selectedMachineId ?? _defaultMachineId,
          machineStatusId: _selectedMachineStatusId ?? '',
          probNatureId: selectedProbNatureId ?? '',
          description: _descriptionController.text,
          risqueId: _risqueId,
          priorityId: _selectedPriorityId ?? '1', // Default to priority 1
          referredCollaborateurId: _selectedCollaborateurId,
          closed: _closed,
        );

        // Send to API
        final result = await ApiService().createInterventionRequest(
          intervention,
          uploadedFiles,
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
          selectedMachineId = null;
          scannedCode = null;
          selectedProbNatureId = null;
          _selectedMachineStatusId = null;
          _selectedPriorityId = null;
          _selectedCollaborateurId = null;
          uploadedFiles = [];
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
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Créer une Demande'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une Demande'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIRST FORM ELEMENTS

                    // Actif (Machine)
                    const Text(
                      'Actif',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.settings),
                        hintText: 'Sélectionner',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: selectedMachineId,
                      onChanged: (value) {
                        setState(() {
                          selectedMachineId = value;
                          // Update scanned code when machine is selected
                          if (value != null) {
                            final selectedMachine =
                                machines.firstWhere((m) => m['id'] == value);
                            scannedCode = selectedMachine['code'];
                          }
                        });
                      },
                      items: machines.map((machine) {
                        return DropdownMenuItem<String>(
                          value: machine['id'].toString(),
                          child: Text(machine['label']),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner une machine';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Code
                    const Text(
                      'Code',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.qr_code),
                              hintText: 'Sélectionner',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: scannedCode != null &&
                                    machines
                                        .any((m) => m['code'] == scannedCode)
                                ? scannedCode
                                : null,
                            onChanged: (value) {
                              setState(() {
                                scannedCode = value;
                                // Update selected machine when code is selected
                                if (value != null) {
                                  final machineWithCode = machines
                                      .firstWhere((m) => m['code'] == value);
                                  selectedMachineId = machineWithCode['id'];
                                }
                              });
                            },
                            items: machines.map((machine) {
                              return DropdownMenuItem<String>(
                                value: machine['code'],
                                child: Text(machine['code']),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _scanQRCode,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Type (Problem Nature)
                    const Text(
                      'Type',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.build),
                        hintText: 'Sélectionner',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: selectedProbNatureId,
                      onChanged: (value) {
                        setState(() {
                          selectedProbNatureId = value;
                          // Also update the same value in the second part of the form
                          selectedProbNatureId = value;
                        });
                      },
                      items: probNatures.map((nature) {
                        return DropdownMenuItem<String>(
                          value: nature['id'].toString(),
                          child: Text(nature['nature']),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un type de problème';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // MEDIA UPLOAD SECTION

                    // Media upload buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Audio button
                        ElevatedButton.icon(
                          onPressed:
                              _isRecording ? _stopRecording : _startRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop' : 'Audio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),

                        // Video button
                        ElevatedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Video'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),

                        // Photo button
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Photo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // File button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Uploaded files list
                    if (uploadedFiles.isNotEmpty) ...[
                      const Text(
                        'Fichiers attachés',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...uploadedFiles.map(_buildFilePreview).toList(),
                      const SizedBox(height: 16),
                    ],

                    // SECOND FORM ELEMENTS

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
                        border: OutlineInputBorder(),
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
                      icon: Image.asset('assets/icons/state_icon.png',
                          width: 24, height: 24),
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
                      items: probNatures.map((nature) {
                        return DropdownMenuItem(
                          value: nature['id'],
                          child: Text(nature['nature']),
                        );
                      }).toList(),
                      hint: 'Sélectionner',
                      value: selectedProbNatureId,
                      onChanged: (value) {
                        setState(() {
                          selectedProbNatureId = value as String;
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
                      icon: Image.asset('assets/icons/user_icon.png',
                          width: 24, height: 24),
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
                          onPressed: isSubmitting ? null : _submitForm,
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
