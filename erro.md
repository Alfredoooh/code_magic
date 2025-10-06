
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
Running Gradle task 'assembleRelease'...

lib/screens/webview_screen.dart:122:39: Error: Local variable 'newController' can't be referenced before it is declared.

final pageTitle = await newController.getTitle() ?? title;

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:98:11: Context: This is the declaration of the variable 'newController'.

final newController = WebViewController()

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:122:39: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

final pageTitle = await newController.getTitle() ?? title;

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:155:27: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

_setupScrollDetection(newController);

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:156:5: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

newController.loadRequest(Uri.parse(url));

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:162:19: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

controller: newController,

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:862:47: Error: The getter 'CupertinoEntendoIcons' isn't defined for the class '_TabCard'.

- '_TabCard' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'CupertinoEntendoIcons'.

child: Center(child: Icon(CupertinoEntendoIcons.globe, size: 52, color: tab.primaryColor ?? primaryColor)),

^^^^^^^^^^^^^^^^^^^^^

Target kernel_snapshot_program failed: Exception

FAILURE: Build failed with an exception.

* What went wrong:

Execution failed for task ':app:compileFlutterBuildRelease'.

> Process 'command '/opt/flutter/bin/flutter'' finished with non-zero exit value 1

* Try:

> Run with --stacktrace option to get the stack trace.

> Run with --info or --debug option to get more log output.

> Run with --scan to get full insights.

> Get more help at https://help.gradle.org.

BUILD FAILED in 42s

Running Gradle task 'assembleRelease'...

43.1s

Gradle task assembleRelease failed with exit code 1

Process finished with exit code 1

Running Gradle task 'assembleRelease'...

lib/screens/webview_screen.dart:122:39: Error: Local variable 'newController' can't be referenced before it is declared.

final pageTitle = await newController.getTitle() ?? title;

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:98:11: Context: This is the declaration of the variable 'newController'.

final newController = WebViewController()

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:122:39: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

final pageTitle = await newController.getTitle() ?? title;

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:155:27: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

_setupScrollDetection(newController);

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:156:5: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

newController.loadRequest(Uri.parse(url));

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:162:19: Error: The getter 'newController' isn't defined for the class '_WebViewScreenState'.

- '_WebViewScreenState' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'newController'.

controller: newController,

^^^^^^^^^^^^^

lib/screens/webview_screen.dart:862:47: Error: The getter 'CupertinoEntendoIcons' isn't defined for the class '_TabCard'.

- '_TabCard' is from 'package:madeeasy/screens/webview_screen.dart' ('lib/screens/webview_screen.dart').

Try correcting the name to the name of an existing getter, or defining a getter or field named 'CupertinoEntendoIcons'.

child: Center(child: Icon(CupertinoEntendoIcons.globe, size: 52, color: tab.primaryColor ?? primaryColor)),

^^^^^^^^^^^^^^^^^^^^^

Target kernel_snapshot_program failed: Exception

FAILURE: Build failed with an exception.

* What went wrong:

Execution failed for task ':app:compileFlutterBuildRelease'.

> Process 'command '/opt/flutter/bin/flutter'' finished with non-zero exit value 1

* Try:

> Run with --stacktrace option to get the stack trace.

> Run with --info or --debug option to get more log output.

> Run with --scan to get full insights.

> Get more help at https://help.gradle.org.

BUILD FAILED in 42s

Running Gradle task 'assembleRelease'...

43.1s

Gradle task assembleRelease failed with exit code 1

Process finished with exit code 1

========== 🏁 Build finished at Tuesday, September 30th 2025, 1:43:11 +01:00 🏁 ==========










​