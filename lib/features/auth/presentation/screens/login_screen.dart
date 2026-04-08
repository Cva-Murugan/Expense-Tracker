// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
// import '../../../utils/global.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  bool isValid = false;

  Future<void> checkLogin() async {
    // if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);

    await notifier.login(
      emailTextController.text.trim(),
      passwordTextController.text.trim(),
    );
  }

  void validate() {
    final email = emailTextController.text;
    final pass = passwordTextController.text;

    setState(() {
      isValid =
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) &&
          pass.length >= 6;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    //final notifier = ref.read(authProvider.notifier);

    ref.listen(authProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset('assets/images/bottom.png', scale: 2.7),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset('assets/images/top.png', scale: 1.5),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    welcomeTextContainer(),
                    const SizedBox(height: 10),

                    _entryField(
                      "Email",
                      "",
                      emailTextController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    _entryField(
                      "Password",
                      "",
                      passwordTextController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 20),

                    loginButtonWidget(authState),

                    // if (authState.hasError)
                    //   Text(
                    //     authState.error.toString(),
                    //     style: const TextStyle(color: Colors.red),
                    //   ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget welcomeTextContainer() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome,",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        Text(
          "Please Login Here",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
      ],
    );
  }

  Widget _entryField(
    String title,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (_) => validate(),
        validator: (value) {
          if (title == "Email") {
            if (value == null ||
                value.isEmpty ||
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Enter a valid email';
            }
          } else {
            if (value == null || value.length < 6) {
              return 'Password must be 6+ chars';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget loginButtonWidget(AsyncValue authState) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authState.isLoading
            ? null
            : isValid
            ? checkLogin
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(39, 84, 138, 1),
        ),
        child: authState.isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Sign In",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
      ),
    );
  }
}
