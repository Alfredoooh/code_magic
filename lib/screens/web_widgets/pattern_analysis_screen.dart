import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PatternAnalysisScreen extends StatefulWidget {
  final GlobalKey webViewKey;

  const PatternAnalysisScreen({
    Key? key,
    required this.webViewKey,
  }) : super(key: key);

  @override
  _PatternAnalysisScreenState createState() => _PatternAnalysisScreenState();
}

class _PatternAnalysisScreenState extends State<PatternAnalysisScreen> {
  List<DrawingLine> _lines = [];
  DrawingLine? _currentLine;
  Color _selectedColor = Color(0xFFFF444F);
  double _selectedWidth = 3.0;
  DrawingTool _selectedTool = DrawingTool.line;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Drawing Canvas
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentLine = DrawingLine(
                  points: [details.localPosition],
                  color: _selectedColor,
                  width: _selectedWidth,
                  tool: _selectedTool,
                );
              });
            },
            onPanUpdate: (details) {
              setState(() {
                if (_currentLine != null) {
                  _currentLine = DrawingLine(
                    points: [..._currentLine!.points, details.localPosition],
                    color: _currentLine!.color,
                    width: _currentLine!.width,
                    tool: _currentLine!.tool,
                  );
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                if (_currentLine != null) {
                  _lines.add(_currentLine!);
                  _currentLine = null;
                }
              });
            },
            child: CustomPaint(
              painter: DrawingPainter(
                lines: _lines,
                currentLine: _currentLine,
              ),
              size: Size.infinite,
            ),
          ),
          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF9F9F9),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Color(0xFF38383A) : Color(0xFFE5E5EA),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolButton(
                      icon: CupertinoIcons.pencil,
                      isSelected: _selectedTool == DrawingTool.line,
                      onTap: () {
                        setState(() {
                          _selectedTool = DrawingTool.line;
                        });
                      },
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.minus,
                      isSelected: _selectedTool == DrawingTool.straightLine,
                      onTap: () {
                        setState(() {
                          _selectedTool = DrawingTool.straightLine;
                        });
                      },
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.circle,
                      isSelected: _selectedTool == DrawingTool.circle,
                      onTap: () {
                        setState(() {
                          _selectedTool = DrawingTool.circle;
                        });
                      },
                    ),
                    _buildToolButton(
                      icon: CupertinoIcons.rectangle,
                      isSelected: _selectedTool == DrawingTool.rectangle,
                      onTap: () {
                        setState(() {
                          _selectedTool = DrawingTool.rectangle;
                        });
                      },
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minSize: 0,
                      onPressed: _showColorPicker,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black87,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minSize: 0,
                      onPressed: () {
                        setState(() {
                          if (_lines.isNotEmpty) {
                            _lines.removeLast();
                          }
                        });
                      },
                      child: Icon(
                        CupertinoIcons.arrow_uturn_left,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 24,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minSize: 0,
                      onPressed: () {
                        setState(() {
                          _lines.clear();
                        });
                      },
                      child: Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.systemRed,
                        size: 24,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minSize: 0,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 8),
      minSize: 0,
      onPressed: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDark ? Colors.white : Colors.black87),
          size: 24,
        ),
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      Color(0xFFFF444F),
      Color(0xFF00C7BE),
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemYellow,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      Colors.white,
      Colors.black,
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Text(
              'Escolher Cor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colors[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DrawingTool {
  line,
  straightLine,
  circle,
  rectangle,
}

class DrawingLine {
  final List<Offset> points;
  final Color color;
  final double width;
  final DrawingTool tool;

  DrawingLine({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLine> lines;
  final DrawingLine? currentLine;

  DrawingPainter({
    required this.lines,
    this.currentLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      _drawLine(canvas, line);
    }
    if (currentLine != null) {
      _drawLine(canvas, currentLine!);
    }
  }

  void _drawLine(Canvas canvas, DrawingLine line) {
    final paint = Paint()
      ..color = line.color
      ..strokeWidth = line.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (line.points.isEmpty) return;

    switch (line.tool) {
      case DrawingTool.line:
        final path = Path();
        path.moveTo(line.points.first.dx, line.points.first.dy);
        for (var point in line.points) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
        break;

      case DrawingTool.straightLine:
        if (line.points.length >= 2) {
          canvas.drawLine(
            line.points.first,
            line.points.last,
            paint,
          );
        }
        break;

      case DrawingTool.circle:
        if (line.points.length >= 2) {
          final center = line.points.first;
          final radius = (line.points.last - center).distance;
          canvas.drawCircle(center, radius, paint);
        }
        break;

      case DrawingTool.rectangle:
        if (line.points.length >= 2) {
          final rect = Rect.fromPoints(
            line.points.first,
            line.points.last,
          );
          canvas.drawRect(rect, paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}