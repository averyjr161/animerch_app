import 'package:animerch_app/Services/auth_service.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'User'; // Default role
  final AuthService _authService = AuthService();

  // Dark blue color to be used throughout
  final Color darkBlue = Colors.blue.shade900;

  void _signup() async {
    String? result = await _authService.signup(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole,
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $result")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Light blue background
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Ani Merch",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.asset("assets/logo.png", width: 200),
                  const SizedBox(height: 20),
                  buildInputField(
                    controller: nameController,
                    icon: Icons.person,
                    hint: "Name",
                    validatorMsg: "Name is required",
                  ),
                  buildInputField(
                    controller: emailController,
                    icon: Icons.email,
                    hint: "Email",
                    validatorMsg: "Email is required",
                  ),
                  buildInputField(
                    controller: passwordController,
                    icon: Icons.lock,
                    hint: "Password",
                    validatorMsg: "Password is required",
                    obscure: true,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue[100]?.withOpacity(1),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRole,
                      icon: Icon(Icons.arrow_drop_down, color: darkBlue),
                      decoration: InputDecoration(
                        icon: Icon(Icons.group, color: darkBlue),
                        border: InputBorder.none,
                        hintText: "Select Role",
                        hintStyle: TextStyle(color: Colors.blueGrey[700]),
                      ),
                      items: ['User', 'Admin'].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role, style: TextStyle(color: darkBlue)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  buildButton(context),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(color: darkBlue),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          "Login here",
                          style: TextStyle(color: darkBlue),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String validatorMsg,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue[100]?.withOpacity(1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (value) => value!.isEmpty ? validatorMsg : null,
        decoration: InputDecoration(
          icon: Icon(icon, color: darkBlue),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey[700]),
        ),
        style: TextStyle(color: darkBlue),
      ),
    );
  }

  Widget buildButton(BuildContext context) {
    return Container(
      height: 55,
      width: MediaQuery.of(context).size.width * .9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.blueAccent,
      ),
      child: TextButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            _signup();
          }
        },
        child: const Text(
          "SIGN UP",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
