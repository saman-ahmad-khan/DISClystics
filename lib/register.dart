import 'package:DISClystics/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  RegistrationScreenState createState() => RegistrationScreenState();
}

class RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();

  String? _selectedRole;
  String? _selectedHearAbout;
  String? _selectedCountry;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<Map<String, String>> _roles = [
    {'value': 'business', 'label': 'Business Owner'},
    {'value': 'individual', 'label': 'Individual'},
  ];

  final List<String> _countries = ['Pakistan', 'USA', 'Canada', 'UK', 'Australia'];

  Future<void> _registerWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Check if username is unique
        final username = _usernameController.text.trim();
        final usernameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
        if (usernameQuery.docs.isNotEmpty) {
          throw 'Username already taken';
        }

        // Create user in Firebase Auth
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'username': username,
          'role': _selectedRole,
          'businessName': _selectedRole == 'business'
              ? _businessNameController.text.trim()
              : null,
          'country': _selectedCountry,
          'hearAbout': _selectedHearAbout,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              userId: userCredential.user!.uid,
              registrationData: {
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'email': _emailController.text.trim(),
                'username': _usernameController.text.trim(),
                'role': _selectedRole,
                'country': _selectedCountry,
              },
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Registration failed. Please try again.';
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          case 'weak-password':
            errorMessage = 'Password must be at least 6 characters.';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage),
              duration: const Duration(seconds: 5),
            ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()),
              duration: const Duration(seconds: 5),
            ));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF582562),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildFieldRow(
                  left: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter your first name' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  right: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter your last name' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFieldRow(
                  left: _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    validator: (value) {
                      if (value!.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Invalid email address';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  right: _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a username' : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFieldRow(
                  left: _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    isConfirmPassword: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Include at least one uppercase letter';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Include at least one lowercase letter';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Include at least one number';
                      }
                      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Include at least one special character';
                      }
                      return null;
                    },
                  ),
                  right: _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    isConfirmPassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildFieldRow(
                  left: _buildDropdown(
                    value: _selectedRole,
                    items: _roles,
                    hint: 'Choose your role...',
                    label: 'Select Role',
                    onChanged: (value) => setState(() => _selectedRole = value),
                  ),
                  right: _buildDropdown(
                    value: _selectedHearAbout,
                    items: const ['Social Media', 'Friend', 'Advertisement', 'Other'],
                    hint: 'How did you hear about us?',
                    label: 'Referral Source',
                    onChanged: (value) => setState(() => _selectedHearAbout = value),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFieldRow(
                  left: _buildTextField(
                    controller: _businessNameController,
                    label: 'Business Name',
                    validator: (value) {
                      if (_selectedRole == 'business' && value!.isEmpty) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  right: _buildDropdown(
                    value: _selectedCountry,
                    items: _countries,
                    hint: 'Select your country',
                    label: 'Country',
                    onChanged: (value) => setState(() => _selectedCountry = value),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 200, // Fixed width for the button
                  height: 50, // Fixed height for the button
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4450F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Register', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already registered? ',
                      children: [
                        TextSpan(
                          text: 'Login here',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: left,
              flex: 1,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: right,
              flex: 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      enabled: !_isLoading,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isConfirmPassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isConfirmPassword ? _obscureConfirmPassword : _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          icon: Icon(
              isConfirmPassword
                  ? _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off
                  : _obscurePassword ? Icons.visibility : Icons.visibility_off
          ),
          onPressed: () {
            setState(() {
              if (isConfirmPassword) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        ),
      ),
      validator: validator,
      enabled: !_isLoading,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDropdown({
    required dynamic value,
    required List<dynamic> items,
    required String hint,
    required String label,
    required Function(dynamic) onChanged,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 120, // Minimum width for the dropdown
        maxWidth: 180, // Maximum width to prevent overflow
      ),
      child: DropdownButtonFormField(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item is Map ? item['value'] : item,
            child: Text(
              item is Map ? item['label']! : item.toString(),
              overflow: TextOverflow.ellipsis, // Handle long text
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: _isLoading ? null : onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
        ),
        hint: Text(
          hint,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.black87, // Hint text color
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          overflow: TextOverflow.ellipsis,
        ),
        validator: (value) => value == null ? 'Required' : null,
        isExpanded: true, // Important for width constraints
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }
}