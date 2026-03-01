package com.cashnet.app.cashnet_app

// ============================================================
// NexusVPN — MainActivity.kt
// VPN real: TUN interface + SNI tunnel + MethodChannel + EventChannel
// ============================================================

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import javax.net.ssl.*
import java.security.cert.X509Certificate

// ─────────────────────────────────────────────────────────────
// MAIN ACTIVITY
// ─────────────────────────────────────────────────────────────
class MainActivity : FlutterActivity() {

    companion object {
        const val VPN_METHOD_CHANNEL  = "com.nexusvpn.app/vpn"
        const val VPN_EVENT_CHANNEL   = "com.nexusvpn.app/vpn_events"
        const val VPN_PERMISSION_CODE = 1001
    }

    private var methodResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var statusReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── METHOD CHANNEL ────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "requestPermission" -> {
                        val intent = VpnService.prepare(this)
                        if (intent == null) {
                            result.success(true)
                        } else {
                            methodResult = result
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, VPN_PERMISSION_CODE)
                        }
                    }

                    "connect" -> {
                        val host      = call.argument<String>("host")      ?: ""
                        val port      = call.argument<Int>("port")         ?: 443
                        val sniHost   = call.argument<String>("sniHost")   ?: "cdn.cloudflare.com"
                        val protocol  = call.argument<String>("protocol")  ?: "SNI"
                        val authToken = call.argument<String>("authToken") ?: ""
                        val dns1      = call.argument<String>("dns1")      ?: "1.1.1.1"
                        val dns2      = call.argument<String>("dns2")      ?: "8.8.8.8"

                        val intent = Intent(this, NexusVpnService::class.java).apply {
                            action = NexusVpnService.ACTION_START
                            putExtra(NexusVpnService.EXTRA_HOST,       host)
                            putExtra(NexusVpnService.EXTRA_PORT,       port)
                            putExtra(NexusVpnService.EXTRA_SNI_HOST,   sniHost)
                            putExtra(NexusVpnService.EXTRA_PROTOCOL,   protocol)
                            putExtra(NexusVpnService.EXTRA_AUTH_TOKEN, authToken)
                            putExtra(NexusVpnService.EXTRA_DNS1,       dns1)
                            putExtra(NexusVpnService.EXTRA_DNS2,       dns2)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                            startForegroundService(intent)
                        else
                            startService(intent)

                        result.success(true)
                    }

                    "disconnect" -> {
                        startService(Intent(this, NexusVpnService::class.java).apply {
                            action = NexusVpnService.ACTION_STOP
                        })
                        result.success(null)
                    }

                    "getStats" -> {
                        val svc = NexusVpnService.instance
                        if (svc != null) {
                            result.success(mapOf(
                                "download" to NexusVpnService.downloadBytes.get(),
                                "upload"   to NexusVpnService.uploadBytes.get(),
                                "ping"     to NexusVpnService.lastPing.get(),
                                "ip"       to (NexusVpnService.assignedIp ?: "10.8.0.2"),
                            ))
                        } else {
                            result.success(mapOf<String, Any>())
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ── EVENT CHANNEL ─────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    registerStatusReceiver()
                }
                override fun onCancel(args: Any?) {
                    eventSink = null
                    unregisterStatusReceiver()
                }
            })
    }

    private fun registerStatusReceiver() {
        statusReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val type = intent?.getStringExtra("type") ?: return
                val map  = mutableMapOf<String, Any>("type" to type)
                intent.getStringExtra("message")?.let { map["message"] = it }
                intent.getStringExtra("ip")?.let { map["ip"] = it }
                runOnUiThread { eventSink?.success(map) }
            }
        }
        val filter = IntentFilter(NexusVpnService.ACTION_STATUS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            registerReceiver(statusReceiver, filter, RECEIVER_NOT_EXPORTED)
        else
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(statusReceiver, filter)
    }

    private fun unregisterStatusReceiver() {
        statusReceiver?.let { try { unregisterReceiver(it) } catch (_: Exception) {} }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_PERMISSION_CODE) {
            methodResult?.success(resultCode == RESULT_OK)
            methodResult = null
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        unregisterStatusReceiver()
        super.onDestroy()
    }
}

// ─────────────────────────────────────────────────────────────
// VPN SERVICE — TUN interface real + SNI tunnel
// ─────────────────────────────────────────────────────────────
class NexusVpnService : VpnService() {

    companion object {
        const val TAG            = "NexusVpnService"
        const val ACTION_START   = "com.nexusvpn.START"
        const val ACTION_STOP    = "com.nexusvpn.STOP"
        const val ACTION_STATUS  = "com.nexusvpn.STATUS"
        const val CHANNEL_ID     = "nexusvpn_channel"
        const val NOTIF_ID       = 100

        const val EXTRA_HOST       = "host"
        const val EXTRA_PORT       = "port"
        const val EXTRA_SNI_HOST   = "sniHost"
        const val EXTRA_PROTOCOL   = "protocol"
        const val EXTRA_AUTH_TOKEN = "authToken"
        const val EXTRA_DNS1       = "dns1"
        const val EXTRA_DNS2       = "dns2"

        @Volatile var instance: NexusVpnService? = null
        val downloadBytes = AtomicLong(0)
        val uploadBytes   = AtomicLong(0)
        val lastPing      = AtomicLong(0)
        @Volatile var assignedIp: String? = null
    }

    private var vpnIface: ParcelFileDescriptor? = null
    private val running = AtomicBoolean(false)
    private var tunnelThread: Thread? = null
    private var pingThread: Thread? = null

    private var serverHost  = ""
    private var serverPort  = 443
    private var sniHost     = "cdn.cloudflare.com"
    private var protocol    = "SNI"
    private var authToken   = ""
    private var dns1        = "1.1.1.1"
    private var dns2        = "8.8.8.8"

    // ── LIFECYCLE ─────────────────────────────────────────────
    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                serverHost  = intent.getStringExtra(EXTRA_HOST)       ?: ""
                serverPort  = intent.getIntExtra(EXTRA_PORT, 443)
                sniHost     = intent.getStringExtra(EXTRA_SNI_HOST)   ?: "cdn.cloudflare.com"
                protocol    = intent.getStringExtra(EXTRA_PROTOCOL)   ?: "SNI"
                authToken   = intent.getStringExtra(EXTRA_AUTH_TOKEN) ?: ""
                dns1        = intent.getStringExtra(EXTRA_DNS1)       ?: "1.1.1.1"
                dns2        = intent.getStringExtra(EXTRA_DNS2)       ?: "8.8.8.8"
                startForegroundNotif()
                startVpn()
            }
            ACTION_STOP -> stopVpn()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopVpn()
        instance = null
        super.onDestroy()
    }

    // ── NOTIFICATION ──────────────────────────────────────────
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CHANNEL_ID, "NexusVPN", NotificationManager.IMPORTANCE_LOW)
            ch.description = "VPN ativa em segundo plano"
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }

    private fun startForegroundNotif() {
        val stopPi = PendingIntent.getService(
            this, 0,
            Intent(this, NexusVpnService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NexusVPN Ativo")
            .setContentText("Conectado a $serverHost")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Desconectar", stopPi)
            .build()
        startForeground(NOTIF_ID, notif)
    }

    // ── CORE START ────────────────────────────────────────────
    private fun startVpn() {
        if (running.getAndSet(true)) return
        downloadBytes.set(0)
        uploadBytes.set(0)

        tunnelThread = Thread({
            try {
                when (protocol) {
                    "WireGuard" -> runWireGuardTunnel()
                    "OpenVPN"   -> runOpenVpnTunnel()
                    else        -> runSniTunnel()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Tunnel error: ${e.message}", e)
                broadcastStatus("error", e.message ?: "Erro no tunnel")
                stopVpn()
            }
        }, "nexus-tunnel").also { it.isDaemon = true; it.start() }
    }

    private fun stopVpn() {
        running.set(false)
        tunnelThread?.interrupt()
        pingThread?.interrupt()
        try { vpnIface?.close() } catch (_: Exception) {}
        vpnIface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        broadcastStatus("disconnected")
    }

    // ── SNI TUNNEL ────────────────────────────────────────────
    private fun runSniTunnel() {
        Log.i(TAG, "SNI tunnel → $serverHost:$serverPort (SNI=$sniHost)")

        // 1. Resolver IP do servidor
        val serverAddr = java.net.InetAddress.getByName(serverHost)

        // 2. Socket TCP protegido (não passa pelo TUN — evita loop)
        val rawSocket = Socket()
        protect(rawSocket)
        rawSocket.connect(InetSocketAddress(serverAddr, serverPort), 10_000)
        rawSocket.soTimeout = 0

        // 3. TLS com SNI customizado
        val sslCtx = buildTrustAllSslContext()
        val sslSocket = sslCtx.socketFactory.createSocket(rawSocket, sniHost, serverPort, true) as SSLSocket
        val sslParams = sslSocket.sslParameters
        sslParams.serverNames = listOf(javax.net.ssl.SNIHostName(sniHost))
        sslSocket.sslParameters = sslParams
        sslSocket.enabledProtocols = sslSocket.supportedProtocols
            .filter { it == "TLSv1.2" || it == "TLSv1.3" }.toTypedArray()
        sslSocket.startHandshake()
        Log.i(TAG, "TLS OK — ${sslSocket.session.protocol} / ${sslSocket.session.cipherSuite}")

        val sslIn  = sslSocket.inputStream
        val sslOut = sslSocket.outputStream

        // 4. Autenticação: [magic:4][tokenLen:4][token:N]
        val tokenBytes = authToken.toByteArray(Charsets.UTF_8)
        val authPkt = ByteBuffer.allocate(8 + tokenBytes.size).apply {
            put(byteArrayOf(0x4E, 0x58, 0x56, 0x50)) // "NXVP"
            putInt(tokenBytes.size)
            put(tokenBytes)
        }.array()
        sslOut.write(authPkt); sslOut.flush()

        // 5. Resposta: [OK00:4][ipLen:4][ip:N]
        val hdr = ByteArray(8)
        var r = 0; while (r < 8) r += sslIn.read(hdr, r, 8 - r)
        val statusCode = ByteBuffer.wrap(hdr, 0, 4).int
        if (statusCode != 0x4F4B3030) throw Exception("Auth rejeitada (code=$statusCode)")
        val ipLen = ByteBuffer.wrap(hdr, 4, 4).int.coerceIn(7, 15)
        val ipBytes = ByteArray(ipLen); var ir = 0
        while (ir < ipLen) ir += sslIn.read(ipBytes, ir, ipLen - ir)
        assignedIp = String(ipBytes, Charsets.UTF_8)
        Log.i(TAG, "IP atribuído: $assignedIp")

        // 6. Criar TUN interface com IP atribuído pelo servidor
        val tunFd = buildTunInterface()
        vpnIface = tunFd

        broadcastStatus("connected", ip = assignedIp)
        startPingMonitor(sslOut)

        val tunIn  = FileInputStream(tunFd.fileDescriptor)
        val tunOut = FileOutputStream(tunFd.fileDescriptor)

        // Upload: TUN → SSL
        val upThread = Thread({
            val buf    = ByteArray(32768)
            val lenBuf = ByteArray(2)
            try {
                while (running.get() && !Thread.interrupted()) {
                    val n = tunIn.read(buf)
                    if (n <= 0) continue
                    lenBuf[0] = ((n shr 8) and 0xFF).toByte()
                    lenBuf[1] = (n and 0xFF).toByte()
                    synchronized(sslOut) {
                        sslOut.write(lenBuf)
                        sslOut.write(buf, 0, n)
                        sslOut.flush()
                    }
                    uploadBytes.addAndGet(n.toLong())
                }
            } catch (e: Exception) {
                if (running.get()) Log.e(TAG, "Upload err: ${e.message}")
            }
        }, "nexus-up").also { it.isDaemon = true; it.start() }

        // Download: SSL → TUN
        val lenBuf = ByteArray(2)
        val buf    = ByteArray(32768)
        try {
            while (running.get() && !Thread.interrupted()) {
                var lr = 0; while (lr < 2) lr += sslIn.read(lenBuf, lr, 2 - lr)
                val pktLen = ((lenBuf[0].toInt() and 0xFF) shl 8) or (lenBuf[1].toInt() and 0xFF)
                if (pktLen <= 0 || pktLen > 32768) continue
                var pr = 0; while (pr < pktLen) pr += sslIn.read(buf, pr, pktLen - pr)
                tunOut.write(buf, 0, pktLen)
                downloadBytes.addAndGet(pktLen.toLong())
            }
        } catch (e: Exception) {
            if (running.get()) Log.e(TAG, "Download err: ${e.message}")
        }

        upThread.interrupt()
        try { sslSocket.close(); rawSocket.close() } catch (_: Exception) {}
    }

    // ── WIREGUARD / OPENVPN (fallback SNI) ───────────────────
    private fun runWireGuardTunnel() {
        Log.w(TAG, "WireGuard: requer wireguard-android lib. Fallback SNI.")
        runSniTunnel()
    }
    private fun runOpenVpnTunnel() {
        Log.w(TAG, "OpenVPN: requer ics-openvpn lib. Fallback SNI.")
        runSniTunnel()
    }

    // ── TUN INTERFACE ─────────────────────────────────────────
    private fun buildTunInterface(): ParcelFileDescriptor =
        Builder()
            .setSession("NexusVPN")
            .addAddress(assignedIp ?: "10.8.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer(dns1)
            .addDnsServer(dns2)
            .setMtu(1500)
            .apply {
                try { addDisallowedApplication(packageName) } catch (_: Exception) {}
            }
            .establish()
            ?: throw Exception("Falha ao criar interface TUN")

    // ── PING KEEPALIVE ────────────────────────────────────────
    private fun startPingMonitor(out: OutputStream) {
        val ping = byteArrayOf(0x50, 0x49, 0x4E, 0x47) // "PING"
        val len  = byteArrayOf(0x00, 0x04)
        pingThread = Thread({
            while (running.get() && !Thread.interrupted()) {
                try {
                    val t0 = System.currentTimeMillis()
                    synchronized(out) { out.write(len); out.write(ping); out.flush() }
                    lastPing.set(System.currentTimeMillis() - t0)
                    Thread.sleep(5000)
                } catch (e: InterruptedException) { break
                } catch (e: Exception) { if (running.get()) Log.w(TAG, "Ping err: ${e.message}"); break }
            }
        }, "nexus-ping").also { it.isDaemon = true; it.start() }
    }

    // ── SSL TRUST (substituir por cert pinning em produção) ───
    private fun buildTrustAllSslContext(): SSLContext {
        val tm = arrayOf<TrustManager>(object : X509TrustManager {
            override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
            override fun checkClientTrusted(c: Array<X509Certificate>, a: String) {}
            override fun checkServerTrusted(c: Array<X509Certificate>, a: String) {
                Log.d(TAG, "Server cert: ${c[0].subjectDN}")
            }
        })
        return SSLContext.getInstance("TLS").apply { init(null, tm, java.security.SecureRandom()) }
    }

    // ── BROADCAST ─────────────────────────────────────────────
    private fun broadcastStatus(type: String, message: String? = null, ip: String? = null) {
        sendBroadcast(Intent(ACTION_STATUS).apply {
            putExtra("type", type)
            message?.let { putExtra("message", it) }
            ip?.let { putExtra("ip", it) }
        })
    }
}