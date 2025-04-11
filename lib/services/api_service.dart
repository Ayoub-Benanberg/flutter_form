import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/intervention_request.dart';

class ApiService {
  
  final String baseUrl = 'https://your-backend-url.com/api';

  // Get authentication token
  Future<String> _getToken() async {
    // Replace with authentication
    return 'your_auth_token';
  }

  // Create intervention request with optional file upload
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
    });

    // Add form fields
    request.fields.addAll(intervention.toJson().map(
          (key, value) => MapEntry(key, value.toString()),
        ));

    // Add files if any
    if (documents.isNotEmpty) {
      for (var document in documents) {
        final fileName = document.path.split('/').last;
        final mimeType = _getMimeType(fileName);
        
        request.files.add(await http.MultipartFile.fromPath(
          'documents[]',
          document.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
    }

    // Send request
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to create intervention request: ${responseBody}');
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
}