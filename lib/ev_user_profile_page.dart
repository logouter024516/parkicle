import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'car_info_page.dart';

class EVUserProfilePage extends StatelessWidget {
  final User user;
  const EVUserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // 연한 하늘색
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(Icons.electric_car, size: 48, color: Colors.blue)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.email ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('car_info').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('차량 정보 불러오기 실패', style: TextStyle(color: Colors.red));
                }
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final carNumber = data != null && data['car_number'] != null && data['car_number'].toString().isNotEmpty
                  ? data['car_number']
                  : '등록 필요';
                return Text('차량번호: $carNumber', style: const TextStyle(fontSize: 16));
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('car_info').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('차량 정보 불러오기 실패', style: TextStyle(color: Colors.red));
                }
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final cartype = data != null && data['car_type'] != null && data['car_type'].toString().isNotEmpty
                    ? data['car_type']
                    : '연동 실패';
                return Text('차종: $cartype', style: const TextStyle(fontSize: 16));
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CarInfoPage(user: user)),
                );
              },
              child: const Text('차량 정보 등록/수정하기'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (route) => false,
                  );
                },
                child: const Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
