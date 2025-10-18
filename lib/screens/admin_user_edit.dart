import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../widgets/app_ui_components.dart';

void showUserEditModal(BuildContext context, UserModel user, bool isDark) {
  final TextEditingController usernameController = TextEditingController(text: user.username);
  final TextEditingController tokensController = TextEditingController(text: user.tokens.toString());
  final TextEditingController expirationController = TextEditingController(text: user.expirationDate ?? '');
  final TextEditingController banUntilController = TextEditingController();

  bool isAdmin = user.admin;
  bool hasAccess = user.access;
  bool isPro = user.pro;
  DateTime? selectedExpirationDate;
  DateTime? selectedBanDate;

  // Parse existing expiration date if available
  if (user.expirationDate != null && user.expirationDate!.isNotEmpty) {
    try {
      final parts = user.expirationDate!.split('-');
      if (parts.length == 3) {
        selectedExpirationDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  Future<void> _selectDate(BuildContext context, StateSetter setModalState, bool isExpiration) async {
    DateTime initialDate = isExpiration 
        ? (selectedExpirationDate ?? DateTime.now().add(Duration(days: 30)))
        : (selectedBanDate ?? DateTime.now().add(Duration(days: 7)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.darkCard : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDark ? AppColors.darkCard : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setModalState(() {
        if (isExpiration) {
          selectedExpirationDate = picked;
          expirationController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        } else {
          selectedBanDate = picked;
          banUntilController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => KeyboardAvoiding(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              // User Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
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
                    AppFieldLabel(text: 'NOME DE USUÁRIO'),
                    AppTextField(
                      controller: usernameController,
                      hintText: 'Nome de usuário',
                      prefixIcon: Icon(Icons.person, color: Colors.grey, size: 20),
                    ),
                    SizedBox(height: 24),

                    // Permissions Section
                    _buildSectionHeader('PERMISSÕES', isDark),
                    SizedBox(height: 8),
                    AppCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 16,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.shield,
                            title: 'Administrador',
                            value: isAdmin,
                            onChanged: (value) => setModalState(() => isAdmin = value),
                            isDark: isDark,
                            isFirst: true,
                          ),
                          Divider(height: 1, thickness: 0.5, indent: 52),
                          _buildSwitchTile(
                            icon: Icons.lock_open,
                            title: 'Acesso ao App',
                            value: hasAccess,
                            onChanged: (value) => setModalState(() => hasAccess = value),
                            isDark: isDark,
                          ),
                          Divider(height: 1, thickness: 0.5, indent: 52),
                          _buildSwitchTile(
                            icon: Icons.star,
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
                    AppFieldLabel(text: 'TOKENS'),
                    AppTextField(
                      controller: tokensController,
                      hintText: 'Quantidade de tokens',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.monetization_on, color: Colors.grey, size: 20),
                    ),
                    SizedBox(height: 16),

                    // Expiration Date
                    AppFieldLabel(text: 'DATA DE EXPIRAÇÃO'),
                    GestureDetector(
                      onTap: () => _selectDate(context, setModalState, true),
                      child: AppCard(
                        padding: EdgeInsets.all(16),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedExpirationDate != null
                                    ? expirationController.text
                                    : 'Selecionar data',
                                style: TextStyle(
                                  color: selectedExpirationDate != null
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (selectedExpirationDate != null)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedExpirationDate = null;
                                    expirationController.clear();
                                  });
                                },
                                child: Icon(Icons.clear, color: Colors.grey, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Ban Section
                    _buildSectionHeader('BANIMENTO', isDark),
                    SizedBox(height: 8),
                    AppCard(
                      padding: EdgeInsets.all(16),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.block, color: Colors.red, size: 20),
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
                          GestureDetector(
                            onTap: () => _selectDate(context, setModalState, false),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.event, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
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
                                  ),
                                  if (selectedBanDate != null)
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedBanDate = null;
                                          banUntilController.clear();
                                        });
                                      },
                                      child: Icon(Icons.clear, color: Colors.grey, size: 20),
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
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Usuário será banido até ${banUntilController.text}',
                                      style: TextStyle(color: Colors.red, fontSize: 12),
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
                    AppPrimaryButton(
                      text: 'Salvar Alterações',
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
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    // Delete Button
                    AppSecondaryButton(
                      text: 'Excluir Usuário',
                      onPressed: () => _showDeleteConfirmation(context, user),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
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

Widget _buildSwitchTile({
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
        Switch(
          value: value,
          activeColor: AppColors.primary,
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
  AppDialogs.showConfirmation(
    context,
    'Excluir Usuário',
    'Tem certeza que deseja excluir ${user.username}? Esta ação não pode ser desfeita.',
    onConfirm: () async {
      await FirebaseFirestore.instance.collection('users').doc(user.id).delete();
      Navigator.pop(context); // Close modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário excluído com sucesso!'),
          backgroundColor: Colors.red,
        ),
      );
    },
    confirmText: 'Excluir',
    cancelText: 'Cancelar',
    isDestructive: true,
  );
}

// Keyboard Avoiding Widget (if not already in app_ui_components)
class KeyboardAvoiding extends StatelessWidget {
  final Widget child;

  const KeyboardAvoiding({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }
}