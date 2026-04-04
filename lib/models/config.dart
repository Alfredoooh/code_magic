// lib/models/config.dart
class AppConfig {
  final String operatorName;
  final String defaultCurrency;
  final String apiPrivateKey;
  final String endpoint;
  final String webplayerPath;
  final String sportsbookPath;
  final String authService;
  final String authId;
  final String authKey;
  final String authUsername;
  final String authPassword;
  final List<String> operatorInfo;

  AppConfig({
    required this.operatorName,
    required this.defaultCurrency,
    required this.apiPrivateKey,
    required this.endpoint,
    required this.webplayerPath,
    required this.sportsbookPath,
    required this.authService,
    required this.authId,
    required this.authKey,
    required this.authUsername,
    required this.authPassword,
    required this.operatorInfo,
  });

  String get basePath => endpoint + webplayerPath;
  String get sportsbookUrl => endpoint + sportsbookPath;
  String get phone => operatorInfo.length > 1
      ? operatorInfo[1].replaceAll('contactos : ', '').trim()
      : '';
  String get email => operatorInfo.length > 2 ? operatorInfo[2] : '';

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        operatorName: j['operatorName'] ?? 'ElephantBet AO',
        defaultCurrency: j['defaultCurrency'] ?? 'kz',
        apiPrivateKey: j['webServiceConfig']['apiPrivateKey'],
        endpoint: j['webServiceConfig']['endpoint'],
        webplayerPath: j['webServiceConfig']['webplayer_path'],
        sportsbookPath: j['webServiceConfig']['sportsbook_path'],
        authService: j['authServiceConfig']['authService'],
        authId: j['authServiceConfig']['authId'],
        authKey: j['authServiceConfig']['authKey'],
        authUsername: j['authServiceConfig']['authUsername'],
        authPassword: j['authServiceConfig']['authPassword'],
        operatorInfo: List<String>.from(j['operatorInfo'] ?? []),
      );
}