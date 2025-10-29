import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/cloudinary_config.dart';

class CloudinaryUploadResult {
  final String url;
  final String deleteToken;

  CloudinaryUploadResult({required this.url, required this.deleteToken});
}

class CloudinaryService {
  /// Upload image to Cloudinary
  /// Returns the secure URL and delete token of the uploaded image
  static Future<CloudinaryUploadResult?> uploadImage(File imageFile) async {
    print('═══════════════════════════════════════════════════');
    print('🚀 STARTING CLOUDINARY UPLOAD');
    print('═══════════════════════════════════════════════════');

    try {
      print('📁 File path: ${imageFile.path}');
      print('📊 File size: ${await imageFile.length()} bytes');
      print('☁️  Cloud name: ${CloudinaryConfig.cloudName}');
      print('🔧 Upload preset: ${CloudinaryConfig.uploadPreset}');
      print('📂 Folder: ${CloudinaryConfig.uploadFolder}');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );
      print('🌐 Upload URL: $url');

      final request = http.MultipartRequest('POST', url);

      // Add upload preset
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      print('✅ Added upload_preset');

      // Add folder (optional)
      if (CloudinaryConfig.uploadFolder.isNotEmpty) {
        request.fields['folder'] = CloudinaryConfig.uploadFolder;
        print('✅ Added folder');
      }

      print('📝 Request fields: ${request.fields}');

      // Note: For unsigned uploads, return_delete_token must be enabled
      // in the upload preset settings on Cloudinary dashboard, not here!

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      print('✅ Added image file to request');

      // Send the request
      print('📤 Sending request to Cloudinary...');
      final response = await request.send();
      print('📥 Response received! Status: ${response.statusCode}');

      // Get response body
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      print('📄 Response length: ${responseString.length} characters');

      if (response.statusCode == 200) {
        print('✅ UPLOAD SUCCESSFUL!');
        final jsonMap = json.decode(responseString);

        print('───────────────────────────────────────────────────');
        print('📦 Response data:');
        jsonMap.forEach((key, value) {
          print('   $key: $value');
        });
        print('───────────────────────────────────────────────────');

        // Return both the secure URL and delete token
        final secureUrl = jsonMap['secure_url'] as String?;
        final deleteToken = jsonMap['delete_token'] as String?;
        final publicId = jsonMap['public_id'] as String?;

        print('🔗 Secure URL: $secureUrl');
        print('🔑 Delete Token: $deleteToken');
        print('🆔 Public ID: $publicId');

        if (secureUrl != null) {
          if (deleteToken != null) {
            print('✅ Got delete token - can delete images!');
          } else {
            print('⚠️  No delete token - check preset settings!');
            print('   Go to: https://cloudinary.com/console/settings/upload');
            print('   Enable "Return delete token" in your preset');
          }

          return CloudinaryUploadResult(
            url: secureUrl,
            deleteToken: deleteToken ?? '',
          );
        }

        print('❌ Missing secure_url in response!');
        return null;
      } else {
        print('❌ UPLOAD FAILED!');
        print('Status code: ${response.statusCode}');
        print('Response body: $responseString');

        // Try to parse error
        try {
          final errorJson = json.decode(responseString);
          print('───────────────────────────────────────────────────');
          print('🔴 Error details:');
          if (errorJson['error'] != null) {
            if (errorJson['error'] is Map) {
              errorJson['error'].forEach((key, value) {
                print('   $key: $value');
              });
            } else {
              print('   ${errorJson['error']}');
            }
          }
          print('───────────────────────────────────────────────────');
        } catch (e) {
          print('Could not parse error as JSON');
        }

        return null;
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION OCCURRED!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return null;
    } finally {
      print('═══════════════════════════════════════════════════');
      print('🏁 UPLOAD PROCESS COMPLETED');
      print('═══════════════════════════════════════════════════\n');
    }
  }

  /// Delete image from Cloudinary using delete token
  /// This method uses the delete token returned during upload
  static Future<bool> deleteImageWithToken(String deleteToken) async {
    print('═══════════════════════════════════════════════════');
    print('🗑️  STARTING CLOUDINARY DELETE');
    print('═══════════════════════════════════════════════════');

    if (deleteToken.isEmpty) {
      print('⚠️  No delete token provided - skipping deletion');
      print('═══════════════════════════════════════════════════\n');
      return true;
    }

    try {
      print('🔑 Delete token: $deleteToken');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/delete_by_token',
      );
      print('🌐 Delete URL: $url');

      print('📤 Sending delete request...');
      final response = await http.post(url, body: {'token': deleteToken});
      print('📥 Response received! Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ IMAGE DELETED SUCCESSFULLY!');
        print('═══════════════════════════════════════════════════\n');
        return true;
      } else {
        print('❌ DELETE FAILED!');
        print('Status: ${response.statusCode}');
        try {
          final errorJson = json.decode(response.body);
          print('Error details: $errorJson');
        } catch (e) {
          // Response wasn't JSON
        }
        print('═══════════════════════════════════════════════════\n');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION OCCURRED!');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════\n');
      return false;
    }
  }
}
