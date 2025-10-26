# Flutter Material Design 3 Theme System

Complete implementation of Material Design 3 (M3) Expressive theme system for Flutter applications.

## 📁 File Structure

```
lib/
├── theme/
│   ├── app_colors.dart      # Color palette and semantic colors
│   ├── app_typography.dart  # Typography scale and text styles
│   ├── app_theme.dart       # Complete theme configuration
│   └── app_widgets.dart     # Reusable UI components
```

## 🚀 Installation

### 1. Add files to your project

Copy the four files into your `lib/theme/` directory:
- `app_colors.dart`
- `app_typography.dart`
- `app_theme.dart`
- `app_widgets.dart`

### 2. Import in your main.dart

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter M3 App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: _toggleTheme),
    );
  }
}
```

### 3. Using Theme Switcher in Settings

```dart
import 'settings_screen.dart';

// In your app navigation:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SettingsScreen(
      onThemeChanged: () {
        // This will be called from your main app
        // to update the theme
      },
    ),
  ),
);
```

### 4. Complete Main.dart Example with Settings

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_widgets.dart';
import 'settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: _toggleTheme),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final VoidCallback onThemeChanged;

  const HomeScreen({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Home',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onThemeChanged: onThemeChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome!',
              style: context.textStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Go to Settings',
              icon: Icons.settings_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onThemeChanged: onThemeChanged,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎨 Color System

### Using Colors

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Direct color access
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.onPrimary),
  ),
)

// Using theme colors (recommended)
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
  ),
)

// Using context extensions
Container(
  color: context.primary,
  child: Text('Hello'),
)
```

### Available Color Categories

**Primary Colors**
- `AppColors.primary` - Main brand color
- `AppColors.onPrimary` - Text/icons on primary
- `AppColors.primaryContainer` - Containers with primary theme
- `AppColors.onPrimaryContainer` - Content on primary containers

**Status Colors**
- `AppColors.success` - Success states (green)
- `AppColors.error` - Error states (red)
- `AppColors.warning` - Warning states (orange)
- `AppColors.info` - Info states (blue)

**Surface Colors**
- Dark theme: `darkBackground`, `darkSurface`, `darkSurfaceVariant`
- Light theme: `lightBackground`, `lightSurface`, `lightSurfaceVariant`

**Text Colors**
- Dark theme: `darkTextPrimary`, `darkTextSecondary`, `darkTextTertiary`
- Light theme: `lightTextPrimary`, `lightTextSecondary`, `lightTextTertiary`

## ✍️ Typography

### Using Text Styles

```dart
import '../theme/app_typography.dart';

Text(
  'Display Large',
  style: AppTypography.displayLarge,
)

// With theme (adapts to dark/light mode)
Text(
  'Headline',
  style: Theme.of(context).textTheme.headlineLarge,
)

// With context extension
Text(
  'Body Text',
  style: context.textStyles.bodyMedium,
)
```

### Typography Scale

| Style | Size | Weight | Use Case |
|-------|------|--------|----------|
| `displayLarge` | 57sp | 400 | Hero text, large headlines |
| `displayMedium` | 45sp | 400 | Important headers |
| `displaySmall` | 36sp | 400 | Section headers |
| `headlineLarge` | 32sp | 400 | Page titles |
| `headlineMedium` | 28sp | 400 | Card headers |
| `headlineSmall` | 24sp | 400 | List headers |
| `titleLarge` | 22sp | 400 | Prominent titles |
| `titleMedium` | 16sp | 500 | Card titles |
| `titleSmall` | 14sp | 500 | List item titles |
| `bodyLarge` | 16sp | 400 | Long-form text |
| `bodyMedium` | 14sp | 400 | Default body text |
| `bodySmall` | 12sp | 400 | Captions, helper text |
| `labelLarge` | 14sp | 500 | Buttons, tabs |
| `labelMedium` | 12sp | 500 | Chip labels |
| `labelSmall` | 11sp | 500 | Small labels |

## 📏 Spacing System

Based on 4dp grid system:

```dart
import '../theme/app_theme.dart';

Container(
  padding: EdgeInsets.all(AppSpacing.md),
  margin: EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  ),
)
```

### Available Spacing

| Name | Value | Use Case |
|------|-------|----------|
| `xxs` | 2dp | Micro spacing |
| `xs` | 4dp | Tight spacing |
| `sm` | 8dp | Small spacing |
| `md` | 12dp | Medium spacing |
| `lg` | 16dp | Standard spacing |
| `xl` | 20dp | Large spacing |
| `xxl` | 24dp | Extra large spacing |
| `xxxl` | 32dp | Section spacing |
| `huge` | 40dp | Major sections |
| `massive` | 48dp | Page-level spacing |

### Border Radius

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  ),
)
```

| Name | Value |
|------|-------|
| `radiusXs` | 4dp |
| `radiusSm` | 8dp |
| `radiusMd` | 12dp |
| `radiusLg` | 16dp |
| `radiusXl` | 28dp |
| `radiusFull` | 9999dp |

## 🎭 Shapes

Pre-configured shape styles:

```dart
Container(
  decoration: ShapeDecoration(
    shape: AppShapes.shapeMedium,
    color: Colors.blue,
  ),
)

// Or use values directly
BorderRadius.circular(AppShapes.medium)
```

### Available Shapes

- `shapeNone` - No rounding (0dp)
- `shapeExtraSmall` - 4dp radius
- `shapeSmall` - 8dp radius
- `shapeMedium` - 12dp radius
- `shapeLarge` - 16dp radius
- `shapeExtraLarge` - 28dp radius
- `shapeFull` - Fully rounded (9999dp)

## ⚡ Motion & Animation

### Duration Constants

```dart
AnimatedContainer(
  duration: AppMotion.medium,
  curve: AppMotion.standardEasing,
  // ...
)
```

| Duration | Value | Use Case |
|----------|-------|----------|
| `instant` | 0ms | No animation |
| `veryShort` | 50ms | Micro interactions |
| `short` | 100ms | Quick transitions |
| `medium` | 200ms | Standard transitions |
| `long` | 300ms | Emphasized transitions |
| `veryLong` | 400ms | Complex animations |
| `extraLong` | 500ms | Page transitions |

### Easing Curves

- `standardEasing` - Default M3 curve (easeInOutCubicEmphasized)
- `emphasizedDecelerate` - Entering animations
- `emphasizedAccelerate` - Exiting animations
- `linear` - Constant speed

### Spring Animations

```dart
SpringDescription spring = AppMotion.mediumSpring;

// Available springs:
// - fastSpring (quick, snappy)
// - mediumSpring (balanced)
// - slowSpring (smooth, gentle)
```

## 🎯 Haptic Feedback

```dart
import '../theme/app_theme.dart';

// Light tap feedback
AppHaptics.light();

// Selection feedback
AppHaptics.selection();

// Success feedback
AppHaptics.success();

// Error feedback
AppHaptics.error();
```

## 🌓 Theme Mode Management

### Method 1: Using StatefulWidget (Recommended)

```dart
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: _toggleTheme),
    );
  }
}
```

### Method 2: With SharedPreferences (Persistent)

```dart
import 'package:shared_preferences/shared_preferences.dart';

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    
    setState(() => _themeMode = newMode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(onThemeChanged: _toggleTheme),
    );
  }
}
```

### Method 3: With Provider (State Management)

First, add provider to pubspec.yaml:
```yaml
dependencies:
  provider: ^6.0.0
```

Create a theme provider:
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
  }
}
```

Use in main.dart:
```dart
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
```

Use in SettingsScreen:
```dart
// Toggle theme
Provider.of<ThemeProvider>(context, listen: false).toggleTheme();

// Or with context.read
context.read<ThemeProvider>().toggleTheme();

// Check if dark
final isDark = context.watch<ThemeProvider>().isDark;
```

### Using in Settings Screen

The included `SettingsScreen` already has theme switching built-in:

```dart
// Navigate to settings with theme callback
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SettingsScreen(
      onThemeChanged: _toggleTheme, // Your toggle function
    ),
  ),
);
```

Or with Provider:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SettingsScreen(
      onThemeChanged: () {
        context.read<ThemeProvider>().toggleTheme();
      },
    ),
  ),
);
```

## 🔧 Context Extensions

Convenient shortcuts for accessing theme values:

```dart
// Colors
context.colors          // Full ColorScheme
context.surface         // Surface color
context.primary         // Primary color
context.error           // Error color
context.success         // Success color
context.warning         // Warning color

// Typography
context.textStyles      // Full TextTheme

// Theme info
context.isDark          // bool: is dark mode active
```

### Example Usage

```dart
Widget build(BuildContext context) {
  return Container(
    color: context.surface,
    child: Text(
      'Hello World',
      style: context.textStyles.headlineMedium?.copyWith(
        color: context.primary,
      ),
    ),
  );
}
```

## 📦 Common Patterns

### Card with spacing

```dart
Card(
  margin: EdgeInsets.all(AppSpacing.md),
  child: Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        Text('Title', style: context.textStyles.titleLarge),
        SizedBox(height: AppSpacing.sm),
        Text('Subtitle', style: context.textStyles.bodyMedium),
      ],
    ),
  ),
)
```

### Animated button

```dart
GestureDetector(
  onTap: () {
    AppHaptics.selection();
    // Handle tap
  },
  child: AnimatedContainer(
    duration: AppMotion.short,
    curve: AppMotion.standardEasing,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    decoration: BoxDecoration(
      color: context.primary,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Text(
      'Button',
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.onPrimary,
      ),
    ),
  ),
)
```

### Themed container with status color

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.success.withOpacity(0.15),
    border: Border.all(color: AppColors.success),
    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
  ),
  child: Row(
    children: [
      Icon(Icons.check_circle, color: AppColors.success),
      SizedBox(width: AppSpacing.sm),
      Text(
        'Success message',
        style: context.textStyles.bodyMedium?.copyWith(
          color: AppColors.success,
        ),
      ),
    ],
  ),
)
```

## 🔍 Troubleshooting

### Compilation Errors

**Error: "Member not found: 'radiusXl'"**
- Solution: Use `AppSpacing.radiusXl` instead of `AppShapes.radiusXl`

**Error: "Const evaluation error with darkOutline"**
- Solution: Colors with opacity can't be const. Use getters instead:
  ```dart
  color: AppColors.darkOutline  // getter, not const
  ```

**Error: "The method 'X' isn't defined"**
- Solution: Import the correct file:
  ```dart
  import 'theme/app_theme.dart';
  import 'theme/app_colors.dart';
  import 'theme/app_typography.dart';
  ```

### Context Extensions Not Working

Make sure you import `app_theme.dart`:
```dart
import 'theme/app_theme.dart';
```

## 📱 Responsive Design

### Breakpoints (recommended)

```dart
class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 900.0;
  static const desktop = 1200.0;
}

// Usage
bool isMobile = MediaQuery.of(context).size.width < Breakpoints.mobile;
double padding = isMobile ? AppSpacing.md : AppSpacing.xl;
```

## 🎨 Customization

### Changing Primary Color

In `app_colors.dart`:
```dart
static const primary = Color(0xFFYourColor);
```

### Adding Custom Colors

In `app_colors.dart`:
```dart
static const customColor = Color(0xFF123456);
```

### Custom Typography

In `app_typography.dart`:
```dart
static const customStyle = TextStyle(
  fontFamily: fontFamily,
  fontSize: 18,
  fontWeight: FontWeight.w600,
);
```

## 📚 Additional Resources

- [Material Design 3 Guidelines](https://m3.material.io/)
- [Flutter Material 3](https://docs.flutter.dev/ui/design/material)
- [Color System](https://m3.material.io/styles/color/overview)
- [Typography Scale](https://m3.material.io/styles/typography/overview)

## 🧩 UI Components (app_widgets.dart)

### AppBars

**Primary AppBar** - For main screens (Home, Dashboard)
```dart
PrimaryAppBar(
  title: 'Home',
  actions: [
    IconButton(icon: Icon(Icons.settings), onPressed: () {}),
  ],
)
```

**Secondary AppBar** - For detail/child screens
```dart
SecondaryAppBar(
  title: 'Details',
  onBack: () => Navigator.pop(context),
)
```

**Transparent AppBar** - With blur effect
```dart
TransparentAppBar(
  title: 'Overlay',
  backgroundColor: Colors.black.withOpacity(0.3),
)
```

### Cards

**Standard Card**
```dart
AppCard(
  padding: EdgeInsets.all(AppSpacing.lg),
  onTap: () => print('Tapped'),
  child: Text('Content'),
)
```

**Animated Card** - With scale animation
```dart
AnimatedCard(
  onTap: () => print('Animated tap'),
  child: Column(
    children: [
      Text('Title', style: context.textStyles.titleLarge),
      Text('Subtitle'),
    ],
  ),
)
```

**Elevated Card** - Higher elevation
```dart
ElevatedCard(
  child: Text('Important content'),
)
```

**Outlined Card** - With border
```dart
OutlinedCard(
  borderColor: AppColors.primary,
  child: Text('Outlined content'),
)
```

**Glass Card** - Glassmorphism effect
```dart
GlassCard(
  blur: 15,
  opacity: 0.3,
  child: Text('Glass effect'),
)
```

### Modals & Bottom Sheets

**Modal Bottom Sheet**
```dart
AppModalBottomSheet.show(
  context: context,
  title: 'Select Option',
  child: ListView(
    shrinkWrap: true,
    children: [
      ListTile(title: Text('Option 1')),
      ListTile(title: Text('Option 2')),
    ],
  ),
);
```

**Full Screen Modal**
```dart
FullScreenModal.show(
  context: context,
  title: 'Full Screen',
  child: YourContentWidget(),
);
```

**Dialog**
```dart
AppDialog.show(
  context: context,
  title: 'Confirm',
  content: 'Are you sure?',
  icon: Icons.warning_rounded,
  iconColor: AppColors.warning,
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    FilledButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text('Confirm'),
    ),
  ],
);
```

### Buttons

**Primary Button** (Filled)
```dart
PrimaryButton(
  text: 'Save',
  icon: Icons.save_rounded,
  onPressed: () => print('Saved'),
  loading: false,
  expanded: true, // Full width
)
```

**Secondary Button** (Outlined)
```dart
SecondaryButton(
  text: 'Cancel',
  icon: Icons.close_rounded,
  onPressed: () => Navigator.pop(context),
)
```

**Tertiary Button** (Text)
```dart
TertiaryButton(
  text: 'Learn More',
  icon: Icons.arrow_forward_rounded,
  onPressed: () {},
)
```

**Icon Button with Background**
```dart
IconButtonWithBackground(
  icon: Icons.favorite_rounded,
  onPressed: () => print('Liked'),
  backgroundColor: AppColors.error.withOpacity(0.15),
  iconColor: AppColors.error,
  size: 56,
)
```

### Specialized Cards

**Info Card**
```dart
InfoCard(
  icon: Icons.account_balance_wallet_rounded,
  title: 'Balance',
  subtitle: '\$1,234.56',
  color: AppColors.success,
  onTap: () => print('View balance'),
)
```

**Stats Card**
```dart
StatsCard(
  label: 'Total Sales',
  value: '\$45,230',
  icon: Icons.trending_up_rounded,
  color: AppColors.success,
  subtitle: '+12.5% from last month',
  onTap: () => print('View stats'),
)
```

**Action Card**
```dart
ActionCard(
  title: 'Complete Profile',
  description: 'Add your personal information to unlock features',
  icon: Icons.person_rounded,
  actionText: 'Complete Now',
  onAction: () => print('Navigate to profile'),
  color: AppColors.primary,
)
```

### List Items

**Standard List Tile**
```dart
AppListTile(
  title: 'Settings',
  subtitle: 'Manage your preferences',
  leading: Icon(Icons.settings_rounded),
  trailing: Icon(Icons.chevron_right_rounded),
  onTap: () => print('Open settings'),
)
```

**Transaction List Item**
```dart
TransactionListItem(
  title: 'Payment Received',
  subtitle: 'From: John Doe',
  amount: 250.00,
  icon: Icons.arrow_downward_rounded,
  onTap: () => print('View transaction'),
)
```

### Utility Widgets

**Empty State**
```dart
EmptyState(
  icon: Icons.inbox_rounded,
  title: 'No Messages',
  subtitle: 'You don\'t have any messages yet',
  actionText: 'Compose Message',
  onAction: () => print('Open composer'),
)
```

**Loading Overlay**
```dart
LoadingOverlay(
  isLoading: _isLoading,
  message: 'Please wait...',
  child: YourContentWidget(),
)
```

**Badge**
```dart
AppBadge(
  text: 'New',
  color: AppColors.success,
  outlined: false,
)
```

**Labeled Divider**
```dart
LabeledDivider(label: 'OR')
```

**Skeleton Loader**
```dart
SkeletonLoader(
  width: double.infinity,
  height: 100,
  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
)
```

### Animations

**Fade In Widget**
```dart
FadeInWidget(
  duration: AppMotion.medium,
  delay: Duration(milliseconds: 200),
  child: YourWidget(),
)
```

**Staggered List**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return StaggeredListItem(
      index: index,
      delay: Duration(milliseconds: 50),
      child: YourListItemWidget(),
    );
  },
)
```

### Input Fields

**Standard Text Field**
```dart
AppTextField(
  label: 'Email',
  hint: 'Enter your email',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Required';
    return null;
  },
  prefix: Icon(Icons.email_rounded),
)
```

**Search Field**
```dart
SearchField(
  hint: 'Search products...',
  controller: _searchController,
  onChanged: (value) => _performSearch(value),
  onClear: () => _clearSearch(),
)
```

### Segmented Button

```dart
SegmentedButtonGroup<String>(
  values: ['Day', 'Week', 'Month'],
  selected: _selectedPeriod,
  onChanged: (value) => setState(() => _selectedPeriod = value),
  labelBuilder: (value) => value,
  iconBuilder: (value) {
    switch (value) {
      case 'Day': return Icons.today_rounded;
      case 'Week': return Icons.date_range_rounded;
      case 'Month': return Icons.calendar_month_rounded;
      default: return Icons.circle;
    }
  },
)
```

### Snackbars

```dart
// Success
AppSnackbar.success(context, 'Saved successfully!');

// Error
AppSnackbar.error(context, 'Something went wrong');

// Warning
AppSnackbar.warning(context, 'Please review your input');

// Info
AppSnackbar.info(context, 'Update available');

// Custom
AppSnackbar.show(
  context,
  message: 'Custom message',
  icon: Icons.star_rounded,
  backgroundColor: AppColors.tertiary,
  action: SnackBarAction(
    label: 'UNDO',
    onPressed: () {},
  ),
);
```

## 🎯 Complete Screen Examples

### Main Screen with Primary AppBar
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          StatsCard(
            label: 'Total Balance',
            value: '\$12,450',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
          ),
          SizedBox(height: AppSpacing.md),
          InfoCard(
            icon: Icons.trending_up_rounded,
            title: 'Monthly Growth',
            subtitle: '+15.3% this month',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}
```

### Detail Screen with Secondary AppBar
```dart
class DetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(
        title: 'Transaction Details',
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  Text('Amount', style: context.textStyles.bodySmall),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '\$250.00',
                    style: context.textStyles.headlineLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            OutlinedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: context.textStyles.titleMedium),
                  SizedBox(height: AppSpacing.sm),
                  LabeledDivider(label: 'Information'),
                  // More content...
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Modal Example
```dart
void _showOptions(BuildContext context) {
  AppModalBottomSheet.show(
    context: context,
    title: 'Choose Action',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppListTile(
          title: 'Edit',
          leading: Icon(Icons.edit_rounded),
          onTap: () {
            Navigator.pop(context);
            // Edit action
          },
        ),
        AppListTile(
          title: 'Share',
          leading: Icon(Icons.share_rounded),
          onTap: () {
            Navigator.pop(context);
            // Share action
          },
        ),
        AppListTile(
          title: 'Delete',
          leading: Icon(Icons.delete_rounded, color: AppColors.error),
          onTap: () {
            Navigator.pop(context);
            _confirmDelete(context);
          },
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context) {
  AppDialog.show(
    context: context,
    title: 'Delete Item',
    content: 'Are you sure you want to delete this item?',
    icon: Icons.delete_rounded,
    iconColor: AppColors.error,
    actions: [
      TertiaryButton(
        text: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
      PrimaryButton(
        text: 'Delete',
        onPressed: () {
          Navigator.pop(context);
          AppSnackbar.success(context, 'Item deleted');
        },
      ),
    ],
  );
}
```

## 📄 License

This theme system is provided as-is for use in Flutter applications following Material Design 3 guidelines.

---

**Version:** 1.0.0  
**Last Updated:** 2025  
**Compatible with:** Flutter 3.0+