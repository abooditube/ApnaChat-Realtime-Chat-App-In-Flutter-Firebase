import 'dart:developer';

import 'package:flutter/material.dart';

import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../../main.dart';
import 'signup_screen.dart';
import '../home_screen.dart';

// login screen -- implements email/password sign in feature for app
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // form key for validation
  final _formKey = GlobalKey<FormState>();

  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // password visibility
  bool _obscurePassword = true;

  // animation
  bool _isAnimate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isAnimate = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // handle login button click
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // show loading dialog
      Dialogs.showLoading(context);

      try {
        // sign in with email and password
        final userCredential = await APIs.auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // hide loading
        if (mounted) Navigator.pop(context);

        if (userCredential.user != null) {
          log('\nUser: ${userCredential.user}');

          // get user info
          await APIs.getSelfInfo();

          if (await APIs.userExists() && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            // user exists in auth but not in firestore, create user
            await APIs.createUserWithEmail(
              userCredential.user!.displayName ?? 'User',
              userCredential.user!.email ?? '',
            );
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          }
        }
      } catch (e) {
        // hide loading
        if (mounted) Navigator.pop(context);

        log('\n_loginError: $e');

        String errorMessage = 'Something went wrong!';
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No user found with this email!';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Wrong password!';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address!';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled!';
        } else if (e.toString().contains('invalid-credential')) {
          errorMessage = 'Invalid email or password!';
        }

        if (mounted) {
          Dialogs.showSnackbar(context, errorMessage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to We Chat'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
        child: Column(
          children: [
            SizedBox(height: mq.height * .02),

            // app logo with animation
            AnimatedPositioned(
              top: mq.height * .05,
              right: _isAnimate ? mq.width * .25 : -mq.width * .5,
              width: mq.width * .5,
              duration: const Duration(seconds: 1),
              child: SizedBox(
                height: mq.height * .2,
                child: Image.asset('assets/images/icon.png'),
              ),
            ),

            SizedBox(height: mq.height * .03),

            // welcome text
            const Text(
              'Login to Continue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: mq.height * .03),

            // login form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter your email',
                      labelText: 'Email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: mq.height * .02),

                  // password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter your password',
                      labelText: 'Password',
                    ),
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

                  SizedBox(height: mq.height * .04),

                  // login button
                  SizedBox(
                    width: double.infinity,
                    height: mq.height * .06,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: mq.height * .03),

            // signup link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
