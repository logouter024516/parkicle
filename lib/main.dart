import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_page.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<UserCredential?> signInWithGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    try {
      await _auth.signOut(); // 항상 로그아웃 후 새 계정 로그인
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google sign in failed: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("PARKICLE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 48),
            Image.asset(
              'assets/img.png',
              height: 80,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 260,
              height: 50,
              child: SignInButton(
                Buttons.Google,
                text: 'Continue with Google',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                onPressed: () async {
                  final userCredential = await signInWithGoogle();
                  if (userCredential != null && userCredential.user != null) {
                    final profilePage = await UserProfilePage.getProfilePage(userCredential.user!);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => profilePage),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
