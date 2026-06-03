import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_button.dart';

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
          AppSnackBar.showSuccess(context, 'ID Card uploaded successfully! It is now pending review.');
          Navigator.pop(context, true); // Return true to signal success
        }
      } else {
        throw Exception(res['error'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Upload failed: $e');
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
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Please upload a clear picture of your National ID, Passport, or Driver\'s License.',
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.buttonColor.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
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
                          const Icon(Icons.upload_file, size: 48, color: AppColors.buttonColor),
                          const SizedBox(height: 8),
                          Text('Tap to select image from gallery', style: TextStyle(color: Theme.of(context).hintColor)),
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
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Submit ID Card',
                    onPressed: _imageFile == null ? () {} : _uploadDocument,
                    color: _imageFile == null ? Colors.grey : AppColors.buttonColor,
                  ),
          ],
        ),
      ),
    );
  }
}
