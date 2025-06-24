import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import 'edit_profile_page.dart';
import '../login.dart';
import 'dart:ui';
import '../../view_models/theme_view_model.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late TabController _tabController;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String? _gender;
  String? userID;
  File? _profileImage;
  bool _isEditMode = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  Map<String, dynamic> _userData = {};
  int _selectedTabIndex = 0;
  final List<String> _tabs = [
    'Preferences',
    'Friends',
    'General Setting',
    'About iBites',
    'Log Out',
  ];

  @override
  void initState() {
    super.initState();
    userID = _auth.getUserID();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadProfileData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userData: _userData,
          onProfileUpdated: (updatedData) {
            setState(() {
              _userData = updatedData;
            });
          },
        ),
      ),
    );
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

          await FirebaseFirestore.instance.collection('users').doc(userID).set({
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
          });

          if (mounted) {
            setState(() {
              _isEditMode = false;
            });
            if (updateEmail) {
              _showDialog(
                  'Your profile has been successfully updated! Please check your new email inbox to verify and confirm the email change.',
                  isSuccess: true);
            } else {
              _showDialog('Profile updated successfully!', isSuccess: true);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          _showDialog('Failed to update profile: $e', isSuccess: false);
        }
      }
    }
  }

  void _showDialog(String message, {required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Close the dialog first
                  Navigator.of(context).pop();

                  // Sign out the user
                  await _auth.signout();

                  // Navigate back to login page and clear history
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  print("Error during logout: $e");
                  // If there's an error, show a snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error during logout: $e',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onError)),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text('Logout',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onError)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? profileImageUrl = _userData['profileImageUrl'];
    final String userName = _userData['name'] ?? 'Your Name';
    final String userEmail = _userData['email'] ?? 'your.email@example.com';
    final String joinedDate = _userData['joined'] ?? '1 January 2024';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          Consumer<ThemeViewModel>(
            builder: (context, themeViewModel, _) {
              return IconButton(
                icon: Icon(
                  themeViewModel.themeMode == ThemeMode.system
                      ? Icons.brightness_auto
                      : themeViewModel.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                ),
                tooltip: '${themeViewModel.currentThemeText} Theme',
                onPressed: themeViewModel.toggleTheme,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Profile Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                userName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userEmail,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _navigateToEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Action List
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                children: [
                  _buildProfileLink(
                    icon: Icons.tune,
                    title: 'Preferences',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      // TODO: Navigate to Preferences page
                    },
                  ),
                  _buildProfileLink(
                    icon: Icons.people,
                    title: 'Friends',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      // TODO: Navigate to Friends page
                    },
                  ),
                  _buildProfileLink(
                    icon: Icons.settings,
                    title: 'General Setting',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      // TODO: Navigate to General Setting page
                    },
                  ),
                  _buildProfileLink(
                    icon: Icons.info_outline,
                    title: 'About iBites',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      // TODO: Navigate to About iBites page
                    },
                  ),
                  _buildProfileLink(
                    icon: Icons.logout,
                    title: 'Log Out',
                    color: Color(0xFFE53935),
                    onTap: () {
                      _showLogoutConfirmationDialog();
                    },
                    isLogout: true,
                  ),
                ],
              ),
              // Joined Date
              Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 8),
                child: Text(
                  'Joined $joinedDate',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileLink({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 26),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isLogout
                  ? Color(0xFFE53935)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing:
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
