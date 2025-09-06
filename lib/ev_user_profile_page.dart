import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'car_info_page.dart';
import 'dart:ui'; // ImageFilter 사용을 위한 import

class EVUserProfilePage extends StatelessWidget {
  final User user;
  const EVUserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 하얀색으로
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
                  color: const Color(0xFFECF4FB), // 연하면서 파란기가 조금 더 도는 하늘색
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null ? const Icon(Icons.electric_car, size: 48, color: Colors.blue) : null,
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
                  color: const Color(0xFFECF4FB), // 연하면서 파란기가 조금 더 도는 하늘색
                  elevation: 3,
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
                            if (fuelType != '전기' && fuelType != '하이브리드(PHEV, 외부 충전 가능)') {
                              return const Text('이 페이지는 전기차 또는 PHEV(외부 충전 가능)만 지원합니다.', style: TextStyle(color: Colors.red));
                            }
                            final parkingArea = data != null && data['parkingArea'] != null && data['parkingArea'].toString().isNotEmpty
                                ? data['parkingArea']
                                : null;
                            final parkingTime = data != null && data['parkingTime'] != null
                                ? data['parkingTime']
                                : null;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_gas_station, size: 20, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text('연료 종류: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(fuelType, style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (parkingArea != null && parkingTime != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.local_parking, size: 20, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Text('주차중: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                      Builder(
                                        builder: (context) {
                                          int minutes = 0;
                                          try {
                                            minutes = int.tryParse(parkingTime.toString()) ?? 0;
                                          } catch (_) {}
                                          if (minutes >= 60) {
                                            final hours = minutes ~/ 60;
                                            final mins = minutes % 60;
                                            return Text('$parkingArea, ${hours}시간 ${mins}분', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black));
                                          } else {
                                            return Text('$parkingArea, ${minutes}분', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black));
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      const Icon(Icons.local_parking, size: 20, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      const Text('주차중이 아님', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                                    ],
                                  ),
                              ],
                            );
                          },
                        ),
                        // 차량 정보 카드 아래에 불법주차 경고 표시
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('car_info').doc(user.uid).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final parkingTime = data != null && data['parkingTime'] != null
                                ? int.tryParse(data['parkingTime'].toString()) ?? 0
                                : 0;
                            final fuelType = data != null && data['fuel_type'] != null
                                ? data['fuel_type'].toString()
                                : '';
                            // 전기차/PHEV가 아닌 차량일 때만 경고 표시
                            if (parkingTime > 0 && fuelType != '전기' && fuelType != '하이브리드(PHEV, 외부 충전 가능)') {
                              return const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text('불법주차중(TEST)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
