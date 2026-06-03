import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({Key? key}) : super(key: key);

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 70, // compress to save bandwidth
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_imageFile == null) return;
    
    setState(() => _isLoading = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = "data:image/jpeg;base64," + base64Encode(bytes);
      
      final res = await ApiService.uploadKycDocument(base64Image);
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ID Card uploaded successfully! It is now pending review.')),
          );
          Navigator.pop(context, true); // Return true to signal success
        }
      } else {
        throw Exception(res['error'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload ID Card'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please upload a clear picture of your National ID, Passport, or Driver\'s License.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        // Note: Using FutureBuilder or dart:io File isn't needed if we just read bytes, but for XFile we can use FutureBuilder to load bytes in memory for Web/Emulator compatibility
                        child: FutureBuilder<List<int>>(
                          future: _imageFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                Uint8List.fromList(snapshot.data!),
                                fit: BoxFit.cover,
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 48, color: AppTheme.primaryColor),
                          const SizedBox(height: 8),
                          const Text('Tap to select image from gallery', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Or Take a Photo'),
            ),
            
            const Spacer(),
            
            CustomButton(
              text: 'Submit ID Card',
              isLoading: _isLoading,
              onPressed: _imageFile == null ? null : _uploadDocument,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';
