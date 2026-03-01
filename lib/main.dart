// ============================================================
// NexusVPN — main.dart (arquivo único)
// VPN real com SNI tunneling, TUN interface nativa Android
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF111827),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const NexusVpnApp());
}

// ─────────────────────────────────────────────────────────────
// TEMA
// ─────────────────────────────────────────────────────────────
class T {
  static const bgDeep     = Color(0xFF0A0D14);
  static const bgCard     = Color(0xFF111827);
  static const bgElevated = Color(0xFF1C2333);
  static const bgSurface  = Color(0xFF242D3F);
  static const accent     = Color(0xFF2563EB);
  static const accentSoft = Color(0xFF3B82F6);
  static const success    = Color(0xFF10B981);
  static const danger     = Color(0xFFEF4444);
  static const warning    = Color(0xFFF59E0B);
  static const txtPrimary = Color(0xFFE4E9F2);
  static const txtSec     = Color(0xFF8896B3);
  static const txtMuted   = Color(0xFF4B5A72);
  static const divider    = Color(0xFF1E2A3E);
  static const border     = Color(0xFF2A3A54);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accentSoft,
      surface: bgCard,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDeep,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        color: txtPrimary, fontSize: 18, fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: txtPrimary),
    ),
    dividerColor: divider,
  );
}

// ─────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────
enum VpnStatus { disconnected, connecting, connected, disconnecting }

class VpnServer {
  final String id, country, city, flag, host, protocol;
  final int port, ping;
  final double load;
  final bool isPremium;
  const VpnServer({
    required this.id, required this.country, required this.city,
    required this.flag, required this.host, required this.protocol,
    required this.port, required this.ping, required this.load,
    this.isPremium = false,
  });
}

class VpnStats {
  final int dlBytes, ulBytes, ping;
  final Duration duration;
  final String ip;
  const VpnStats({
    required this.dlBytes, required this.ulBytes,
    required this.ping, required this.duration, required this.ip,
  });
  String get dl => _fmt(dlBytes);
  String get ul => _fmt(ulBytes);
  String get time {
    final h = duration.inHours.toString().padLeft(2,'0');
    final m = (duration.inMinutes%60).toString().padLeft(2,'0');
    final s = (duration.inSeconds%60).toString().padLeft(2,'0');
    return '$h:$m:$s';
  }
  static String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1048576) return '${(b/1024).toStringAsFixed(1)}KB';
    return '${(b/1048576).toStringAsFixed(2)}MB';
  }
}

// Servidores de demo (conectar a servidor real via campo host)
const kServers = [
  VpnServer(id:'br-sp', country:'Brasil',        city:'São Paulo',  flag:'🇧🇷', host:'br-sp.nexusvpn.net',  protocol:'SNI',       port:443, ping:12,  load:.35),
  VpnServer(id:'us-ny', country:'Estados Unidos', city:'New York',   flag:'🇺🇸', host:'us-ny.nexusvpn.net',  protocol:'SNI',       port:443, ping:140, load:.61, isPremium:true),
  VpnServer(id:'de-ff', country:'Alemanha',       city:'Frankfurt',  flag:'🇩🇪', host:'de-ff.nexusvpn.net',  protocol:'WireGuard', port:443, ping:210, load:.28, isPremium:true),
  VpnServer(id:'nl-am', country:'Holanda',        city:'Amsterdam',  flag:'🇳🇱', host:'nl-am.nexusvpn.net',  protocol:'OpenVPN',   port:443, ping:195, load:.52),
  VpnServer(id:'jp-tk', country:'Japão',          city:'Tokyo',      flag:'🇯🇵', host:'jp-tk.nexusvpn.net',  protocol:'SNI',       port:443, ping:290, load:.44, isPremium:true),
  VpnServer(id:'ca-mt', country:'Canadá',         city:'Montreal',   flag:'🇨🇦', host:'ca-mt.nexusvpn.net',  protocol:'WireGuard', port:443, ping:155, load:.19),
  VpnServer(id:'sg-sg', country:'Singapura',      city:'Singapore',  flag:'🇸🇬', host:'sg-sg.nexusvpn.net',  protocol:'SNI',       port:443, ping:260, load:.67, isPremium:true),
  VpnServer(id:'uk-ld', country:'Reino Unido',    city:'London',     flag:'🇬🇧', host:'uk-ld.nexusvpn.net',  protocol:'OpenVPN',   port:443, ping:200, load:.40),
  VpnServer(id:'fr-pa', country:'França',         city:'Paris',      flag:'🇫🇷', host:'fr-pa.nexusvpn.net',  protocol:'SNI',       port:443, ping:185, load:.33),
  VpnServer(id:'au-sy', country:'Austrália',      city:'Sydney',     flag:'🇦🇺', host:'au-sy.nexusvpn.net',  protocol:'WireGuard', port:443, ping:320, load:.21),
];

// ─────────────────────────────────────────────────────────────
// CHANNEL BRIDGE → Kotlin nativo
// ─────────────────────────────────────────────────────────────
class VpnBridge {
  static const _ch = MethodChannel('com.nexusvpn.app/vpn');
  static const _ev = EventChannel('com.nexusvpn.app/vpn_events');

  static Stream<Map>? _eventStream;

  static Stream<Map> get events {
    _eventStream ??= _ev.receiveBroadcastStream().map((e) => Map<String,dynamic>.from(e));
    return _eventStream!;
  }

  /// Solicita permissão VPN ao Android (abre dialog nativo)
  static Future<bool> requestPermission() async {
    try {
      final granted = await _ch.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } catch (_) { return false; }
  }

  /// Inicia o VpnService nativo com os parâmetros do servidor
  static Future<bool> connect({
    required String host,
    required int port,
    required String sniHost,
    required String protocol,
    required String authToken,
    required String dns1,
    required String dns2,
  }) async {
    try {
      final ok = await _ch.invokeMethod<bool>('connect', {
        'host': host,
        'port': port,
        'sniHost': sniHost,
        'protocol': protocol,
        'authToken': authToken,
        'dns1': dns1,
        'dns2': dns2,
      });
      return ok ?? false;
    } catch (e) {
      debugPrint('[Bridge] connect error: $e');
      return false;
    }
  }

  /// Para o VpnService nativo e remove rotas
  static Future<void> disconnect() async {
    try { await _ch.invokeMethod('disconnect'); } catch (_) {}
  }

  /// Lê estatísticas do tunnel (bytes reais do tun0)
  static Future<Map<String,dynamic>> getStats() async {
    try {
      final r = await _ch.invokeMethod<Map>('getStats');
      return Map<String,dynamic>.from(r ?? {});
    } catch (_) { return {}; }
  }
}

// ─────────────────────────────────────────────────────────────
// VPN SERVICE (Flutter side — estado + chamadas ao nativo)
// ─────────────────────────────────────────────────────────────
class VpnService extends ChangeNotifier {
  VpnStatus _status = VpnStatus.disconnected;
  VpnServer? _server;
  VpnStats? _stats;
  String _sniHost = 'cdn.cloudflare.com';
  String _dns1 = '1.1.1.1';
  String _dns2 = '8.8.8.8';
  bool _killSwitch = true;
  bool _dnsLeak = true;
  bool _ipv6Block = true;
  String _error = '';
  Timer? _statsTimer;
  DateTime? _connectedAt;
  StreamSubscription? _eventSub;
  final _rng = Random();

  VpnStatus get status => _status;
  VpnServer? get server => _server;
  VpnStats? get stats => _stats;
  String get sniHost => _sniHost;
  String get dns1 => _dns1;
  String get dns2 => _dns2;
  bool get killSwitch => _killSwitch;
  bool get dnsLeak => _dnsLeak;
  bool get ipv6Block => _ipv6Block;
  bool get isConnected => _status == VpnStatus.connected;
  bool get isBusy => _status == VpnStatus.connecting || _status == VpnStatus.disconnecting;
  String get error => _error;

  VpnService() {
    _loadPrefs();
    _listenEvents();
  }

  void _listenEvents() {
    _eventSub = VpnBridge.events.listen((event) {
      final type = event['type'] as String? ?? '';
      switch (type) {
        case 'connected':
          _status = VpnStatus.connected;
          _connectedAt = DateTime.now();
          _startStatsTimer();
          break;
        case 'disconnected':
          _status = VpnStatus.disconnected;
          _stats = null;
          _stopStatsTimer();
          _connectedAt = null;
          break;
        case 'error':
          _status = VpnStatus.disconnected;
          _error = event['message'] ?? 'Erro desconhecido';
          _stopStatsTimer();
          break;
      }
      notifyListeners();
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _sniHost = p.getString('sni_host') ?? 'cdn.cloudflare.com';
    _dns1 = p.getString('dns1') ?? '1.1.1.1';
    _dns2 = p.getString('dns2') ?? '8.8.8.8';
    _killSwitch = p.getBool('kill_switch') ?? true;
    _dnsLeak = p.getBool('dns_leak') ?? true;
    _ipv6Block = p.getBool('ipv6_block') ?? true;
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sni_host', _sniHost);
    await p.setString('dns1', _dns1);
    await p.setString('dns2', _dns2);
    await p.setBool('kill_switch', _killSwitch);
    await p.setBool('dns_leak', _dnsLeak);
    await p.setBool('ipv6_block', _ipv6Block);
  }

  void selectServer(VpnServer s) {
    if (isBusy || isConnected) return;
    _server = s;
    notifyListeners();
  }

  Future<void> connect() async {
    if (_server == null || isBusy || isConnected) return;
    _error = '';
    _status = VpnStatus.connecting;
    notifyListeners();

    // 1. Pedir permissão Android VPN
    final granted = await VpnBridge.requestPermission();
    if (!granted) {
      _status = VpnStatus.disconnected;
      _error = 'Permissão VPN negada';
      notifyListeners();
      return;
    }

    // 2. Iniciar tunnel nativo
    final ok = await VpnBridge.connect(
      host: _server!.host,
      port: _server!.port,
      sniHost: _sniHost,
      protocol: _server!.protocol,
      authToken: 'demo-token-replace-with-real',
      dns1: _dnsLeak ? _dns1 : '1.1.1.1',
      dns2: _dnsLeak ? _dns2 : '8.8.8.8',
    );

    if (!ok) {
      _status = VpnStatus.disconnected;
      _error = 'Falha ao iniciar tunnel';
      notifyListeners();
    }
    // Status vai vir pelo EventChannel quando nativo conectar
  }

  Future<void> disconnect() async {
    if (_status == VpnStatus.disconnected) return;
    _status = VpnStatus.disconnecting;
    notifyListeners();
    await VpnBridge.disconnect();
  }

  Future<void> toggleConnection() async {
    isConnected ? await disconnect() : await connect();
  }

  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final raw = await VpnBridge.getStats();
      if (raw.isEmpty || _connectedAt == null) return;
      _stats = VpnStats(
        dlBytes: (raw['download'] as int? ?? 0),
        ulBytes: (raw['upload'] as int? ?? 0),
        ping: (raw['ping'] as int? ?? _server?.ping ?? 0),
        duration: DateTime.now().difference(_connectedAt!),
        ip: raw['ip'] as String? ?? '10.8.0.2',
      );
      notifyListeners();
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void setSniHost(String v) { _sniHost = v; _savePrefs(); notifyListeners(); }
  void setDns1(String v) { _dns1 = v; _savePrefs(); notifyListeners(); }
  void setDns2(String v) { _dns2 = v; _savePrefs(); notifyListeners(); }
  void setKillSwitch(bool v) { _killSwitch = v; _savePrefs(); notifyListeners(); }
  void setDnsLeak(bool v) { _dnsLeak = v; _savePrefs(); notifyListeners(); }
  void setIpv6Block(bool v) { _ipv6Block = v; _savePrefs(); notifyListeners(); }

  @override
  void dispose() {
    _eventSub?.cancel();
    _stopStatsTimer();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// APP ROOT + PROVIDER
// ─────────────────────────────────────────────────────────────
class NexusVpnApp extends StatefulWidget {
  const NexusVpnApp({super.key});
  @override State<NexusVpnApp> createState() => _NexusVpnAppState();
}

class _NexusVpnAppState extends State<NexusVpnApp> {
  final _vpn = VpnService();
  @override
  void dispose() { _vpn.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vpn,
    builder: (_, __) => MaterialApp(
      title: 'NexusVPN',
      debugShowCheckedModeBanner: false,
      theme: T.theme,
      home: MainShell(vpn: _vpn),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// SHELL COM BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  final VpnService vpn;
  const MainShell({super.key, required this.vpn});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(vpn: widget.vpn),
      ServersScreen(vpn: widget.vpn),
      SettingsScreen(vpn: widget.vpn),
    ];
    return Scaffold(
      backgroundColor: T.bgDeep,
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: _BottomNav(
        index: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Ionicons.shield_outline, Ionicons.shield, 'VPN'),
      (Ionicons.globe_outline, Ionicons.globe, 'Servidores'),
      (Ionicons.settings_outline, Ionicons.settings, 'Config'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: T.bgCard,
        border: Border(top: BorderSide(color: T.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final (ico, icoA, label) = items[i];
              final sel = index == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? T.accent.withOpacity(.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sel ? icoA : ico,
                        color: sel ? T.accentSoft : T.txtMuted, size: 22),
                      const SizedBox(height: 3),
                      Text(label, style: GoogleFonts.inter(
                        color: sel ? T.accentSoft : T.txtMuted,
                        fontSize: 10,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final VpnService vpn;
  const HomeScreen({super.key, required this.vpn});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: .92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Color _sColor(VpnStatus s) => switch(s) {
    VpnStatus.connected    => T.success,
    VpnStatus.connecting   => T.warning,
    VpnStatus.disconnecting=> T.warning,
    VpnStatus.disconnected => T.danger,
  };

  String _sLabel(VpnStatus s) => switch(s) {
    VpnStatus.connected     => 'Protegido',
    VpnStatus.connecting    => 'Conectando...',
    VpnStatus.disconnecting => 'Desconectando...',
    VpnStatus.disconnected  => 'Desprotegido',
  };

  @override
  Widget build(BuildContext context) {
    final vpn = widget.vpn;
    final sc = _sColor(vpn.status);
    return Scaffold(
      backgroundColor: T.bgDeep,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20,14,20,14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider))),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: T.accent, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Ionicons.shield_checkmark, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('NexusVPN', style: GoogleFonts.inter(
                color: T.txtPrimary, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -.3)),
              const Spacer(),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: sc, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: sc.withOpacity(.5), blurRadius: 6)]),
              ),
              const SizedBox(width: 8),
              Text(_sLabel(vpn.status),
                style: GoogleFonts.inter(color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 36),

                // Power button
                Stack(alignment: Alignment.center, children: [
                  if (vpn.isConnected)
                    AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
                      Transform.scale(scale: _pulseAnim.value,
                        child: Container(width: 200, height: 200,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            border: Border.all(color: sc.withOpacity(.12), width: 1))))),
                  if (vpn.isConnected)
                    Container(width: 162, height: 162,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: sc.withOpacity(.2), width: 1))),

                  GestureDetector(
                    onTap: vpn.isBusy ? null : () => vpn.toggleConnection(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 122, height: 122,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: T.bgCard,
                        border: Border.all(color: sc, width: 2.5),
                        boxShadow: [BoxShadow(color: sc.withOpacity(.25), blurRadius: 30, spreadRadius: 4)],
                      ),
                      child: Center(child: vpn.isBusy
                        ? SizedBox(width: 32, height: 32,
                            child: CircularProgressIndicator(color: sc, strokeWidth: 2.5))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Ionicons.power, color: sc, size: 38),
                            const SizedBox(height: 4),
                            Text(vpn.isConnected ? 'ON' : 'OFF',
                              style: GoogleFonts.inter(color: sc,
                                fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.5)),
                          ]),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 28),

                // Error message
                if (vpn.error.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: T.danger.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: T.danger.withOpacity(.3)),
                    ),
                    child: Row(children: [
                      const Icon(Ionicons.warning_outline, color: T.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(vpn.error,
                        style: GoogleFonts.inter(color: T.danger, fontSize: 12))),
                    ]),
                  ),

                // Status badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sc.withOpacity(.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(vpn.isConnected ? Ionicons.lock_closed : Ionicons.lock_open_outline,
                      color: sc, size: 14),
                    const SizedBox(width: 6),
                    Text(vpn.isConnected
                      ? 'Conexão criptografada'
                      : 'Conexão não protegida',
                      style: GoogleFonts.inter(color: sc, fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ),

                const SizedBox(height: 28),

                // Stats
                if (vpn.isConnected && vpn.stats != null) ...[
                  Row(children: [
                    _statCard(Ionicons.arrow_down_outline, T.success,   'Download', vpn.stats!.dl),
                    const SizedBox(width: 10),
                    _statCard(Ionicons.arrow_up_outline,   T.accentSoft,'Upload',   vpn.stats!.ul),
                    const SizedBox(width: 10),
                    _statCard(Ionicons.timer_outline,      T.warning,   'Tempo',    vpn.stats!.time),
                  ]),
                  const SizedBox(height: 12),
                  _infoRow('IP Atribuído', vpn.stats!.ip, Ionicons.location_outline, T.accentSoft),
                  const SizedBox(height: 8),
                  _infoRow('Ping', '${vpn.stats!.ping}ms', Ionicons.wifi_outline, T.success),
                  const SizedBox(height: 20),
                ],

                // Servidor
                _ServerCard(vpn: vpn),
                const SizedBox(height: 12),

                // Protocolo
                _ProtocolSelector(vpn: vpn),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(IconData icon, Color color, String label, String value) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: T.bgCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.border)),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.robotoMono(
          color: T.txtPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: T.txtMuted, fontSize: 10)),
      ]),
    ));

  Widget _infoRow(String label, String value, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: T.bgCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.border)),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: T.txtSec, fontSize: 13)),
        const Spacer(),
        Text(value, style: GoogleFonts.robotoMono(
          color: T.txtPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
}

// ─────────────────────────────────────────────────────────────
// SERVER CARD
// ─────────────────────────────────────────────────────────────
class _ServerCard extends StatelessWidget {
  final VpnService vpn;
  const _ServerCard({required this.vpn});

  @override
  Widget build(BuildContext context) {
    final s = vpn.server;
    return GestureDetector(
      onTap: vpn.isConnected ? null : () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => ServersScreen(vpn: vpn))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: T.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.border)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: T.bgSurface, borderRadius: BorderRadius.circular(12)),
            child: Center(child: s == null
              ? const Icon(Ionicons.globe_outline, color: T.txtMuted, size: 22)
              : Text(s.flag, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s == null ? 'Selecionar Servidor' : s.city,
              style: GoogleFonts.inter(color: T.txtPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text(s == null ? 'Nenhum servidor selecionado' : '${s.country} · ${s.ping}ms',
              style: GoogleFonts.inter(color: T.txtSec, fontSize: 12)),
          ])),
          if (s != null) _Pill(s.protocol),
          const SizedBox(width: 8),
          if (!vpn.isConnected)
            const Icon(Ionicons.chevron_forward, color: T.txtMuted, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROTOCOL SELECTOR
// ─────────────────────────────────────────────────────────────
class _ProtocolSelector extends StatelessWidget {
  final VpnService vpn;
  const _ProtocolSelector({required this.vpn});

  @override
  Widget build(BuildContext context) {
    final protocols = [
      ('SNI',       Ionicons.git_network_outline),
      ('WireGuard', Ionicons.flash_outline),
      ('OpenVPN',   Ionicons.shield_outline),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.bgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Protocolo', style: GoogleFonts.inter(
          color: T.txtSec, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .8)),
        const SizedBox(height: 12),
        Row(children: protocols.map(((String, IconData) p) {
          final sel = vpn.server?.protocol == p.$1;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? T.accent.withOpacity(.15) : T.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? T.accent : T.border)),
              child: Column(children: [
                Icon(p.$2, color: sel ? T.accentSoft : T.txtMuted, size: 18),
                const SizedBox(height: 4),
                Text(p.$1, style: GoogleFonts.inter(
                  color: sel ? T.txtPrimary : T.txtMuted,
                  fontSize: 10, fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                  textAlign: TextAlign.center),
              ]),
            ),
          ));
        }).toList()),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SERVERS SCREEN
// ─────────────────────────────────────────────────────────────
class ServersScreen extends StatefulWidget {
  final VpnService vpn;
  const ServersScreen({super.key, required this.vpn});
  @override State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  String _q = '';
  String _filter = 'Todos';
  final _filters = ['Todos', 'SNI', 'WireGuard', 'OpenVPN'];

  List<VpnServer> get _list {
    var l = kServers.toList();
    if (_q.isNotEmpty)
      l = l.where((s) =>
        s.country.toLowerCase().contains(_q.toLowerCase()) ||
        s.city.toLowerCase().contains(_q.toLowerCase())).toList();
    if (_filter != 'Todos') l = l.where((s) => s.protocol == _filter).toList();
    return l;
  }

  Color _lc(double load) => load < .4 ? T.success : load < .7 ? T.warning : T.danger;

  @override
  Widget build(BuildContext context) {
    final vpn = widget.vpn;
    return Scaffold(
      backgroundColor: T.bgDeep,
      appBar: AppBar(
        title: const Text('Servidores'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: T.divider)),
      ),
      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16,16,16,8),
          child: Container(
            decoration: BoxDecoration(
              color: T.bgCard, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: T.border)),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              style: GoogleFonts.inter(color: T.txtPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar país ou cidade...',
                hintStyle: GoogleFonts.inter(color: T.txtMuted, fontSize: 14),
                prefixIcon: const Icon(Ionicons.search_outline, color: T.txtMuted, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        // Filters
        SizedBox(height: 44, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          itemBuilder: (_, i) {
            final f = _filters[i]; final sel = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? T.accent : T.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? T.accent : T.border)),
                  child: Text(f, style: GoogleFonts.inter(
                    color: sel ? Colors.white : T.txtSec, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ),
            );
          },
        )),
        const SizedBox(height: 8),
        // List
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _list.length,
          itemBuilder: (_, i) {
            final s = _list[i];
            final isSel = vpn.server?.id == s.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () { vpn.selectServer(s); Navigator.pop(context); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSel ? T.accent.withOpacity(.12) : T.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? T.accent : T.border)),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: T.bgSurface, borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(s.flag, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(s.city, style: GoogleFonts.inter(
                          color: T.txtPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        if (s.isPremium) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: T.warning.withOpacity(.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: T.warning.withOpacity(.4))),
                            child: Text('PRO', style: GoogleFonts.inter(
                              color: T.warning, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .5)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(s.country, style: GoogleFonts.inter(color: T.txtSec, fontSize: 12)),
                        const SizedBox(width: 8),
                        _Pill(s.protocol),
                      ]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(children: [
                        const Icon(Ionicons.wifi_outline, color: T.txtMuted, size: 12),
                        const SizedBox(width: 3),
                        Text('${s.ping}ms', style: GoogleFonts.inter(
                          color: T.txtSec, fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 4),
                      Text('${(s.load*100).toInt()}% carga',
                        style: GoogleFonts.inter(color: T.txtMuted, fontSize: 10)),
                      const SizedBox(height: 2),
                      Container(
                        width: 60, height: 4,
                        decoration: BoxDecoration(color: T.bgSurface, borderRadius: BorderRadius.circular(2)),
                        child: FractionallySizedBox(
                          widthFactor: s.load, alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(color: _lc(s.load), borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    ]),
                    const SizedBox(width: 8),
                    isSel
                      ? const Icon(Ionicons.checkmark_circle, color: T.accent, size: 20)
                      : const Icon(Ionicons.chevron_forward, color: T.txtMuted, size: 16),
                  ]),
                ),
              ),
            );
          },
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final VpnService vpn;
  const SettingsScreen({super.key, required this.vpn});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VpnService get vpn => widget.vpn;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: T.bgDeep,
    appBar: AppBar(
      title: const Text('Configurações'),
      automaticallyImplyLeading: false,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: T.divider)),
    ),
    body: ListView(padding: const EdgeInsets.all(16), children: [

      // SNI Config
      _sec('Tunelamento SNI'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: T.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Ionicons.code_slash_outline, color: T.accentSoft, size: 16),
            const SizedBox(width: 8),
            Text('SNI Host Spoofing', style: GoogleFonts.inter(
              color: T.txtPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Host injetado no TLS ClientHello para mascarar o destino real da conexão.',
            style: GoogleFonts.inter(color: T.txtSec, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          _editableField(
            label: 'SNI Host',
            value: vpn.sniHost,
            icon: Ionicons.globe_outline,
            onEdit: () => _editText('SNI Host', vpn.sniHost,
              hint: 'ex: cdn.cloudflare.com',
              onSave: vpn.setSniHost),
          ),
          const SizedBox(height: 8),
          _editableField(
            label: 'DNS Primário',
            value: vpn.dns1,
            icon: Ionicons.server_outline,
            onEdit: () => _editText('DNS Primário', vpn.dns1,
              hint: '1.1.1.1',
              onSave: vpn.setDns1),
          ),
          const SizedBox(height: 8),
          _editableField(
            label: 'DNS Secundário',
            value: vpn.dns2,
            icon: Ionicons.server_outline,
            onEdit: () => _editText('DNS Secundário', vpn.dns2,
              hint: '8.8.8.8',
              onSave: vpn.setDns2),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // Segurança
      _sec('Segurança'),
      _card([
        _toggle(Ionicons.skull_outline,   T.danger,    'Kill Switch',
          'Bloqueia internet se VPN cair', vpn.killSwitch, vpn.setKillSwitch),
        _div(),
        _toggle(Ionicons.eye_off_outline, T.accentSoft,'Proteção DNS Leak',
          'Evita vazamento de requisições DNS', vpn.dnsLeak, vpn.setDnsLeak),
        _div(),
        _toggle(Ionicons.ban_outline,     T.warning,   'Bloquear IPv6',
          'Previne vazamentos via IPv6', vpn.ipv6Block, vpn.setIpv6Block),
      ]),
      const SizedBox(height: 20),

      // Info técnica
      _sec('Informações Técnicas'),
      _card([
        _info(Ionicons.git_network_outline, T.accentSoft, 'Protocolo SNI',
          'TLS 1.3 ClientHello patching'),
        _div(),
        _info(Ionicons.shield_checkmark_outline, T.success, 'Criptografia',
          'AES-256-GCM'),
        _div(),
        _info(Ionicons.key_outline, T.warning, 'Handshake',
          'ECDHE-RSA-2048'),
        _div(),
        _info(Ionicons.layers_outline, T.accentSoft, 'Interface',
          'TUN (Layer 3)'),
      ]),
      const SizedBox(height: 32),

      Center(child: Text('NexusVPN v1.0.0',
        style: GoogleFonts.inter(color: T.txtMuted, fontSize: 11))),
      const SizedBox(height: 16),
    ]),
  );

  Widget _sec(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(label.toUpperCase(), style: GoogleFonts.inter(
      color: T.txtMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: T.bgCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: T.border)),
    child: Column(children: children),
  );

  Widget _div() => const Divider(height: 1, color: T.divider, indent: 16);

  Widget _editableField({
    required String label, required String value,
    required IconData icon, required VoidCallback onEdit,
  }) => GestureDetector(
    onTap: onEdit,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: T.bgSurface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: T.border)),
      child: Row(children: [
        Icon(icon, color: T.txtMuted, size: 15),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(color: T.txtMuted, fontSize: 10)),
          Text(value, style: GoogleFonts.robotoMono(color: T.accentSoft, fontSize: 13)),
        ])),
        const Icon(Ionicons.pencil_outline, color: T.txtMuted, size: 15),
      ]),
    ),
  );

  Widget _toggle(IconData icon, Color color, String label, String sub,
      bool value, ValueChanged<bool> onChange) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(color: T.txtPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(sub, style: GoogleFonts.inter(color: T.txtMuted, fontSize: 11)),
        ])),
        Switch(
          value: value, onChanged: onChange,
          activeColor: T.accent,
          trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? T.accent.withOpacity(.3) : T.bgSurface),
        ),
      ]),
    );

  Widget _info(IconData icon, Color color, String label, String value) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          color: T.txtPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
        Text(value, style: GoogleFonts.inter(color: T.txtSec, fontSize: 12)),
      ]),
    );

  void _editText(String title, String current, {
    required String hint, required ValueChanged<String> onSave,
  }) {
    final ctrl = TextEditingController(text: current);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: T.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: GoogleFonts.inter(color: T.txtPrimary)),
      content: TextField(
        controller: ctrl,
        style: GoogleFonts.robotoMono(color: T.txtPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: T.txtMuted),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: T.border),
            borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: T.accent),
            borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter(color: T.txtSec))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: T.accent),
          onPressed: () { onSave(ctrl.text.trim()); Navigator.pop(context); },
          child: Text('Salvar', style: GoogleFonts.inter(color: Colors.white))),
      ],
    ));
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED WIDGET — Protocol Pill
// ─────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String protocol;
  const _Pill(this.protocol);

  Color get _c => switch(protocol) {
    'SNI'       => T.accentSoft,
    'WireGuard' => T.success,
    'OpenVPN'   => T.warning,
    _           => T.txtMuted,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: _c.withOpacity(.12),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: _c.withOpacity(.3))),
    child: Text(protocol, style: GoogleFonts.robotoMono(
      color: _c, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
