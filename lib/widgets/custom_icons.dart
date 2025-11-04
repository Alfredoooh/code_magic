// lib/widgets/custom_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomIcons {
  // Ícones atualizados com SVG mais limpos e modernos
  static const String home = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
      <polyline points="9 22 9 12 15 12 15 22"/>
    </svg>
  ''';

  static const String users = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
      <circle cx="9" cy="7" r="4"/>
      <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
      <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
    </svg>
  ''';

  static const String plus = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
      <line x1="12" y1="5" x2="12" y2="19"/>
      <line x1="5" y1="12" x2="19" y2="12"/>
    </svg>
  ''';

  static const String bell = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
      <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
    </svg>
  ''';

  static const String menu = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <line x1="3" y1="6" x2="21" y2="6"/>
      <line x1="3" y1="12" x2="21" y2="12"/>
      <line x1="3" y1="18" x2="21" y2="18"/>
    </svg>
  ''';

  static const String search = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="11" cy="11" r="8"/>
      <path d="m21 21-4.35-4.35"/>
    </svg>
  ''';

  static const String inbox = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/>
      <path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>
    </svg>
  ''';

  static const String marketplace = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="m5 11 4-7"/>
      <path d="m19 11-4-7"/>
      <path d="M2 11h20"/>
      <path d="m3.5 11 1.6 7.4a2 2 0 0 0 2 1.6h9.8c.9 0 1.8-.7 2-1.6l1.7-7.4"/>
      <path d="M9 11v5"/>
      <path d="M12 11v5"/>
      <path d="M15 11v5"/>
    </svg>
  ''';

  static const String settings = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="12" cy="12" r="3"/>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
    </svg>
  ''';

  static const String logout = '''
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
      <polyline points="16 17 21 12 16 7"/>
      <line x1="21" y1="12" x2="9" y2="12"/>
    </svg>
  ''';
}

class CustomIcon extends StatelessWidget {
  final String svgString;
  final double size;
  final Color color;
  final BoxFit fit;

  const CustomIcon({
    Key? key,
    required this.svgString,
    this.size = 24.0,
    this.color = Colors.black,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      fit: fit,
    );
  }
}

// Widgets específicos para cada ícone
class HomeIcon extends StatelessWidget {
  final double size;
  final Color color;
  const HomeIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.home,
      size: size,
      color: color,
    );
  }
}

class UsersIcon extends StatelessWidget {
  final double size;
  final Color color;
  const UsersIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.users,
      size: size,
      color: color,
    );
  }
}

class PlusIcon extends StatelessWidget {
  final double size;
  final Color color;
  const PlusIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.plus,
      size: size,
      color: color,
    );
  }
}

class BellIcon extends StatelessWidget {
  final double size;
  final Color color;
  const BellIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.bell,
      size: size,
      color: color,
    );
  }
}

class MenuIcon extends StatelessWidget {
  final double size;
  final Color color;
  const MenuIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.menu,
      size: size,
      color: color,
    );
  }
}

class SearchIcon extends StatelessWidget {
  final double size;
  final Color color;
  const SearchIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.search,
      size: size,
      color: color,
    );
  }
}

class InboxIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InboxIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.inbox,
      size: size,
      color: color,
    );
  }
}

class MarketplaceIcon extends StatelessWidget {
  final double size;
  final Color color;
  const MarketplaceIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.marketplace,
      size: size,
      color: color,
    );
  }
}

class SettingsIcon extends StatelessWidget {
  final double size;
  final Color color;
  const SettingsIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.settings,
      size: size,
      color: color,
    );
  }
}

class LogoutIcon extends StatelessWidget {
  final double size;
  final Color color;
  const LogoutIcon({Key? key, this.size = 24.0, this.color = Colors.black}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomIcon(
      svgString: CustomIcons.logout,
      size: size,
      color: color,
    );
  }
}