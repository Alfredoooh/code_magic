import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../svg_icons.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final Color surfaceColor;
  final Color borderColor;
  final Color subTextColor;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.surfaceColor,
    required this.borderColor,
    required this.subTextColor,
  }) : super(key: key);

  static const String _tvOutlineSvg = '''<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" id="Outline" viewBox="0 0 24 24" width="512" height="512"><path d="M19,3H5A5.006,5.006,0,0,0,0,8v6a5.006,5.006,0,0,0,5,5h6v1H8a1,1,0,0,0,0,2h8a1,1,0,0,0,0-2H13V19h6a5.006,5.006,0,0,0,5-5V8A5.006,5.006,0,0,0,19,3Zm3,11a3,3,0,0,1-3,3H5a3,3,0,0,1-3-3V8A3,3,0,0,1,5,5H19a3,3,0,0,1,3,3Z"/></svg>''';

  static const String _tvFilledSvg = '''<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" id="Filled" viewBox="0 0 24 24" width="512" height="512"><path d="M19,3H5A5.006,5.006,0,0,0,0,8v6a5.006,5.006,0,0,0,5,5h6v1H8a1,1,0,0,0,0,2h8a1,1,0,0,0,0-2H13V19h6a5.006,5.006,0,0,0,5-5V8A5.006,5.006,0,0,0,19,3Z"/></svg>''';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                SvgIcons.homeOutline,
                SvgIcons.homeFilled,
                'Início',
                0,
              ),
              _buildNavItem(
                SvgIcons.matchesOutline,
                SvgIcons.matchesFilled,
                'Partidas',
                1,
              ),
              _buildNavItem(
                _tvOutlineSvg,
                _tvFilledSvg,
                'TV',
                2,
                inactiveColor: const Color(0xFF9AA0A6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String outlinedSvg,
    String filledSvg,
    String label,
    int index, {
    Color? inactiveColor,
  }) {
    final isSelected = selectedIndex == index;
    final Color colorInactive = inactiveColor ?? subTextColor;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            isSelected ? filledSvg : outlinedSvg,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? const Color(0xFF2374E1) : colorInactive,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF2374E1) : colorInactive,
            ),
          ),
        ],
      ),
    );
  }
}