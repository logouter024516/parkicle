import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'ev_user_profile_page.dart';
import 'car_info_page.dart'; // CarInfoPage 임포트 추가

class UserProfilePage extends StatelessWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  static Future<Widget> getProfilePage(User user) async {
    final doc = await FirebaseFirestore.instance.collection('car_info').doc(user.uid).get();
    final fuelType = doc.data()?['fuel_type'];
    if (fuelType == '전기' || fuelType == '하이브리드(PHEV, 외부 충전 가능)') {
      return EVUserProfilePage(user: user);
    } else {
      return UserProfilePage(user: user);
    }
  }

  static Future<void> pushProfilePage(BuildContext context, User user) async {
    final doc = await FirebaseFirestore.instance.collection('car_info').doc(user.uid).get();
    final carNumber = doc.data()?['car_number'];
    final fuelType = doc.data()?['fuel_type'];
    if (carNumber == null || carNumber.toString().isEmpty) {
      // 차량 번호가 없으면 차량 정보 등록 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CarInfoPage(user: user)),
      );
      return;
    }
    if (fuelType == null) {
      // fuelType이 없으면 차량 정보 등록 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CarInfoPage(user: user)),
      );
      return;
    }
    if (fuelType == '전기' || fuelType == '하이브리드(PHEV, 외부 충전 가능)') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EVUserProfilePage(user: user)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfilePage(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('PARKICLE', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 비활성화
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null ? const Icon(Icons.person, size: 48) : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'WELCOME, ${user.displayName ?? "USER"}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            const Text('차량 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('car_info').doc(user.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Text('차량 정보 불러오기 실패', style: TextStyle(color: Colors.red));
                            }
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            final carNumber = data != null && data['car_number'] != null && data['car_number'].toString().isNotEmpty
                              ? data['car_number']
                              : '등록 필요';
                            return Row(
                              children: [
                                const Icon(Icons.confirmation_number, size: 20, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('차량번호: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(carNumber, style: TextStyle(fontWeight: FontWeight.bold, color: carNumber == '등록 필요' ? Colors.red : Colors.black)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('car_info').doc(user.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox();
                            }
                            if (snapshot.hasError) {
                              return const Text('차량 정보 불러오기 실패', style: TextStyle(color: Colors.red));
                            }
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            final fuelType = data != null && data['fuel_type'] != null && data['fuel_type'].toString().isNotEmpty
                                ? data['fuel_type']
                                : '연동 실패';
                            return Row(
                              children: [
                                const Icon(Icons.local_gas_station, size: 20, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('연료 종류: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(fuelType, style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            );
                          },
                        ),
                        // 불법주차 경고 표시
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('car_info').doc(user.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final parkingTime = data != null && data['parkingTime'] != null
                                ? int.tryParse(data['parkingTime'].toString()) ?? 0
                                : 0;
                            if (parkingTime > 0) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text('불법주차중', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CarInfoPage(user: user)),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('차량 정보 등록/수정하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                // 로그아웃 버튼을 가장 아래로 이동
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MyApp()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}
