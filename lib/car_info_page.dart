import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_page.dart';

class CarInfoPage extends StatefulWidget {
  final User user;
  const CarInfoPage({super.key, required this.user});

  @override
  State<CarInfoPage> createState() => _CarInfoPageState();
}

class _CarInfoPageState extends State<CarInfoPage> {
  final TextEditingController _carNumberController = TextEditingController();
  bool _loading = false;
  String? _savedCarNumber;
  String? _selectedFuelType;
  String? _savedFuelType;

  @override
  void initState() {
    super.initState();
    _loadCarInfo();
  }

  Future<void> _loadCarInfo() async {
    final doc = await FirebaseFirestore.instance.collection('car_info').doc(widget.user.uid).get();
    if (doc.exists) {
      setState(() {
        _savedCarNumber = doc['car_number'] ?? '';
        _savedFuelType = doc['fuel_type'] ?? '';
        _carNumberController.text = _savedCarNumber!;
        _selectedFuelType = _savedFuelType;
      });
    }
  }

  Future<void> _saveCarInfo() async {
    setState(() { _loading = true; });
    final docRef = FirebaseFirestore.instance.collection('car_info').doc(widget.user.uid);
    final doc = await docRef.get();
    final data = {
      'car_number': _carNumberController.text,
      'fuel_type': _selectedFuelType,
      'email': widget.user.email,
      'displayName': widget.user.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (doc.exists) {
      await docRef.update(data);
    } else {
      await docRef.set(data);
    }

    // car_info/key 문서에 UID:차량번호 형태로 업데이트 (merge)
    await FirebaseFirestore.instance.collection('car_info').doc('key').set({
      _carNumberController.text : widget.user.uid,
    }, SetOptions(merge: true));
    setState(() {
      _loading = false;
      _savedCarNumber = _carNumberController.text;
      _savedFuelType = _selectedFuelType;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('차량 정보가 저장되었습니다.')));
    await UserProfilePage.pushProfilePage(context, widget.user);
  }
  @override
  Widget build(BuildContext context) {
    // 드롭다운에 들어갈 연료 종류 리스트
    final List<String> fuelTypeList = [
      '휘발유',
      '경유(디젤)',
      '전기',
      '수소',
      '하이브리드(PHEV, 외부 충전 가능)',
      '하이브리드(HEV, 외부 충전 불가)',
      '기타',
    ];
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      // AppBar와 BottomNavigationBar 제거
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    const Text(
                      "차량 정보 등록/수정",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "차량 번호와 연료 종류를 입력해주세요.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 차량번호 입력 필드
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _carNumberController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          labelText: "차량 번호",
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          hintText: "예시: 12가3456",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 연료 종류 드롭다운
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: (_selectedFuelType != null && fuelTypeList.contains(_selectedFuelType)) ? _selectedFuelType : null,
                        items: fuelTypeList
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFuelType = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "연료 종류",
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_savedCarNumber != null && _savedCarNumber!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('등록된 차량 번호: $_savedCarNumber'),
                      ),

                    if (_savedFuelType != null && _savedFuelType!.isNotEmpty)
                      const SizedBox(height: 8),

                    if (_savedFuelType != null && _savedFuelType!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('등록된 연료 종류: $_savedFuelType'),
                      ),

                    const Spacer(),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 40),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveCarInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '저장',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
