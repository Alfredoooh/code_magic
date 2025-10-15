import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

void showUserEditModal(BuildContext context, UserModel user, bool isDark) {
  final TextEditingController usernameController = TextEditingController(text: user.username);
  final TextEditingController tokensController = TextEditingController(text: user.tokens.toString());
  final TextEditingController expirationController = TextEditingController(text: user.expirationDate ?? '');
  final TextEditingController banUntilController = TextEditingController();
  
  bool isAdmin = user.admin;
  bool hasAccess = user.access;
  bool isPro = user.pro;
  DateTime? selectedBanDate;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF48484A) : Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            SizedBox(height: 20),
            // User Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFFF444F),
              backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: user.profileImage == null || user.profileImage!.isEmpty
                  ? Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              user.username,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Username Field
                  _buildInputSection(
                    label: 'NOME DE USUÁRIO',
                    child: CupertinoTextField(
                      controller: usernameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      placeholder: 'Nome de usuário',
                      placeholderStyle: TextStyle(color: Colors.grey),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefix: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(CupertinoIcons.person, color: Colors.grey, size: 20),
                      ),
                    ),
                    isDark: isDark,
                  ),
                  SizedBox(height: 24),
                  
                  // Permissions Section
                  _buildSectionHeader('PERMISSÕES', isDark),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildIOSSwitchTile(
                          icon: CupertinoIcons.shield_lefthalf_fill,
                          title: 'Administrador',
                          value: isAdmin,
                          onChanged: (value) => setModalState(() => isAdmin = value),
                          isDark: isDark,
                          isFirst: true,
                        ),
                        Divider(height: 1, thickness: 0.5, indent: 52, color: isDark ? Color(0xFF48484A) : Color(0xFFE5E5EA)),
                        _buildIOSSwitchTile(
                          icon: CupertinoIcons.lock_open_fill,
                          title: 'Acesso ao App',
                          value: hasAccess,
                          onChanged: (value) => setModalState(() => hasAccess = value),
                          isDark: isDark,
                        ),
                        Divider(height: 1, thickness: 0.5, indent: 52, color: isDark ? Color(0xFF48484A) : Color(0xFFE5E5EA)),
                        _buildIOSSwitchTile(
                          icon: CupertinoIcons.star_fill,
                          title: 'Conta PRO',
                          value: isPro,
                          onChanged: (value) => setModalState(() => isPro = value),
                          isDark: isDark,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Tokens Section
                  _buildInputSection(
                    label: 'TOKENS',
                    child: CupertinoTextField(
                      controller: tokensController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      placeholder: 'Quantidade de tokens',
                      placeholderStyle: TextStyle(color: Colors.grey),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefix: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(CupertinoIcons.money_dollar_circle, color: Colors.grey, size: 20),
                      ),
                    ),
                    isDark: isDark,
                  ),
                  SizedBox(height: 16),
                  
                  // Expiration Date
                  _buildInputSection(
                    label: 'DATA DE EXPIRAÇÃO',
                    child: CupertinoTextField(
                      controller: expirationController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      placeholder: 'YYYY-MM-DD',
                      placeholderStyle: TextStyle(color: Colors.grey),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefix: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(CupertinoIcons.calendar, color: Colors.grey, size: 20),
                      ),
                    ),
                    isDark: isDark,
                  ),
                  SizedBox(height: 24),
                  
                  // Ban Section
                  _buildSectionHeader('BANIMENTO', isDark),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.hand_raised_fill, color: CupertinoColors.systemRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Banir usuário até',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setModalState(() {
                                selectedBanDate = date;
                                banUntilController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.calendar_badge_plus, color: CupertinoColors.systemRed, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  selectedBanDate != null 
                                      ? banUntilController.text
                                      : 'Selecionar data',
                                  style: TextStyle(
                                    color: selectedBanDate != null
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (selectedBanDate != null) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.exclamationmark_circle_fill, color: CupertinoColors.systemRed, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Usuário será banido até ${banUntilController.text}',
                                    style: TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  // Save Button
                  CupertinoButton(
                    color: CupertinoColors.systemBlue,
                    borderRadius: BorderRadius.circular(10),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    onPressed: () async {
                      await _updateUser(
                        user.id,
                        usernameController.text,
                        isAdmin,
                        hasAccess,
                        isPro,
                        int.tryParse(tokensController.text) ?? user.tokens,
                        expirationController.text.isEmpty ? null : expirationController.text,
                        selectedBanDate != null ? banUntilController.text : null,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Usuário atualizado com sucesso!'),
                          backgroundColor: CupertinoColors.systemGreen,
                        ),
                      );
                    },
                    child: Text(
                      'Salvar Alterações',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Delete Button
                  CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => _showDeleteConfirmation(context, user),
                    child: Text(
                      'Excluir Usuário',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSectionHeader(String title, bool isDark) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
      letterSpacing: -0.08,
    ),
  );
}

Widget _buildInputSection({
  required String label,
  required Widget child,
  required bool isDark,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(label, isDark),
      SizedBox(height: 8),
      child,
    ],
  );
}

Widget _buildIOSSwitchTile({
  required IconData icon,
  required String title,
  required bool value,
  required Function(bool) onChanged,
  required bool isDark,
  bool isFirst = false,
  bool isLast = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: Colors.grey, size: 22),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeColor: CupertinoColors.systemBlue,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

Future<void> _updateUser(
  String userId,
  String username,
  bool admin,
  bool access,
  bool pro,
  int tokens,
  String? expirationDate,
  String? banUntil,
) async {
  Map<String, dynamic> updates = {
    'username': username,
    'admin': admin,
    'access': access,
    'pro': pro,
    'tokens': tokens,
  };
  
  if (expirationDate != null && expirationDate.isNotEmpty) {
    updates['expiration_date'] = expirationDate;
  }
  
  if (banUntil != null && banUntil.isNotEmpty) {
    updates['banned_until'] = banUntil;
    updates['access'] = false;
  }
  
  await FirebaseFirestore.instance.collection('users').doc(userId).update(updates);
}

void _showDeleteConfirmation(BuildContext context, UserModel user) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Excluir Usuário'),
      content: Text('\nTem certeza que deseja excluir ${user.username}? Esta ação não pode ser desfeita.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            await FirebaseFirestore.instance.collection('users').doc(user.id).delete();
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close modal
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Usuário excluído com sucesso!'),
                backgroundColor: CupertinoColors.systemRed,
              ),
            );
          },
          child: Text('Excluir'),
        ),
      ],
    ),
  );
}