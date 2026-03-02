import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/repositories/medical_records_repository.dart';
import '../../../core/services/image_cache_service.dart';
//import '../../../core/models/update_profile_request.dart';
import '../../../core/services/medical_record_cache_service.dart';
import '../../../shared/widgets/simple_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedGender = 'Male';
  DateTime? _selectedDateOfBirth;
  File? _selectedProfileImage;
  List<File> _medicalRecords = [];
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
      _countryController.text = user.country ?? '';
      _postalCodeController.text = user.postalCode ?? '';
      _bioController.text = user.bio ?? '';
      
      if (user.dateOfBirth != null) {
        _selectedDateOfBirth = user.dateOfBirth;
        _dateOfBirthController.text = '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}';
      }
      
      // Set gender if available
      if (user.gender != null) {
        _selectedGender = user.gender!;
      }
      
      // Cache the current profile picture
      if (user.profilePicture != null) {
        ImageCacheService.cacheProfileImage(user.profilePicture!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConfig.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfilePictureSection(),
                    const SizedBox(height: 32),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 32),
                    if (_shouldShowMedicalRecordsSection(authProvider.currentUser))
                      _buildMedicalRecordsSection(),
                    if (_shouldShowMedicalRecordsSection(authProvider.currentUser))
                      const SizedBox(height: 32),
                    _buildSaveButton(authProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _selectProfilePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedProfileImage != null 
                      ? FileImage(_selectedProfileImage!)
                      : (user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                          ? NetworkImage(user.profilePicture!)
                          : null),
                  child: _selectedProfileImage == null && (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _selectProfilePicture,
            child: Text(_selectedProfileImage != null || user?.profilePicture != null
                ? 'Change Profile Picture' 
                : 'Add Profile Picture'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SimpleTextField(
                controller: _firstNameController,
                labelText: 'First Name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SimpleTextField(
                controller: _lastNameController,
                labelText: 'Last Name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SimpleTextField(
          controller: _phoneController,
          labelText: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SimpleTextField(
          controller: _dateOfBirthController,
          labelText: 'Date of Birth',
          prefixIcon: Icons.calendar_today,
          readOnly: true,
          onTap: () => _selectDateOfBirth(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your date of birth';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.wc),
            border: OutlineInputBorder(),
          ),
          items: _genderOptions.map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue!;
            });
          },
        ),
        const SizedBox(height: 32),
        _buildAddressSection(),
        const SizedBox(height: 32),
        _buildBioSection(),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SimpleTextField(
          controller: _addressController,
          labelText: 'Address',
          prefixIcon: Icons.location_on,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SimpleTextField(
                controller: _cityController,
                labelText: 'City',
                prefixIcon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SimpleTextField(
                controller: _stateController,
                labelText: 'State/Province',
                prefixIcon: Icons.map,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SimpleTextField(
                controller: _countryController,
                labelText: 'Country',
                prefixIcon: Icons.public,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your country';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SimpleTextField(
                controller: _postalCodeController,
                labelText: 'Postal Code',
                prefixIcon: Icons.markunread_mailbox,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your postal code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us a bit about yourself (optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        SimpleTextField(
          controller: _bioController,
          labelText: 'Bio/About Me',
          prefixIcon: Icons.person_outline,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider) {
    return CustomButton(
      text: 'Save Changes',
      onPressed: () => _handleSaveProfile(authProvider),
      isLoading: authProvider.isLoading,
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _selectProfilePicture() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _chooseFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                _removePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowMedicalRecordsSection(User? user) {
    if (user == null) return false;
    // Show medical records section for all user types except patient
    return user.userType != UserType.patient;
  }

  Widget _buildMedicalRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Records & Certifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload your medical licenses, certifications, or relevant documents.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        if (_medicalRecords.isNotEmpty) ...[
          ..._medicalRecords.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getFileIcon(file.path),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(file.path.split('/').last),
                subtitle: Text(_getFileSize(file)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeMedicalRecord(index),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        CustomButton(
          text: 'Upload Medical Records',
          onPressed: _uploadMedicalRecords,
          icon: Icons.upload_file,
          isOutlined: true,
          isFullWidth: true,
        ),
      ],
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  void _removeMedicalRecord(int index) {
    setState(() {
      _medicalRecords.removeAt(index);
    });
  }

  Future<void> _uploadMedicalRecords() async {
    final files = await ImagePickerService.showMedicalRecordDialog(context);
    if (files != null && files.isNotEmpty) {
      // Upload each file immediately
      for (final file in files) {
        await _uploadSingleMedicalRecord(file);
      }
    }
  }

  Future<void> _uploadSingleMedicalRecord(File file) async {
    try {
      // Show dialog to get record type and description
      final recordInfo = await _showMedicalRecordInfoDialog(file);
      if (recordInfo == null) return; // User cancelled

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Uploading ${file.path.split('/').last}...'),
                ),
              ],
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }

      debugPrint('🔍 EditProfileScreen: recordInfo = $recordInfo');
      debugPrint('🔍 EditProfileScreen: recordType = "${recordInfo['recordType']}"');
      
      final medicalRecordsRepo = MedicalRecordsRepository();
      await medicalRecordsRepo.uploadMedicalRecord(
        file: file,
        description: recordInfo['description']!,
        recordType: recordInfo['recordType']!,
      );

      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('${file.path.split('/').last} uploaded successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Medical record upload error: $e');
      
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Failed to upload ${file.path.split('/').last}: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadSingleMedicalRecord(file),
            ),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final file = await ImagePickerService.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _selectedProfileImage = file;
      });
      
      // Upload immediately
      await _uploadProfileImage(file);
    }
  }

  void _chooseFromGallery() async {
    final file = await ImagePickerService.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _selectedProfileImage = file;
      });
      
      // Upload immediately
      await _uploadProfileImage(file);
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading profile picture...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

             final medicalRecordsRepo = MedicalRecordsRepository();
       final imageUrl = await medicalRecordsRepo.uploadProfileImage(imageFile);
       
       // Cache the uploaded image
       await ImageCacheService.cacheProfileImage(imageUrl);
      
      // Refresh user data to get updated profile picture
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();
      
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Profile picture uploaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Update the UI
        setState(() {
          _selectedProfileImage = null; // Reset local selection
        });
      }
    } catch (e) {
      debugPrint('Profile image upload error: $e');
      
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Failed to upload profile picture: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadProfileImage(imageFile),
            ),
          ),
        );
      }
    }
}

  void _removePhoto() {
    setState(() {
      _selectedProfileImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture removed')),
    );
  }

  Future<void> _handleSaveProfile(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Update basic profile information
      final profileData = UpdateProfileRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

      final success = await authProvider.updateProfile(profileData);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final medicalRecordsRepo = MedicalRecordsRepository();

      // Profile image is now uploaded immediately when selected
      // No need to upload again here

      // Medical records are now uploaded immediately when selected
      // No need to upload again here

             if (mounted) {
         // Refresh user data to get updated profile completion status
         await authProvider.refreshUser();
         
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Profile updated successfully!'),
             backgroundColor: Colors.green,
           ),
         );
         context.pop();
       }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, String>?> _showMedicalRecordInfoDialog(File file) async {
    final descriptionController = TextEditingController();
    String selectedRecordType = 'LICENSE';
    
    final recordTypes = [
      {'value': 'LICENSE', 'label': 'Medical License'},
      {'value': 'CERTIFICATION', 'label': 'Certification'},
      {'value': 'DIPLOMA', 'label': 'Diploma'},
      {'value': 'IDENTIFICATION', 'label': 'Identification'},
      {'value': 'MEDICAL_HISTORY', 'label': 'Medical History'},
      {'value': 'LAB_RESULTS', 'label': 'Lab Results'},
      {'value': 'OTHER', 'label': 'Other'},
    ];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Upload ${file.path.split('/').last}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRecordType,
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  border: OutlineInputBorder(),
                ),
                items: recordTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRecordType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter a description for this document',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descriptionController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'recordType': selectedRecordType,
                    'description': descriptionController.text.trim(),
                  });
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
