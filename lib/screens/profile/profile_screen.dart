import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../services/email_service.dart';
import '../services/auth_service.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';
import '../screens/themes_screen.dart';
import '../screens/languages_screen.dart';
import '../screens/integrations_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  UserModel? _userModel;
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userModel = UserModel.fromJson(doc.data()!);
          _bioController.text = _userModel!.bio;
        });
      }
    }
  }

  Future<void> _updateBio() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'bio': _bioController.text});
      _loadUserData();
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
        await storageRef.putFile(File(pickedFile.path));
        final url = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profile_image': url});
        _loadUserData();
      }
    }
  }

  Future<void> _exportAndSendData() async {
    setState(() => _isLoading = true);
    try {
      if (_userModel != null) {
        await EmailService().sendUserData(_userModel!.toJson(), 'alfredopjonas@gmail.com');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('data_sent')!)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('error_sending_data')!)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _uploadProfileImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _userModel!.profileImage != null ? NetworkImage(_userModel!.profileImage!) : null,
              child: _userModel!.profileImage == null ? const Icon(Icons.person_rounded, size: 50) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(_userModel!.fullName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.translate('bio')!,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 3,
            onSubmitted: (_) => _updateBio(),
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('update_bio')!,
            onPressed: _updateBio,
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('statistics')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.star_rounded),
            title: Text('${AppLocalizations.of(context)!.translate('points')!}: ${_userModel!.points}'),
          ),
          ListTile(
            leading: const Icon(Icons.group_rounded),
            title: Text('${AppLocalizations.of(context)!.translate('followers')!}: ${_userModel!.followedUsers.length}'),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('settings')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: Text(AppLocalizations.of(context)!.translate('themes')!),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ThemesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(AppLocalizations.of(context)!.translate('languages')!),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LanguagesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: Text(AppLocalizations.of(context)!.translate('integrations')!),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => IntegrationsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded),
            title: Text(AppLocalizations.of(context)!.translate('security')!),
            onTap: () {
              // Open security screen with 2FA, etc.
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: _isLoading ? '' : AppLocalizations.of(context)!.translate('export_data')!,
            isLoading: _isLoading,
            onPressed: _exportAndSendData,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('logout')!,
            color: danger,
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}