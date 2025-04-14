// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/intervention_request.dart';

class ApiService {
  // Update this with your actual backend URL
  final String baseUrl = 'https://your-backend-api.com/api';

  // Get authentication token - this should be updated with your actual auth logic
  Future<String> _getToken() async {
    // Implement your authentication logic here
    // This could fetch from secure storage, login, etc.
    return 'your_auth_token';
  }

  // Create intervention request with file uploads
  Future<dynamic> createInterventionRequest(
      InterventionRequest intervention, List<File> documents) async {

    final token = await _getToken();
    final url = Uri.parse('$baseUrl/operator/intervention-requests');

    // Create multipart request
    var request = http.MultipartRequest('POST', url);

    // Add auth header
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'multipart/form-data',
    });

    // Add form fields - ensure field names match the PHP controller expectations
    request.fields.addAll(intervention.toJson().map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
    ));

    // Add files if any
    if (documents.isNotEmpty) {
      for (var document in documents) {
        final fileName = document.path.split('/').last;
        final mimeType = _getMimeType(fileName);

        // Make sure the field name matches what the backend expects
        request.files.add(await http.MultipartFile.fromPath(
          'documents[]', // This matches your PHP controller
          document.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
    }

    try {
      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
        throw Exception('Failed to create intervention request: ${responseBody}');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }


  // Helper to determine MIME type from filename
  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/m4a';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case '3gp':
        return 'video/3gpp';
      default:
        return 'application/octet-stream';
    }
  }

  // Get intervention list
  Future<Map<String, dynamic>> getInterventionList() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/operator/interventions');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load interventions');
    }
  }

  // Get intervention details
  Future<dynamic> getInterventionDetails(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/operator/intervention-requests/$id');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load intervention details');
    }
  }

  // Mark intervention as fixed
  Future<dynamic> markAsFixed(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/operator/intervention-requests/$id/fixed');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to mark intervention as fixed');
    }
  }

  // Mark intervention as rejected
  Future<dynamic> markAsRejected(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/operator/intervention-requests/$id/rejected');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to mark intervention as rejected');
    }
  }
  
  // Get machines list
  // In ApiService
  Future<List<Map<String, dynamic>>> getMachines() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/machines');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to load machines');
      }
    } catch (e) {
      // Return mock data for development/fallback
      return [
        {'id': 'machine1', 'label': 'Machine 1', 'code': 'M001'},
        {'id': 'machine2', 'label': 'Machine 2', 'code': 'M002'},
        {'id': 'machine3', 'label': 'Machine 3', 'code': 'M003'},
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getProblemNatures() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/problem-natures');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to load problem natures');
      }
    } catch (e) {
      // Fallback mock data
      return [
        {'id': 'nature1', 'nature': 'Gamme 1'},
        {'id': 'nature2', 'nature': 'Gamme 2'},
        {'id': 'nature3', 'nature': 'Gamme 3'},
      ];
    }
  }
  
  // Download= document
  Future<File?> downloadDocument(String documentUrl, String fileName) async {
    final token = await _getToken();
    final url = Uri.parse(documentUrl);
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Get temporary directory
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        
        // Write file
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('Failed to download document');
      }
    } catch (e) {
      print('Error downloading document: $e');
      return null;
    }
  }
}