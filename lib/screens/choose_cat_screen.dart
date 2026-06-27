import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_screen.dart';


class ChooseCatScreen extends StatefulWidget {
  const ChooseCatScreen({super.key});

  @override
  State<ChooseCatScreen> createState() => _ChooseCatScreenState();
}

class _ChooseCatScreenState extends State<ChooseCatScreen> {
  final List<String> cats = [
    'cat1', 'cat2', 'cat3',
    'cat4', 'cat5', 'cat6',
    'cat7', 'cat8', 'cat9',
  ];

  String? selectedCat;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSelectedCat();
  }

  Future<void> _loadSelectedCat() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        selectedCat = doc.data()?['cat'];
      });
    }
  }

  Future<void> _selectCat(String catName) async {
    if (user != null) {
      try {
        debugPrint('Updating cat to $catName');
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'cat': catName,
        });
        if (!mounted) return;
        setState(() {
          selectedCat = catName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🐱 You choose $catName')),
        );
      } catch (e) {
        debugPrint('Firestore update error: $e');
      }
    } else {
      debugPrint('User is null!');
    }
  }

  String _catAssetPath(String catName) {
    return 'assets/images/cats_profile/$catName.jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your Cat Character')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              selectedCat != null
                  ? 'Your current selection is：$selectedCat'
                  : 'Please choose your favorite cat character',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: cats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final catName = cats[index];
                  final isSelected = selectedCat == catName;

                  return InkWell(
                    onTap: () => _selectCat(catName),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 60,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Image.asset(
                                _catAssetPath(catName),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(catName),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              child: const Text('Save and return to home page'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}