import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final ImagePicker _picker = ImagePicker();


  static const String _imgBbApiKey = '34a36f6e80b27beec3c23d53d3cb941e';


  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      rethrow;
    }
    return null;
  }


  Future<String?> uploadImage(File file, String folder) async {
    try {
      final List<int> imageBytes = await file.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _imgBbApiKey,
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['url'] != null) {
          final imageUrl = data['data']['url'] as String;
          debugPrint("Uploaded image URL: $imageUrl");
          return imageUrl;
        }
      }
      throw Exception("Server returned code ${response.statusCode}: ${response.body}");
    } catch (e) {
      debugPrint("Error uploading image: $e");
      rethrow;
    }
  }
}
