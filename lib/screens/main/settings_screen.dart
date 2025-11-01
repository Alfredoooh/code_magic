import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../localization/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String t(String key) => AppLocalizations.translate(key, appProvider.currentLanguage);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('settings'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB52A)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Language Section
                _buildSectionHeader(t('language'), isDark),
                const SizedBox(height: 8),
                _buildLanguageCard(appProvider, authProvider, isDark),
                
                const SizedBox(height: 24),
                
                // Theme Section
                _buildSectionHeader(t('theme'), isDark),
                const SizedBox(height: 8),
                _buildThemeCard(appProvider, authProvider, isDark, t),
                
                const SizedBox(height: 24),
                
                // Clear Activities Section
                _buildSectionHeader(t('clear_activities'), isDark),
                const SizedBox(height: 8),
                _buildClearActivitiesCard(appProvider, authProvider, isDark, t),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    AppProvider appProvider,
    AuthProvider authProvider,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242526) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: AppLocalizations.supportedLanguages.map((lang) {
          final isSelected = appProvider.currentLanguage == lang['code'];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFDB52A).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.language,
                color: isSelected
                    ? const Color(0xFFFDB52A)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            title: Text(
              lang['name']!,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFFFDB52A))
                : null,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });
              
              await appProvider.changeLanguage(
                lang['code']!,
                authProvider.currentUser?.userId,
              );
              
              setState(() {
                _isLoading = false;
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to ${lang['name']}'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFFFDB52A),
                  ),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeCard(
    AppProvider appProvider,
    AuthProvider authProvider,
    bool isDark,
    String Function(String) t,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242526) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dark Theme
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appProvider.themeMode == ThemeMode.dark
                    ? const Color(0xFFFDB52A).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.dark_mode,
                color: appProvider.themeMode == ThemeMode.dark
                    ? const Color(0xFFFDB52A)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            title: Text(
              t('dark_theme'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: appProvider.themeMode == ThemeMode.dark
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: appProvider.themeMode == ThemeMode.dark
                ? const Icon(Icons.check_circle, color: Color(0xFFFDB52A))
                : null,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });
              
              await appProvider.changeTheme(
                ThemeMode.dark,
                authProvider.currentUser?.userId,
              );
              
              setState(() {
                _isLoading = false;
              });
            },
          ),
          
          const Divider(height: 1),
          
          // Light Theme
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appProvider.themeMode == ThemeMode.light
                    ? const Color(0xFFFDB52A).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.light_mode,
                color: appProvider.themeMode == ThemeMode.light
                    ? const Color(0xFFFDB52A)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            title: Text(
              t('light_theme'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: appProvider.themeMode == ThemeMode.light
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: appProvider.themeMode == ThemeMode.light
                ? const Icon(Icons.check_circle, color: Color(0xFFFDB52A))
                : null,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });
              
              await appProvider.changeTheme(
                ThemeMode.light,
                authProvider.currentUser?.userId,
              );
              
              setState(() {
                _isLoading = false;
              });
            },
          ),
          
          const Divider(height: 1),
          
          // System Theme
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appProvider.themeMode == ThemeMode.system
                    ? const Color(0xFFFDB52A).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings_suggest,
                color: appProvider.themeMode == ThemeMode.system
                    ? const Color(0xFFFDB52A)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            title: Text(
              t('system_theme'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: appProvider.themeMode == ThemeMode.system
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: appProvider.themeMode == ThemeMode.system
                ? const Icon(Icons.check_circle, color: Color(0xFFFDB52A))
                : null,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });
              
              await appProvider.changeTheme(
                ThemeMode.system,
                authProvider.currentUser?.userId,
              );
              
              setState(() {
                _isLoading = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClearActivitiesCard(
    AppProvider appProvider,
    AuthProvider authProvider,
    bool isDark,
    String Function(String) t,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242526) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.delete_sweep, color: Colors.red),
        ),
        title: Text(
          t('clear_activities'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text(
          'Clear all posts, messages and activities',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        onTap: () async {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
              title: Text(
                'Clear All Activities?',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              content: Text(
                'This will permanently delete all your posts and activities. This action cannot be undone.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          
          if (confirmed == true && authProvider.currentUser != null) {
            setState(() {
              _isLoading = true;
            });
            
            await appProvider.clearAllActivities(
              authProvider.currentUser!.userId,
            );
            
            setState(() {
              _isLoading = false;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All activities cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      ),
    );
  }
}