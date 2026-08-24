import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? registrationData;
  final bool isEditing;

  const ProfileSetupScreen({
    super.key,
    required this.userId,
    this.registrationData,
    this.isEditing = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();

  File? _profileImage;
  String? _existingImageUrl;
  bool _isSaving = false;

  final String _cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/ddxwnqqbu/image/upload';
  final String _uploadPreset = 'flutter_unsigned';

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing && widget.registrationData != null) {
      _nameController.text =
      '${widget.registrationData!['firstName']} ${widget.registrationData!['lastName']}';
    }
    if (widget.isEditing) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _occupationController.text = data['occupation'] ?? '';
          _existingImageUrl = data['profilePicture'] ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackbar("Failed to load profile: ${e.toString()}");
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('tp'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (widget.isEditing && _existingImageUrl?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:  Text('rp'.tr(),
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmImageRemoval();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmImageRemoval() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:Text('rp'.tr()),
        content: Text('sure'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text('remove'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _profileImage = null;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showErrorSnackbar("Camera access is required to take photos");
      return;
    }
    if (status.isPermanentlyDenied) {
      _showErrorSnackbar("Please enable camera access in Settings");
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await _processImage(pickedFile);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      _showErrorSnackbar("Photo library access is required to choose images");
      return;
    }
    if (status.isPermanentlyDenied) {
      _showErrorSnackbar("Please enable photo access in Settings");
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      await _processImage(pickedFile);
    }
  }

  Future<void> _processImage(XFile pickedFile) async {
    try {
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      final editedImage = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(image: imageBytes),
        ),
      );

      if (editedImage != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/edited_profile_image.jpg';
        final file = await File(path).writeAsBytes(editedImage);

        setState(() => _profileImage = file);
      }
    } catch (e) {
      _showErrorSnackbar("Couldn't process image: ${e.toString()}");
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      final uri = Uri.parse(_cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        return json.decode(resStr)['secure_url'] as String?;
      } else {
        _showErrorSnackbar("Image upload failed (${response.statusCode})");
        return null;
      }
    } catch (e) {
      _showErrorSnackbar("Image upload failed: ${e.toString()}");
      return null;
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImageToCloudinary(_profileImage!);
        if (imageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final userData = {
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'occupation': _occupationController.text.trim(),
        'profilePicture': imageUrl ?? _existingImageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!widget.isEditing) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(userData, SetOptions(merge: true));

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          )
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showErrorSnackbar("Error saving profile: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'edit_profile'.tr() : 'c_p'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                widget.isEditing ? 'u_p'.tr() : 'f_p'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _showImageSourceModal,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _getProfileImage(),
                      child: _profileImage == null &&
                          (_existingImageUrl?.isEmpty ?? true)
                          ? const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey)
                          : null,
                    ),
                    if (_profileImage != null ||
                        (_existingImageUrl?.isNotEmpty ?? false))
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.blue,
                          onPressed: _showImageSourceModal,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length > 50) {
                    return 'Name cannot exceed 50 characters';
                  }
                  if (RegExp(r'[!@#<>?":_`~;[\]\\|=+)(*&^%0-9-]').hasMatch(value)) {
                    return 'Name contains invalid characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Enter a valid number';
                  }
                  if (age < 13 || age > 120) {
                    return 'Enter a valid age (13-120)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your occupation';
                  }
                  if (value.length > 50) {
                    return 'Occupation cannot exceed 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 210,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 70), // Set width and height
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.red, // Customize if needed
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    widget.isEditing ? 'save_changes'.tr() : 'c_p'.tr(),
                    style: const TextStyle(fontSize: 18), // Increase font size
                  ),
                ),

              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text('Skip for now'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_existingImageUrl?.isNotEmpty ?? false) {
      return NetworkImage(_existingImageUrl!);
    }
    return null;
  }
}