import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfilePage({
    super.key,
    required this.userData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _auth = AuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String? _gender;
  String? userID;
  File? _profileImage;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String? _joinedDate;

  @override
  void initState() {
    super.initState();
    userID = _auth.getUserID();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController.text = widget.userData['name'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    _weightController.text = widget.userData['weight'] ?? '';
    _heightController.text = widget.userData['height'] ?? '';
    _contactController.text = widget.userData['contactno'] ?? '';
    _gender = widget.userData['gender'] ?? 'Male';
    _notificationsEnabled = widget.userData['notifications'] ?? true;
    _darkModeEnabled = widget.userData['darkMode'] ?? false;
    _selectedLanguage = widget.userData['language'] ?? 'English';
    _joinedDate = widget.userData['joined'] ?? '1 January 2024';
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // TODO: Upload image to Firebase Storage
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String email = _emailController.text;
          bool updateEmail = false;

          if (email != user.email && _passwordController.text.isNotEmpty) {
            String currentPassword = _passwordController.text;
            AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: currentPassword,
            );
            await user.reauthenticateWithCredential(credential);
            await user.verifyBeforeUpdateEmail(email);
            updateEmail = true;
          }

          Map<String, dynamic> updatedData = {
            'email': user.email,
            'weight': _weightController.text,
            'height': _heightController.text,
            'gender': _gender,
            'contactno': _contactController.text,
            'name': _fullNameController.text,
            'userID': userID,
            'usertype': 'user',
            'notifications': _notificationsEnabled,
            'darkMode': _darkModeEnabled,
            'language': _selectedLanguage,
            'joined': _joinedDate,
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .set(updatedData);

          widget.onProfileUpdated(updatedData);

          if (mounted) {
            await _showDialog('Profile updated successfully!', isSuccess: true);
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          _showDialog('Failed to update profile: $e', isSuccess: false);
        }
      }
    }
  }

  Future<void> _showDialog(String message, {required bool isSuccess}) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? profileImageUrl = widget.userData['profileImageUrl'];
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Profile Avatar with edit icon
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.orange.withOpacity(0.15),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (profileImageUrl != null &&
                                      profileImageUrl.isNotEmpty)
                                  ? NetworkImage(profileImageUrl)
                                      as ImageProvider
                                  : null,
                          child: (_profileImage == null &&
                                  (profileImageUrl == null ||
                                      profileImageUrl.isEmpty))
                              ? Icon(Icons.person,
                                  size: 50, color: Colors.grey[600])
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFF9800),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Email is required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                            return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactController,
                        label: 'Phone No',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Contact number is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _gender,
                        onChanged: (String? newValue) {
                          setState(() {
                            _gender = newValue;
                          });
                        },
                        items: <String>['Male', 'Female', 'Other']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon:
                              Icon(Icons.people, color: Color(0xFFFF9800)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Color(0xFFFF9800)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Color(0xFFFF9800)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Color(0xFFFF9800), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.orange.withOpacity(0.04),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Gender is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Height
                      _buildTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Height is required';
                          if (double.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Weight
                      _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Weight is required';
                          if (double.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF9800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Joined $_joinedDate',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFFFF9800)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFFF9800)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFFF9800)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
        ),
        filled: true,
        fillColor: Colors.orange.withOpacity(0.04),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}
