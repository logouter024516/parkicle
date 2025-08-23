import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCarNumber();
  }

  Future<void> _loadCarNumber() async {
    final doc = await FirebaseFirestore.instance.collection('car_info').doc(widget.user.uid).get();
    if (doc.exists) {
      setState(() {
        _savedCarNumber = doc['car_number'] ?? '';
        _carNumberController.text = _savedCarNumber!;
      });
    }
  }

  Future<void> _saveCarNumber() async {
    setState(() { _loading = true; });
    await FirebaseFirestore.instance.collection('car_info').doc(widget.user.uid).set({
      'car_number': _carNumberController.text,
      'email': widget.user.email,
      'displayName': widget.user.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() { _loading = false; _savedCarNumber = _carNumberController.text; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('차량 번호가 저장되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _carNumberController,
              decoration: InputDecoration(
                hintStyle: const TextStyle(fontSize: 28, color: Colors.black12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              style: const TextStyle(fontSize: 28, letterSpacing: 4),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              maxLength: 8,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final raw = _carNumberController.text;
                return Text(
                  "차량 번호를 입력해주세요.\n예시: 12가3456 또는 123가 1234",
                  style: TextStyle(fontSize: 18, color: Colors.black45),
                  textAlign: TextAlign.center,
                );
              },
            ),
            if (_savedCarNumber != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('등록된 차량 번호: $_savedCarNumber'),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4285F4), // 버튼 색상
                  foregroundColor: Colors.white, // 텍스트 색상
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _saveCarNumber,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('저장', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4285F4),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('뒤로가기'),
            ),
          ],
        ),
      ),
    );
  }
}
