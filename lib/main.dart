import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_page.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _showLocalNotification(message);
}

void _showLocalNotification(RemoteMessage message) async {
  try {
    final notification = message.notification;
    String? title = notification?.title ?? message.data['title'];
    String? body = notification?.body ?? message.data['body'];
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'default_channel',
      '기본 채널',
      channelDescription: '기본 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  } catch (e, st) {
    print('로컬 알림 표시 중 오류: $e\n$st');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // AndroidInitializationSettings에서 파라미터를 생략하여 기본값 사용 (리소스 지정하지 않음)
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드 알림 수신: ${message.notification?.title}');
      _showLocalNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('알림 클릭으로 앱 열림: ${message.notification?.title}');
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    try {
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

  void requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android 13(API 33) 이상에서만 권한 요청
      if (await Permission.notification.isDenied || await Permission.notification.isRestricted) {
        final status = await Permission.notification.request();
        print('알림 권한 요청 결과: $status');
      } else {
        print('알림 권한 이미 허용됨');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser != null
          ? FutureBuilder(
              future: UserProfilePage.getProfilePage(FirebaseAuth.instance.currentUser!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return snapshot.data!;
                }
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              },
            )
          : const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<UserCredential?> signInWithGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    try {
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

  void requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android 13(API 33) 이상에서만 권한 요청
      if (await Permission.notification.isDenied || await Permission.notification.isRestricted) {
        final status = await Permission.notification.request();
        print('알림 권한 요청 결과: $status');
      } else {
        print('알림 권한 이미 허용됨');
      }
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
                    // FCM 토큰 출력
                    String? fcmToken = await FirebaseMessaging.instance.getToken();
                    print('FCM Token: '
                        '${fcmToken ?? '토큰 없음'}');
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
