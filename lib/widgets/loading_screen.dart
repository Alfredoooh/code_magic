import 'package:flutter/material.dart';
import 'animated_dot.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone centralizado
          Image.asset(
            'assets/icon/icon.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 40),
          // 5 pontinhos animados estilo Facebook
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return AnimatedDot(delay: index * 200);
            }),
          ),
        ],
      ),
    );
  }
}