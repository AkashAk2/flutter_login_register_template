// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:roomie/homepage.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database
import 'package:google_sign_in/google_sign_in.dart';
import 'package:roomie/resetPassword.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true; // Toggle between login and register screens
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _mobileNumber = ''; // For storing the mobile number with the country code
  final TextEditingController _phoneController = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'AU'); // Default value

  // Implement the normalization method
  String _normalizePhoneNumber(String phoneNumber) {
    // Example normalization for Australian numbers: +610xxxx -> +61xxxx
    String normalizedNumber = phoneNumber.replaceAll(RegExp(r'^\+610'), '+61');
    
    // Further normalization can be added here if needed
    // Normalize Italian numbers
    if (phoneNumber.startsWith('390')) {
      phoneNumber = '+39${phoneNumber.substring(3)}';
    }
    return normalizedNumber;
  }

  void _toggleForm() {
  setState(() {
    isLogin = !isLogin;
    // Clear password and confirmPassword fields when toggling between forms
    _password = '';
    _confirmPassword = '';
    // Also, consider resetting the form state to clear any existing validation errors
    _formKey.currentState?.reset();
    // If using TextEditingController for the password fields, reset them as well
    // _passwordController.clear();
    // _confirmPasswordController.clear();
  });
}


  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Normalize the phone number to ensure uniqueness
      final normalizedPhoneNumber = _normalizePhoneNumber(_mobileNumber);

      try {
        UserCredential userCredential;

        if (isLogin) {
          // For Email/Password login
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );
        } else {
          // For Email/Password registration
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          // Store user details in Realtime Database
          final dbRef = FirebaseDatabase.instance.ref(); // Get a reference to the database
          await dbRef.child('users/${userCredential.user!.uid}').set({
            'email': _email,
            'phone': normalizedPhoneNumber, // Storing the phone number
            // Add any additional fields you may need
          });
        }

        // Navigate to home page if successful
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
      } catch (e) {
        print(e);
        String errorMessage = 'An unexpected error occurred. Please try again.';
        if (e is FirebaseAuthException) {
          
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'Email is already registered. Try logging in or resetting your password.';
              break;
            case 'weak-password':
              errorMessage = 'The password is too weak!';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is not valid!';
              break;
            case 'invalid-credential':
              errorMessage = "Please enter a valid email address and password!";
              break;
            case 'too-many-requests':
              errorMessage = "Access to this account has been temporarily disabled due to many failed login attempts. Try again later!";
              break;
            // Handle other auth errors
            default:
              break;
          }
      }
        // Display a SnackBar with an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _signInWithGoogle() async {
  try {
    // Trigger the Google Sign-In flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Optional: Store additional user information in your database now

    // Navigate to the home page if successful
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
  } catch (e) {
    // Handle error
    print(e); // Consider using a more user-friendly error reporting mechanism
  }
}



  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password.';
    String pattern = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Password must be 8 characters including 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character.';
    }
    if (!isLogin && _password != _confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  void _forgotPassword() {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ResetPassword()));
}




  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 100),
        Text('Hi Roomie!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headline4),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ToggleButton(text: 'Login', selected: isLogin, onPressed: () => _toggleForm()),
                        _ToggleButton(text: 'Register', selected: !isLogin, onPressed: () => _toggleForm()),
                      ],
                    ),
                    SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Email address'),
                            onSaved: (value) {
                            _email = value ?? ''; // Update _email with the input value
                          },
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: _validatePassword,
                            onSaved: (value) => _password = value!,
                          ),
                          if (!isLogin)
                            TextFormField(
                              decoration: InputDecoration(labelText: 'Confirm Password'),
                              obscureText: true,
                              validator: _validatePassword,
                              onSaved: (value) => _confirmPassword = value!,
                            ),
                          SizedBox(height: 20),
                          if (!isLogin) ...[
                            InternationalPhoneNumberInput(
                              onInputChanged: (PhoneNumber number) {
                                _mobileNumber = number.phoneNumber ?? '';
                              },
                              onInputValidated: (bool value) {
                                // Handle phone number validation
                              },
                              selectorConfig: SelectorConfig(
                                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                              ),
                              ignoreBlank: false,
                              autoValidateMode: AutovalidateMode.disabled,
                              initialValue: _phoneNumber,
                              textFieldController: _phoneController,
                              formatInput: false,
                              keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                              inputBorder: OutlineInputBorder(),
                              onSaved: (PhoneNumber number) {
                                _mobileNumber = number.phoneNumber ?? '';
                              },
                            ),
                            SizedBox(height: 20),
                          ],
                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: Text('Forgot Password?'),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: _submit,
                            child: Text(isLogin ? 'Login' : 'Register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Divider(height: 40, thickness: 2, indent: 20, endIndent: 20, color: Colors.grey[300]),
                          Text('Or', textAlign: TextAlign.center),
                          SignInButton(
                            Buttons.Google,
                            text: 'Sign up with Google',
                            onPressed: _signInWithGoogle,
                          ),
                          if (isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextButton(
                                onPressed: _toggleForm,
                                child: Text('Not registered yet? Create Account'),
                              ),
                            ),
                          if (!isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextButton(
                                onPressed: _toggleForm,
                                child: Text('Already have an account? Login'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}



  Widget _ToggleButton({required String text, required bool selected,
    required VoidCallback onPressed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? Colors.black : Colors.grey[300],
            foregroundColor: selected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
