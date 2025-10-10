import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:madeeasy/models/user_model.dart';
import 'package:madeeasy/services/email_service.dart';
import 'package:madeeasy/services/auth_service.dart';
import 'package:madeeasy/widgets/design_system.dart';
import 'package:madeeasy/localization/app_localizations.dart';

import 'package:madeeasy/screens/themes_screen.dart';
import 'package:madeeasy/screens/languages_screen.dart';
import 'package:madeeasy/screens/integrations_screen.dart';
import 'package:madeeasy/screens/auth/login_screen.dart';

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
      return Center(child: CustomProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadProfileImage,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: accentPrimary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: secondaryBg,
                      backgroundImage: _userModel!.profileImage != null ? NetworkImage(_userModel!.profileImage!) : null,
                      child: _userModel!.profileImage == null ? const Icon(Icons.person_rounded, size: 60, color: accentPrimary) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(_userModel!.fullName, style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.translate('bio')!, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _bioController,
                    label: AppLocalizations.of(context)!.translate('bio')!,
                    icon: Icons.edit_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: AppLocalizations.of(context)!.translate('update_bio')!,
                    onPressed: _updateBio,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('statistics')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.star_rounded, color: warning, size: 32),
                        const SizedBox(height: 8),
                        Text('${_userModel!.points}', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.translate('points')!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.group_rounded, color: accentPrimary, size: 32),
                        const SizedBox(height: 8),
                        Text('${_userModel!.followedUsers.length}', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.translate('followers')!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('settings')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                CustomListTile(
                  leadingIcon: Icons.palette_rounded,
                  title: AppLocalizations.of(context)!.translate('themes')!,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ThemesScreen()));
                  },
                ),
                CustomDivider(),
                CustomListTile(
                  leadingIcon: Icons.language_rounded,
                  title: AppLocalizations.of(context)!.translate('languages')!,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LanguagesScreen()));
                  },
                ),
                CustomDivider(),
                CustomListTile(
                  leadingIcon: Icons.link_rounded,
                  title: AppLocalizations.of(context)!.translate('integrations')!,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => IntegrationsScreen()));
                  },
                ),
                CustomDivider(),
                CustomListTile(
                  leadingIcon: Icons.security_rounded,
                  title: AppLocalizations.of(context)!.translate('security')!,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: _isLoading ? '' : AppLocalizations.of(context)!.translate('export_data')!,
            isLoading: _isLoading,
            onPressed: _exportAndSendData,
            color: info,
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