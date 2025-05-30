import 'package:animerch_app/Services/auth_service.dart';
import 'package:animerch_app/screens/admin/admin_home_screen.dart';
import 'package:animerch_app/screens/user/user_app_first_screen.dart';
import 'package:flutter/material.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoginTrue = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();


  final Color darkBlue = Colors.blue.shade900;

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    String? result = await _authService.login(email: email, password: password);

    if (result == "User") {
      setState(() => isLoginTrue = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserAppFirstScreen()),
      );
    } else if (result == "Admin") {
      setState(() => isLoginTrue = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else {
      setState(() => isLoginTrue = true);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], 
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
                  Image.asset("assets/logo.png", width: 210),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
                  buildButton(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: darkBlue),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: Text(
                          "SIGN UP",
                          style: TextStyle(color: darkBlue),
                        ),
                      ),
                    ],
                  ),
                  if (isLoginTrue)
                    const Text(
                      "Email or password is incorrect",
                      style: TextStyle(color: Colors.red),
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
        obscureText: obscure ? _obscurePassword : false,
        validator: (value) => value!.isEmpty ? validatorMsg : null,
        decoration: InputDecoration(
          icon: Icon(icon, color: darkBlue),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey[700]),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: darkBlue,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
        style: TextStyle(color: darkBlue),
      ),
    );
  }

  Widget buildButton() {
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
            login();
          }
        },
        child: const Text(
          "LOGIN",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
