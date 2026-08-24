import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_setup_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCheckingAuth = true; // Add this flag

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    setState(() => _isCheckingAuth = true);

    try {
      // Check if user is already authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _redirectUser(currentUser);
      }
    } catch (e) {
      print("Auth check error: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
        // Only load remembered email if not redirecting
        if (FirebaseAuth.instance.currentUser == null) {
          await _loadRememberedEmail();
        }
      }
    }
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('rememberedEmail');
    if (rememberedEmail != null) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _signInWithEmailOrUsername() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final input = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // First check if the input is a valid email or username exists
        bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
        bool usernameExists = false;
        String? associatedEmail;

        if (!isEmail) {
          // Check if username exists
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input.toLowerCase())
              .limit(1)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            usernameExists = true;
            associatedEmail = userSnapshot.docs.first.data()['email'] as String?;
          }
        }

        // If not an email and username doesn't exist, show error
        if (!isEmail && !usernameExists) {
          throw FirebaseAuthException(
            code: 'invalid-email-username',
            message: 'The email/username you entered is incorrect.',
          );
        }

        // Try to sign in with the email (either directly entered or from username lookup)
        try {
          final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: isEmail ? input : associatedEmail!,
            password: password,
          );

          await _handleSuccessfulSignIn(userCredential.user!);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            throw FirebaseAuthException(
              code: 'wrong-password',
              message: 'The password you entered is incorrect. Please try again.',
            );
          }
          rethrow;
        }
      } on FirebaseAuthException catch (e) {
        _handleAuthError(e);
      } catch (e) {
        print('Login error: $e');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text(e.toString()), // show detailed error
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _redirectUser(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (!userDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfileSetupScreen(userId: user.uid, registrationData: {}),
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleSuccessfulSignIn(User user) async {
    await _saveRememberedEmail();
    await _redirectUser(user);
  }

  void _handleAuthError(FirebaseAuthException e) {
    String title = 'Sign In Error';
    String message;

    switch (e.code) {
      case 'invalid-email':
      case 'invalid-email-username':
        message = 'The email/username you entered is incorrect.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'user-not-found':
        message = 'No account found with this email/username. Please check or register.';
        break;
      case 'wrong-password':
      case 'invalid-credential':
        message = 'The password you entered is incorrect. Please try again.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password sign-in is not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      default:
        message = e.message ?? 'Sign in failed. Please try again.';
    }

    _showErrorDialog(title, message);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('rememberedEmail', _emailController.text.trim());
    } else {
      await prefs.remove('rememberedEmail');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth status
    if (_isCheckingAuth) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Checking authentication...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: const Color(0xff582562),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(40.0, 120.0, 40.0, 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email or Username',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value!);
                        },
                      ),
                      const Text('Remember Me'),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _showPasswordResetDialog,
                    child: const Text('Forgot your password?'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmailOrUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4450F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Don\'t have an account? ',
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff582562),
                            ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white54,
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white54,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: validator,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signInWithEmailOrUsername(),
    );
  }

  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            hintText: 'example@email.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                _showErrorDialog('Error', e.message ?? 'Failed to send reset email');
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}