// posts_screen.dart
import 'package:flutter/material.dart';

class PostsScreen extends StatelessWidget {
  final String token;

  const PostsScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Publicações',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em breve você poderá ver publicações\ne atualizações da comunidade',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}