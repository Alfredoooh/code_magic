// lib/widgets/wallet_card.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'dart:math' as math;

class WalletCard extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String cardStyle;
  final Function(String)? onStyleChanged;
  final bool showCustomizeButton;

  const WalletCard({
    required this.userData,
    required this.cardStyle,
    this.onStyleChanged,
    this.showCustomizeButton = true,
    Key? key,
  }) : super(key: key);

  void _showCardStylePicker(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 450,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Escolha o Estilo do Cartão',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildStyleOption(context, 'aurora', 'Aurora', CupertinoIcons.sparkles, isDark),
                  _buildStyleOption(context, 'ocean', 'Ocean', CupertinoIcons.wind, isDark),
                  _buildStyleOption(context, 'carbon', 'Carbon', CupertinoIcons.layers_alt_fill, isDark),
                  _buildStyleOption(context, 'sunset', 'Sunset', CupertinoIcons.sun_max_fill, isDark),
                  _buildStyleOption(context, 'midnight', 'Midnight', CupertinoIcons.moon_stars_fill, isDark),
                  _buildStyleOption(context, 'emerald', 'Emerald', CupertinoIcons.leaf_arrow_circlepath, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(BuildContext context, String style, String name, IconData icon, bool isDark) {
    final isSelected = cardStyle == style;

    return GestureDetector(
      onTap: () async {
        onStyleChanged?.call(style);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'cardStyle': style});
        }
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFFFF444F).withOpacity(0.2)
              : (isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFFFF444F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? Color(0xFFFF444F) : CupertinoColors.systemGrey,
            ),
            SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Color(0xFFFF444F) 
                    : (isDark ? CupertinoColors.white : CupertinoColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (cardStyle) {
      case 'aurora':
        return _buildAuroraCard(context);
      case 'ocean':
        return _buildOceanCard(context);
      case 'carbon':
        return _buildCarbonCard(context);
      case 'sunset':
        return _buildSunsetCard(context);
      case 'midnight':
        return _buildMidnightCard(context);
      case 'emerald':
        return _buildEmeraldCard(context);
      default:
        return _buildAuroraCard(context);
    }
  }

  // Aurora Card - Inspirado em American Express
  Widget _buildAuroraCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                    Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: WavyLinesPainter(color: Colors.white.withOpacity(0.1)),
            ),
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _buildCardContent(context, Colors.white),
          ],
        ),
      ),
    );
  }

  // Ocean Card - Tons de azul/verde como Mastercard
  Widget _buildOceanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0891B2).withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0E7490),
                    Color(0xFF0891B2),
                    Color(0xFF06B6D4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: CircularPatternPainter(color: Colors.white.withOpacity(0.08)),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 40,
                  ),
                ),
              ),
            ),
            _buildCardContent(context, Colors.white),
          ],
        ),
      ),
    );
  }

  // Carbon Card - Preto com linhas texturizadas
  Widget _buildCarbonCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF1A1A1A),
                    Color(0xFF0F0F0F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: CarbonFiberPainter(),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFF444F).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _buildCardContent(context, Colors.white),
          ],
        ),
      ),
    );
  }

  // Sunset Card - Laranja/Rosa vibrante
  Widget _buildSunsetCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF59E0B).withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF59E0B),
                    Color(0xFFF97316),
                    Color(0xFFEF4444),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: TopographicPainter(color: Colors.white.withOpacity(0.1)),
            ),
            _buildCardContent(context, Colors.white),
          ],
        ),
      ),
    );
  }

  // Midnight Card - Azul escuro estrelado
  Widget _buildMidnightCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E3A8A).withOpacity(0.5),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF334155),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: StarfieldPainter(),
            ),
            _buildCardContent(context, Colors.white),
          ],
        ),
      ),
    );
  }

  // Emerald Card - Verde esmeralda com padrão
  Widget _buildEmeraldCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF059669).withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF059669),
                    Color(0xFF10B981),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: HexagonPatternPainter(color: Colors.white.withOpacity(0.08)),
            ),
            Positioned(
              bottom: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _buildCardContent(context, Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, Color textColor) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOKENS',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final tokens = snapshot.data?.data() != null
                          ? (snapshot.data!.data() as Map<String, dynamic>)['tokens'] ?? 0
                          : 0;
                      return Text(
                        '$tokens',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Visibility(
                visible: showCustomizeButton,
                child: GestureDetector(
                  onTap: () => _showCardStylePicker(context),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userData?['pro'] == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.star_fill, color: textColor, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'PRO MEMBER',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_getExpirationDays()} DIAS',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              SizedBox(height: 10),
              Text(
                (userData?['username'] ?? 'UTILIZADOR').toUpperCase(),
                style: TextStyle(
                  color: textColor.withOpacity(0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getExpirationDays() {
    if (userData?['expiration_date'] == null) return '0';
    try {
      final date = DateTime.parse(userData!['expiration_date']);
      final diff = date.difference(DateTime.now()).inDays;
      return diff > 0 ? '$diff' : '0';
    } catch (e) {
      return '0';
    }
  }
}

// Painters para padrões decorativos

class WavyLinesPainter extends CustomPainter {
  final Color color;
  WavyLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final path = Path();
      final y = size.height * 0.15 * i;
      path.moveTo(0, y);
      
      for (double x = 0; x <= size.width; x += 20) {
        path.lineTo(x, y + math.sin(x * 0.05) * 8);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularPatternPainter extends CustomPainter {
  final Color color;
  CircularPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double r = 20; r < 300; r += 20) {
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CarbonFiberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += 4) {
      for (double j = 0; j < size.height; j += 4) {
        if ((i + j) % 8 == 0) {
          canvas.drawRect(Rect.fromLTWH(i, j, 2, 2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TopographicPainter extends CustomPainter {
  final Color color;
  TopographicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      final yOffset = i * 25.0;
      path.moveTo(0, yOffset);
      
      for (double x = 0; x <= size.width; x += 30) {
        final y = yOffset + math.sin(x * 0.03 + i) * 15;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final size = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.5 + 0.3;
      
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonPatternPainter extends CustomPainter {
  final Color color;
  HexagonPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final hexSize = 30.0;
    for (double y = 0; y < size.height + hexSize; y += hexSize * 1.5) {
      for (double x = 0; x < size.width + hexSize; x += hexSize * math.sqrt(3)) {
        final offset = (y / (hexSize * 1.5)) % 2 == 0 ? 0.0 : hexSize * math.sqrt(3) / 2;
        _drawHexagon(canvas, Offset(x + offset, y), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}