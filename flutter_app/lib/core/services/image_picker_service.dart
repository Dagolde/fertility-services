import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Show dialog to choose between camera and gallery for profile picture
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result == null) return null;

    if (result == 'camera') {
      return await _pickImageFromCamera();
    } else if (result == 'gallery') {
      return await _pickImageFromGallery();
    }

    return null;
  }

  /// Pick image from camera
  static Future<File?> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  static Future<File?> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick multiple files for medical records
  static Future<List<File>?> pickMedicalRecords() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error picking medical records: $e');
      return null;
    }
  }

  /// Pick single file for medical record
  static Future<File?> pickSingleMedicalRecord() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking medical record: $e');
      return null;
    }
  }

  /// Show dialog to upload medical records
  static Future<List<File>?> showMedicalRecordDialog(BuildContext context) async {
    return await showDialog<List<File>?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Medical Records'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please upload your medical records, certifications, or licenses.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supported formats: PDF, DOC, DOCX, JPG, PNG',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final files = await pickMedicalRecords();
                Navigator.pop(context, files);
              },
              child: const Text('Select Files'),
            ),
          ],
        );
      },
    );
  }
}
