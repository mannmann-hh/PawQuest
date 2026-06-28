import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

/// Unified "edit user info" screen: change display name and character (and,
/// later, avatar) in one place.
class EditProfileScreen extends StatefulWidget {
  final String currentNickname;
  final String currentCat;
  final String? currentAvatarUrl;

  const EditProfileScreen({
    super.key,
    required this.currentNickname,
    required this.currentCat,
    this.currentAvatarUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color _cream = Color(0xFFFFF6EB);
  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _orange = Color(0xFFF77F42);
  static const Color _brown = Color(0xFF6B4F3A);

  static const List<String> _cats = [
    'cat1', 'cat2', 'cat3', 'cat4', 'cat5', 'cat6', 'cat7', 'cat8', 'cat9'
  ];

  late TextEditingController _nameController;
  late String _selectedCat;
  String? _avatarUrl;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentNickname);
    _selectedCat = widget.currentCat;
    _avatarUrl = widget.currentAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  ImageProvider _avatarProvider() {
    final url = _avatarUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return AssetImage('assets/images/cats_profile/$_selectedCat.jpeg');
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'nickname': name,
        'cat': _selectedCat,
        'avatarUrl': _avatarUrl,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _brown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _orange),
              title: const Text('Choose from photos',
                  style: TextStyle(color: _brown, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndUpload();
              },
            ),
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.restore_rounded, color: _brown),
                title: const Text('Use my character instead',
                    style:
                        TextStyle(color: _brown, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _avatarUrl = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      final ref =
          FirebaseStorage.instance.ref('avatars/${user.uid}/avatar.jpg');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _yellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          // avatar preview with edit badge
          Center(
            child: GestureDetector(
              onTap: _uploading ? null : _showAvatarOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: _yellow.withValues(alpha: 0.4),
                    backgroundImage: _avatarProvider(),
                  ),
                  if (_uploading)
                    Positioned.fill(
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: _cream, width: 2.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Tap to change photo',
              style: TextStyle(
                fontSize: 12,
                color: _brown.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _label('Display name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: _brown, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.person_rounded, color: _orange),
            ),
          ),
          const SizedBox(height: 28),

          _label('Your character'),
          const SizedBox(height: 12),
          _catSelector(),
          const SizedBox(height: 36),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _brown,
        ),
      );

  Widget _catSelector() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: _cats.map((cat) {
        final selected = cat == _selectedCat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCat = cat),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _orange : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/cats_profile/$cat.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle_rounded,
                        color: _orange, size: 20),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
