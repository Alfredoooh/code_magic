// lib/widgets/custom_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomIcons {
  // Ícone home melhorado - tudo junto
  static const String home = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v4.875h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
</svg>
''';

  static const String share = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7.217 10.907a2.25 2.25 0 1 0 0 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186 9.566-5.314m-9.566 7.5 9.566 5.314m0 0a2.25 2.25 0 1 0 3.935 2.186 2.25 2.25 0 0 0-3.935-2.186zm0-7.5a2.25 2.25 0 1 0 3.935 2.186 2.25 2.25 0 0 0-3.935-2.186z" />
</svg>
''';

  static const String users = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M15 19.128a9.38 9.38 0 0 0 2.625-.372 9.337 9.337 0 0 0 4.121-3.84 9.337 9.337 0 0 0-.372-2.625A5.25 5.25 0 0 0 20.25 9.75M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0z" />
</svg>
''';

  static const String plus = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 4.5v15m7.5-7.5h-15" />
</svg>
''';

  static const String bell = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0" />
</svg>
''';

  static const String menu = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 6h16M4 12h16M4 18h16" />
</svg>
''';

  static const String search = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21 21-4.35-4.35M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z" />
</svg>
''';

  static const String inbox = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M2.25 12.759c0-1.43 1.117-2.59 2.494-2.59h2.015l-2-2M21.75 12.75c0-1.43-1.117-2.59-2.494-2.59h-2.013l2-2m0 5-2 2m-2-2 2 2m-6-2h6" />
</svg>
''';

  static const String marketplace = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349M1 4.5h1.5m18 0h1.5m-7.5 0h3m-15 0h3m-1.5 0H19M4.5 9.75h15V21H4.5V9.75Z" />
</svg>
''';

  static const String settings = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.582.495-.644.869l-.214 1.28c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.755-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" />
  <path d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
</svg>
''';

  static const String logout = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M15.75 9V5.25A2.25 2.25 0 0 0 13.5 3h-6a2.25 2.25 0 0 0-2.25 2.25v13.5A2.25 2.25 0 0 0 7.5 21h6a2.25 2.25 0 0 0 2.25-2.25V15m3-3-3-3m0 0-3 3m3-3v12" />
</svg>
''';

  static const String chevronRight = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m9 18 6-6-6-6" />
</svg>
''';

  static const String chevronLeft = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m15 18-6-6 6-6" />
</svg>
''';

  static const String arrowLeft = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
  <path fill-rule="evenodd" d="M11.03 3.97a.75.75 0 010 1.06l-6.22 6.22H21a.75.75 0 010 1.5H4.81l6.22 6.22a.75.75 0 11-1.06 1.06l-7.5-7.5a.75.75 0 010-1.06l7.5-7.5a.75.75 0 011.06 0z" clip-rule="evenodd" />
</svg>
''';

  static const String envelope = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
</svg>
''';

  static const String trash = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
</svg>
''';

  static const String userCircle = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M15.75 6a3.75 3.75 0 1 1-7.5 0m15 0a8.25 8.25 0 1 1-16.5 0 8.25 8.25 0 0 1 16.5 0zm-7.5 14.624a15.999 15.999 0 0 0 6.75-3.623 5.625 5.625 0 0 0-13.5 0c2.232 1.332 4.803 2.31 7.5 2.623z" />
</svg>
''';

  static const String document = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H9.75m8.25 12V18m-6.75-6.75h6.75m-6.75 3h6.75m-6.75 3h6.75M3.375 7.5h17.25m-17.25 0c0-1.863 1.512-3.375 3.375-3.375h5.25c1.863 0 3.375 1.512 3.375 3.375m-12 8.25c0 1.863 1.512 3.375 3.375 3.375h5.25c1.863 0 3.375-1.512 3.375-3.375m-12 0h12" />
</svg>
''';

  static const String shield = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9 12.75 11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 0 1-1.043 3.296 3.745 3.745 0 0 1-3.296 1.043A3.745 3.745 0 0 1 12 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 0 1-3.296-1.043 3.745 3.745 0 0 1-1.043-3.296A3.745 3.745 0 0 1 3 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 0 1 1.043-3.296 3.746 3.746 0 0 1 3.296-1.043A3.746 3.746 0 0 1 12 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 0 1 3.296 1.043 3.746 3.746 0 0 1 1.043 3.296A3.745 3.745 0 0 1 21 12Z" />
</svg>
''';

  static const String globe = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18Zm0-18v18M21 12H3m9-9v18" />
</svg>
''';

  static const String eye = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
  <path d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
</svg>
''';

  static const String eyeSlash = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88" />
</svg>
''';

  // Ícone check corrigido - limpo e bonito
  static const String check = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m4.5 12.75 6 6 9-13.5" />
</svg>
''';

  // Ícone de erro
  static const String errorIcon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z" />
</svg>
''';

    static const String bookOpen = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18c-2.305 0-4.408.867-6 2.292m0-14.25v14.25" />
</svg>
  ''';

  static const String academicCap = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m4.26 10.147a60.438 60.438 0 0 0-.491 6.347A48.62 48.62 0 0 1 12 20.904a48.62 48.62 0 0 1 8.232-4.41 60.46 60.46 0 0 0-.491-6.347m-16.1 0a2.25 2.25 0 0 1 .44-.901l9.07-9.28a2.25 2.25 0 0 1 3.18 0l9.07 9.28a2.25 2.25 0 0 1 .44.902m-16.1 0a49.94 49.94 0 0 1-2.448-5.4m21 0a49.94 49.94 0 0 0-2.448 5.4m-9.552-5.4 3.18 3.28m-6.36 0 3.18-3.28" />
</svg>
''';

  static const String cog = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 0 1 1.37.49l1.296 2.247a1.125 1.125 0 0 1-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 0 1 0 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 0 1-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 0 1-.22.128c-.331.183-.582.495-.644.869l-.214 1.28c-.09.543-.56.94-1.11.94h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 0 1-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 0 1-1.369-.49l-1.297-2.247a1.125 1.125 0 0 1 .26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 0 1 0-.255c.007-.38-.138-.755-.43-.992l-1.004-.827a1.125 1.125 0 0 1-.26-1.43l1.297-2.247a1.125 1.125 0 0 1 1.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28Z" />
  <path d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
</svg>
''';

  static const String star = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M11.48 3.499a.562.562 0 0 1 1.04 0l2.125 5.111a.563.563 0 0 0 .475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 0 0-.182.557l1.285 5.385a.562.562 0 0 1-.84.61l-4.725-2.885a.562.562 0 0 0-.586 0L6.982 20.54a.562.562 0 0 1-.84-.61l1.285-5.386a.562.562 0 0 0-.182-.557l-4.204-3.602a.562.562 0 0 1 .321-.988l5.518-.442a.563.563 0 0 0 .475-.345L11.48 3.5Z" />
</svg>
''';

  static const String heart = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z" />
</svg>
''';

  static const String clock = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
</svg>
''';

  static const String beaker = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.75 3.104v5.714a2.25 2.25 0 0 1-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082M5 14.5c-1.25 0-2.25-1.25-2.25-2.5 0-1.036.784-2.027 1.838-2.16M5 14.5c.667.333 1.333.5 2 .5s1.333-.167 2-.5M9.75 3.104a48.841 48.841 0 0 1 4.5 0M14.25 3.104v5.714a2.25 2.25 0 0 0 .659 1.591L19 14.5m-2 .5c.667-.333 1.333-.5 2-.5s1.333.167 2 .5m-2- .5c1.25 0 2.25-1.25 2.25-2.5 0-1.036-.784-2.027-1.838-2.16m-7 0c1.657 0 3 2.403 3 5.5s-1.343 5.5-3 5.5m0-11c1.657 0 3 2.403 3 5.5s-1.343 5.5-3 5.5m0-11c-1.657 0-3 2.403-3 5.5s1.343 5.5 3 5.5m-1.5 3v5.25m3 0v5.25" />
</svg>
''';

  static const String lightBulb = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 18v4m-3.429-2.143a4.058 4.058 0 0 0 6.858 0M18 8.492a5.625 5.625 0 1 0-8.25 4.968V14.25a.75.75 0 0 0 .75.75h4.5a.75.75 0 0 0 .75-.75v-.758A5.625 5.625 0 0 0 18 8.492ZM8.848 3.424a8.25 8.25 0 1 1 6.304 0M6.75 19.5h10.5" />
</svg>
''';

  static const String sparkles = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.937 5.5 8.662 2.63a.75.75 0 0 0-1.424 0L5.963 5.5m3.974 0 2.587 0m-6.561 0a.25.25 0 0 0 .25.25l2.87 1.275a.75.75 0 0 0 0 1.424l-2.87 1.275a.25.25 0 0 0-.25.25m6.561-3.25-.25.25M9.937 5.5l0 2.587m0-2.587-.25-.25m.25 2.837a.75.75 0 0 0 .25.25l2.87 1.275a.25.25 0 0 0 .25-.25l1.275-2.87a.75.75 0 0 0 1.424 0l1.275 2.87a.25.25 0 0 0 .25.25l2.87 1.275a.75.75 0 0 0 0 1.424l-2.87 1.275a.25.25 0 0 0-.25.25l-1.275 2.87a.75.75 0 0 0-1.424 0l-1.275-2.87a.25.25 0 0 0-.25-.25l-2.87-1.275a.75.75 0 0 0 0-1.424l2.87-1.275a.25.25 0 0 0 .25-.25l1.275-2.87a.75.75 0 0 0 1.424 0l1.275 2.87M5.25 12l-1.523-.677a.25.25 0 0 0-.25.25l-.677 1.523a.75.75 0 0 0 0 1.424l1.523.677a.25.25 0 0 0 .25-.25l.677-1.523a.75.75 0 0 0 1.424 0l.677 1.523a.25.25 0 0 0 .25.25l1.523.677a.75.75 0 0 0 0 1.424l-1.523.677a.25.25 0 0 0-.25.25l-.677 1.523a.75.75 0 0 0-1.424 0l-.677-1.523a.25.25 0 0 0-.25-.25l-1.523-.677a.75.75 0 0 0 0-1.424l1.523-.677a.25.25 0 0 0 .25-.25l.677-1.523a.75.75 0 0 0 1.424 0l.677 1.523a.25.25 0 0 0 .25.25L5.25 12Zm13.5 0 1.523-.677a.25.25 0 0 1 .25.25l.677 1.523a.75.75 0 0 1 0 1.424l-1.523.677a.25.25 0 0 1-.25-.25l-.677-1.523a.75.75 0 0 1-1.424 0l-.677 1.523a.25.25 0 0 1-.25.25l-1.523.677a.75.75 0 0 1 0 1.424l1.523.677a.25.25 0 0 1 .25.25l.677 1.523a.75.75 0 0 1 1.424 0l.677-1.523a.25.25 0 0 1 .25-.25l1.523-.677a.75.75 0 0 1 0-1.424l-1.523-.677a.25.25 0 0 1-.25-.25l-.677-1.523a.75.75 0 0 1-1.424 0l-.677 1.523a.25.25 0 0 1-.25.25L18.75 12Z" />
</svg>
''';

// Ícone de roleta para Bets
static const String roulette = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2Zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8Zm0-12.75a4.5 4.5 0 1 0 0 9 4.5 4.5 0 0 0 0-9Z" />
</svg>
''';

// Ícone de gráfico crescente para Investir
static const String trendingUp = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M2.25 6 9 12.75l4.286-4.286a11.948 11.948 0 0 1 4.306 6.43l.776 2.898m0 0 3.182-5.511m-3.182 5.51-5.511-3.181" />
</svg>
''';

// Adicione estes ícones no arquivo custom_icons.dart

// Ícones financeiros para as categorias do marketplace
static const String chartBar = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
</svg>
''';

static const String wallet = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Zm-9.75 3.75h.008v.008h-.008v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm3.75 3.75h.008v.008h-.008v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm3.75 0h.008v.008h-.008v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-7.5 3h.008v.008h-.008v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm3.75 0h.008v.008h-.008v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
</svg>
''';

static const String currencyDollar = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 3v18m6-15h-3v3H9V6H6m12 9h-3v3H9v-3H6" />
</svg>
''';

static const String bitcoin = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2Zm3.75 4.5h-3v1.5h4.5m-4.5 3v1.5h3m1.5-4.5h-6v9h6m-1.5-4.5h-3v1.5h4.5" />
</svg>
''';

static const String chartLine = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3.75 3v11.25A2.25 2.25 0 0 0 6 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0 1 18 16.5h-2.25m-7.5 0h7.5m-7.5 0-1 3m8.5-3 1 3m0 0 .5 1.5m-.5-1.5h-9.5m0 0-.5 1.5M9 11.25v1.5M12 9v3.75m3-6v6" />
</svg>
''';

static const String buildingLibrary = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6M21 10h.75m-1.5 4.5h-18m1.5 0h15m-15 0 3 3m12-3-3 3m-12 0 3 3m6-3-3 3" />
</svg>
''';

static const String puzzle = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M14.25 3h.75a3 3 0 0 1 3 3v.75m-3 0h3m-3 0v3m3.75 12.75h-.75a3 3 0 0 1-3-3v-.75m3 0h-3m3 0v-3M3 9.75v.75a3 3 0 0 0 3 3h.75m0-3v3m0-3h-3m9.75 0h.75a3 3 0 0 1 3 3v.75m-3-3h3m-3 0v3M3 14.25v-.75a3 3 0 0 1 3-3h.75m0 3v-3m0 3h-3m12.75-12.75h.75a3 3 0 0 1 3 3v.75m-3 0h3m-3 0v3" />
</svg>
''';

static const String photo = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
</svg>
''';

static const String link = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 3.122" />
</svg>
''';

static const String gift = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 11.25v8.25a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 1 0 9.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1 1 14.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-3.75c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v3.75c0 .621.504 1.125 1.125 1.125Z" />
</svg>
''';

  static const String commentOutlined = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
</svg>
''';

  // Ícone de enviar/arrow up
  static const String arrowUp = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m4.5 12.75 7.5-7.5 7.5 7.5" />
</svg>
''';

  // Ícone de like preenchido
  static const String thumbUp = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 11v8a1 1 0 0 0 1 1h8.5a.5.5 0 0 0 .5-.5.5.5 0 0 0-.5-.5H14a2 2 0 0 1-2-2a2 2 0 0 1 2-2h1.5a.5.5 0 0 0 .5-.5.5.5 0 0 0-.5-.5H14a2 2 0 0 1-2-2a2 2 0 0 1 2-2h1.5a.5.5 0 0 0 .5-.5.5.5 0 0 0-.5-.5H12M5 11h2v8H5z" />
</svg>
''';

  // Ícone de like outline
  static const String thumbUpOutlined = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 22V11M2 13v6a2 2 0 0 0 2 2h2.5M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
  <path d="m9 11 3-3 3 3"/>
</svg>
''';

  // Ícone de compartilhar
  static const String shareOutlined = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="18" cy="5" r="3"/>
  <circle cx="6" cy="12" r="3"/>
  <circle cx="18" cy="19" r="3"/>
  <line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/>
  <line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/>
</svg>
''';

  // Ícone de mais opções
  static const String moreHoriz = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z" />
</svg>
''';

  // Ícone de tempo/relógio
  static const String accessTime = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"/>
  <polyline points="12 6 12 12 16 14"/>
</svg>
''';

 static const String warning = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
  <line x1="12" y1="9" x2="12" y2="13"/>
  <line x1="12" y1="17" x2="12.01" y2="17"/>
</svg>
''';

  // Ícone de seta para frente
  static const String arrowForward = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m5 12 14 0m-7-7 7 7-7 7" />
</svg>
''';

  // Ícone de fechar
  static const String close = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m18 6-12 12m0-12 12 12" />
</svg>
''';

  // Ícone de expandir tela cheia
  static const String openInFull = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21 15.61-3-3M18 15.61V18.75M18 18.75h-3.14M15 21l-3-3m3 3v-3.14M15 18.75H11.86M3 8.39l3 3m-3-3h3.14M3 8.39V5.25m3 3V5.25M9 3l3 3M9 3v3.14M9 6.25h3.14" />
</svg>
''';

  // Ícone de imagem
  static const String image = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect width="18" height="18" x="3" y="3" rx="2" ry="2" />
  <circle cx="9" cy="9" r="2" />
  <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" />
</svg>
''';

  // Ícone de câmera
  static const String camera = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M6.827 6.175A2.31 2.31 0 0 1 5.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574v4.852c0 1.067.75 1.994 1.802 2.169a11.05 11.05 0 0 0 1.134.175 2.31 2.31 0 0 1 1.64 1.055l.822 1.316c.955 1.528 2.465 2.251 4.113 2.251 1.647 0 3.158-.723 4.113-2.251l.822-1.315a2.31 2.31 0 0 1 1.64-1.056 11.04 11.04 0 0 0 1.134-.175c1.052-.175 1.802-1.102 1.802-2.169v-4.852c0-1.067-.75-1.994-1.802-2.169a11.05 11.05 0 0 0-1.134-.175 2.31 2.31 0 0 1-1.64-1.055l-.822-1.316C14.408 4.723 12.897 4 11.25 4c-1.647 0-3.158.723-4.113 2.251l-.822 1.316a2.31 2.31 0 0 1-1.64 1.055 11.04 11.04 0 0 0-1.134.175 2.31 2.31 0 0 1-1.64 1.055Zm.75 0a.75.75 0 1 0-1.5 0 .75.75 0 0 0 1.5 0ZM12 14.25a2.25 2.25 0 1 0 0-4.5 2.25 2.25 0 0 0 0 4.5Z" />
</svg>
''';

  // Ícone de vídeo
  static const String videoLibrary = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m20.25 6.375-6 4.5 6 4.5v-9ZM3.782 18.367C5.624 19.242 7.98 19.5 10.5 19.5h3c2.52 0 4.875-.258 6.718-1.133 1.843-.875 3.282-2.165 3.282-4.617 0-4.168-4.868-5.625-9.75-5.625-4.881 0-9.75 1.457-9.75 5.625 0 2.452 1.439 3.742 3.282 4.617Z" />
</svg>
''';

  // Ícone de deletar
  static const String delete = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5m6 4.125 2.25 2.25m0 0 2.25 2.25m-4.5 0 2.25-2.25m2.25-4.125-2.25 2.25m-6 0L9 9.75l-2.25 2.25M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
</svg>
''';

  // Ícone de editar
  static const String edit = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" />
</svg>
''';

  // Ícone de salvar
  static const String save = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H9.75m0 12.75h4.5m-4.5 3 3-3 3 3m-3-3v-18m-6 4.5v12" />
</svg>
''';

  // Ícones para o filtro
  static const String filterList = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M10.5 6h9.75M10.5 6H2.25m8.25 0v-1.5m0 3v1.5m-7.5 3h18.75m-18.75 0H3.75m6.75 0v1.5m0-1.5v1.5m-3 3h10.5m-10.5 0H3.75m6.75 0v1.5m0-1.5v1.5" />
</svg>
''';

  static const String dashboard = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 3.6v16.8A.6.6 0 0 0 3.6 21h9.6a.6.6 0 0 0 .6-.6v-6.6a.6.6 0 0 0-.6-.6H3.6a.6.6 0 0 0-.6.6Zm0-2.4v3.6A.6.6 0 0 0 3.6 3h3.6a.6.6 0 0 0 .6-.6V1.2a.6.6 0 0 0-.6-.6H3.6a.6.6 0 0 0-.6.6Zm7.2 0v3.6a.6.6 0 0 0 .6.6h3.6a.6.6 0 0 0 .6-.6V1.2a.6.6 0 0 0-.6-.6h-3.6a.6.6 0 0 0-.6.6Zm7.2 0v3.6a.6.6 0 0 0 .6.6h3.6a.6.6 0 0 0 .6-.6V1.2a.6.6 0 0 0-.6-.6h-3.6a.6.6 0 0 0-.6.6Zm0 7.2v3.6a.6.6 0 0 0 .6.6h3.6a.6.6 0 0 0 .6-.6V8.4a.6.6 0 0 0-.6-.6h-3.6a.6.6 0 0 0-.6.6Zm0 7.2v3.6a.6.6 0 0 0 .6.6h3.6a.6.6 0 0 0 .6-.6v-3.6a.6.6 0 0 0-.6-.6h-3.6a.6.6 0 0 0-.6.6Z" />
</svg>
''';

  static const String newspaper = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 7.5h.75m- .75 3h.75m-7.5 6h15m.75-3h-18m.75-3h.01M6.75 7.5h.01m3-3h4.5c.414 0 .75.336.75.75v15a.75.75 0 0 1-.75.75h-9a.75.75 0 0 1-.75-.75v-12c0-.414.336-.75.75-.75h4.5Zm6.75 16.5v-3.337c0-.533-.192-1.05-.534-1.418-1.403-1.512-4.966-1.512-6.369 0-.342.368-.534.885-.534 1.418V21" />
</svg>
''';

  static const String expandMore = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m6 9 6 6 6-6" />
</svg>
''';

  static const String checkCircle = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
</svg>
''';

  static const String person = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M15.75 6a3.75 3.75 0 1 1-7.5 0m15 0a8.25 8.25 0 1 1-16.5 0 8.25 8.25 0 0 1 16.5 0Z" />
  <path d="M5.25 18.75h13.5m-13.5 0a3 3 0 0 1 3-3h7.5a3 3 0 0 1 3 3m-13.5 0a3 3 0 0 1 3-3h7.5a3 3 0 0 1 3 3" />
</svg>
''';

  static const String addCircle = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
</svg>
''';

  static const String moreVert = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 6.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 12.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 18.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5Z" />
</svg>
''';

  static const String info = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 11.25v4.5m0 0 3-3m-3 3-3-3m9 3a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
</svg>
''';

  static const String send = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m4.5 12.75 6 6 9-13.5" />
</svg>
''';

  static const String book = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" />
</svg>
''';

  // Adicione estes ícones ao arquivo lib/widgets/custom_icons.dart

static const String certificate = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4.5 15.75l7.5-7.5 7.5 7.5" />
</svg>
''';

static const String description = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H9.75m0 13.5h4.5m-4.5 3l3-3 3 3m-3-3v-18m-3 4.5h6" />
</svg>
''';

static const String contract = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M6 3v12a6 6 0 0 0 12 0V3m-3 18H9M8.25 8.25h.01M8.25 12h.01M8.25 15.75h.01M15.75 8.25h.01M15.75 12h.01M15.75 15.75h.01" />
</svg>
''';

static const String invoice = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19.5 3.75h-15A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V6a2.25 2.25 0 0 0-2.25-2.25Zm-9 13.5a3.75 3.75 0 1 1 0-7.5 3.75 3.75 0 0 1 0 7.5Z" />
</svg>
''';

static const String presentation = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 3v18h18V3H3Zm9 15.75v-6m-3 3v-4.5m6 4.5v-4.5m-3 1.5h6m-12 0h6" />
</svg>
''';

static const String school = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m4.26 10.147a60.438 60.438 0 0 0-.491 6.347A48.62 48.62 0 0 1 12 20.904a48.62 48.62 0 0 1 8.232-4.41 60.46 60.46 0 0 0-.491-6.347m-16.1 0a2.25 2.25 0 0 1 .44-.901l9.07-9.28a2.25 2.25 0 0 1 3.18 0l9.07 9.28a2.25 2.25 0 0 1 .44.902m-16.1 0a49.94 49.94 0 0 1-2.448-5.4m21 0a49.94 49.94 0 0 0-2.448 5.4m-9.552-5.4 3.18 3.28m-6.36 0 3.18-3.28" />
</svg>
''';

static const String folder = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M2.25 7.125C2.25 6.504 2.754 6 3.375 6h6c.621 0 1.125.504 1.125 1.125v3.75c0 .621-.504 1.125-1.125 1.125h-6a1.125 1.125 0 0 1-1.125-1.125v-3.75ZM14.25 8.625c0-.621.504-1.125 1.125-1.125h5.25c.621 0 1.125.504 1.125 1.125v8.25c0 .621-.504 1.125-1.125 1.125h-5.25a1.125 1.125 0 0 1-1.125-1.125v-8.25ZM3.75 16.125c0-.621.504-1.125 1.125-1.125h5.25c.621 0 1.125.504 1.125 1.125v2.25c0 .621-.504 1.125-1.125 1.125h-5.25a1.125 1.125 0 0 1-1.125-1.125v-2.25Z" />
</svg>
''';

  static const String arrowBack = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
  <path fill-rule="evenodd" d="M11.03 3.97a.75.75 0 010 1.06l-6.22 6.22H21a.75.75 0 010 1.5H4.81l6.22 6.22a.75.75 0 11-1.06 1.06l-7.5-7.5a.75.75 0 010-1.06l7.5-7.5a.75.75 0 011.06 0z" clip-rule="evenodd" />
</svg>
''';
}

class SvgIcon extends StatelessWidget {
  final String svgString;
  final Color? color;
  final double? size;

  const SvgIcon({
    super.key,
    required this.svgString,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svgString,
      width: size ?? 24,
      height: size ?? 24,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}