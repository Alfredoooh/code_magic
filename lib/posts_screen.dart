import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class PostsScreen extends StatelessWidget {
  final String token;

  const PostsScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: PrimaryAppBar(title: ''),
      body: Center(
        child: Text(
          'Posts',
          style: context.textStyles.headlineMedium,
        ),
      ),
    );
  }
}