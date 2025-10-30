// =====================================================================
// lib/deriv_chart_widget.dart
// Widget de gráfico ULTRA AVANÇADO - agora com WebSocket Deriv em tempo real
// Suporta: Area Chart e Candlesticks | Mudança de mercado ao vivo
// =====================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

enum ChartType { area, candlestick }

class DerivAreaChart extends StatefulWidget {
  final List<double> points;
  final bool autoScale;
  final bool showGradient;
  final double? height;
  final String? market;
  final ChartType chartType;
  final String? derivAppId; // opcional: fornece um app_id Deriv personalizado
  final void Function(WebViewController controller, String? market)? onControllerCreated;

  const DerivAreaChart({
    Key? key,
    required this.points,
    this.autoScale = true,
    this.showGradient = true,
    this.height,
    this.market,
    this.chartType = ChartType.area,
    this.derivAppId,
    this.onControllerCreated,
  }) : super(key: key);

  @override
  State<DerivAreaChart> createState() => _DerivAreaChartState();
}

class _DerivAreaChartState extends State<DerivAreaChart> {
  late final WebViewController _controller;
  bool _isDark = true;
  ChartType _currentChartType = ChartType.area;

  String get _initialHtml => _buildUltraAdvancedHtml(
        widget.points,
        widget.autoScale,
        widget.showGradient,
        widget.market ?? 'R_10',
        _currentChartType,
        widget.derivAppId,
      );

  @override
  void initState() {
    super.initState();
    _currentChartType = widget.chartType;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('FlutterChannel', onMessageReceived: (message) {
        // Recebe mensagens da página (ex: status do WS, erros, ready, market-changed)
        debugPrint('DerivChart JS -> Flutter: ${message.message}');
      })
      ..loadHtmlString(_initialHtml);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isDark = context.isDark;
        });
        // Recarrega com o esquema de tema correcto
        _controller.loadHtmlString(_buildUltraAdvancedHtml(
          widget.points,
          widget.autoScale,
          widget.showGradient,
          widget.market ?? 'R_10',
          _currentChartType,
          widget.derivAppId,
        ));
      }

      if (widget.onControllerCreated != null) {
        widget.onControllerCreated!(_controller, widget.market);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DerivAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needsReload = false;

    if (mounted && _isDark != context.isDark) {
      setState(() {
        _isDark = context.isDark;
      });
      needsReload = true;
    }

    if (oldWidget.chartType != widget.chartType) {
      setState(() {
        _currentChartType = widget.chartType;
      });
      needsReload = true;
    }

    if (oldWidget.market != widget.market) {
      // Em vez de reload completo, preferimos mandar comando JS para trocar market
      final newMarket = widget.market ?? 'R_10';
      final script = "try{ setMarket('${_escapeJs(newMarket)}'); }catch(e){console.log('setMarket err', e);};";
      _controller.runJavaScript(script);
    }

    if (needsReload) {
      _controller.loadHtmlString(_buildUltraAdvancedHtml(
        widget.points,
        widget.autoScale,
        widget.showGradient,
        widget.market ?? 'R_10',
        _currentChartType,
        widget.derivAppId,
      ));
    } else if (widget.points != oldWidget.points) {
      final jsArray = widget.points.map((p) => p.toString()).join(',');
      final script = "try{ updateData([${jsArray}]); }catch(e){ console.log('Error:', e); };";
      _controller.runJavaScript(script);
    }
  }

  String _escapeJs(String s) => s.replaceAll("'", "\\'").replaceAll('"', '\\"');

  void toggleChartType() {
    setState(() {
      _currentChartType = _currentChartType == ChartType.area ? ChartType.candlestick : ChartType.area;
    });
    _controller.loadHtmlString(_buildUltraAdvancedHtml(
      widget.points,
      widget.autoScale,
      widget.showGradient,
      widget.market ?? 'R_10',
      _currentChartType,
      widget.derivAppId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 320,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: WebViewWidget(controller: _controller),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: toggleChartType,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.outlineVariant, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentChartType == ChartType.area ? Icons.show_chart_rounded : Icons.candlestick_chart_rounded,
                        size: 16,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentChartType == ChartType.area ? 'Area' : 'Candles',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMarketConfig(String market) {
    final lower = market.toLowerCase();
    if (lower.contains('r_') || lower.contains('vol')) {
      return {
        'name': market,
        'type': 'Volatility',
        'volatility': 0.02,
        'speed': 1,
      };
    } else if (lower.contains('btc') || lower.contains('crypto')) {
      return {
        'name': market,
        'type': 'Crypto',
        'volatility': 0.06,
        'speed': 2,
      };
    } else {
      return {
        'name': market,
        'type': 'Forex/Stocks',
        'volatility': 0.01,
        'speed': 1,
      };
    }
  }

  String _buildUltraAdvancedHtml(
    List<double> points,
    bool autoScale,
    bool showGradient,
    String market,
    ChartType chartType,
    String? derivAppId,
  ) {
    final initialData = points.map((p) => p.toString()).join(',');
    final isDark = _isDark;
    final isCandles = chartType == ChartType.candlestick;
    final marketConfig = _getMarketConfig(market);

    final bgColor = isDark ? '#0A0A0A' : '#FFFFFF';
    final textPrimary = isDark ? '#E6E1E5' : '#1C1B1F';
    final textSecondary = isDark ? 'rgba(230, 225, 229, 0.6)' : 'rgba(28, 27, 31, 0.6)';
    final gridColor = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)';
    final outline = isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)';
    final surfaceColor = isDark ? 'rgba(28,27,31,0.95)' : 'rgba(255,251,254,0.95)';

    final successColor = '#34C759';
    final errorColor = '#FF3B30';
    final infoColor = '#007AFF';
    final warningColor = '#FFCC00';

    final safeMarketName = market.replaceAll("'", "\\'").replaceAll('"', '\\"');
    final usedAppId = derivAppId ?? '1089'; // app_id público para testes (troca se tiveres outro)

    // Construções JS que antes tinham ternárias mal formadas — agora montadas em Dart para interpolação segura:
    final datasetsJs = isCandles
        ? '[]'
        : '[datasetLine,'
            '{"label":"EMA(9)","data":ema9,"borderColor":colors.info,"borderWidth":1.5,"borderDash":[4,4],"fill":false,"pointRadius":0,"tension":0.36},'
            '{"label":"BB Upper","data":bbands.map(b=>b.upper),"borderColor":colors.warning,"borderWidth":1,"borderDash":[2,2],"fill":false,"pointRadius":0},'
            '{"label":"BB Lower","data":bbands.map(b=>b.lower),"borderColor":colors.warning,"borderWidth":1,"borderDash":[2,2],"fill":"-1","backgroundColor":"rgba(255,204,0,0.04)","pointRadius":0}'
            ']';

    final chartTypeJs = isCandles ? 'candlestick' : 'line';

    return '''
<!doctype html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  *{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent;}
  html,body{width:100%;height:100%;background:${bgColor};font-family:SF-Pro-Display, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;overflow:hidden;}
  #chartContainer{width:100%;height:100%;position:relative;}
  .info-panel{position:absolute;background:${surfaceColor};backdrop-filter:blur(12px);border-radius:12px;font-size:11px;color:${textPrimary};z-index:100;box-shadow:0 8px 32px rgba(0,0,0,0.35);border:1px solid ${outline};padding:12px 14px;min-width:140px;}
  #stats{top:12px;left:12px;min-width:170px;}
  #indicators{top:12px;right:12px;min-width:160px;}
  #aiPrediction{bottom:12px;left:12px;min-width:220px;max-width:46%;}
  #marketInfo{bottom:12px;right:12px;min-width:140px;text-align:right;}
  .stat-row,.indicator-row{display:flex;justify-content:space-between;margin-bottom:6px;align-items:center;}
  .label{color:${textSecondary};font-weight:500;font-size:10px;text-transform:uppercase;letter-spacing:0.4px;}
  .value{font-weight:700;font-size:12px;margin-left:12px;}
  .positive{color:${successColor};}.negative{color:${errorColor};}.neutral{color:${warningColor};}
  .ai-signal{font-size:13px;font-weight:800;margin-bottom:8px;display:flex;align-items:center;gap:8px;}
  .confidence-bar{height:4px;background:rgba(255,255,255,0.06);border-radius:2px;overflow:hidden;margin-top:8px;}
  .confidence-fill{height:100%;background:linear-gradient(90deg, ${successColor}, ${infoColor});border-radius:2px;transition:width .3s ease;}
  .pulse{width:8px;height:8px;border-radius:50%;animation:pulse 2s ease-in-out infinite;display:inline-block;}
  @keyframes pulse{0%,100%{opacity:1;transform:scale(1);}50%{opacity:0.5;transform:scale(1.3);}}
  canvas{display:block;width:100%;height:100%;}
</style>
</head><body>
<div id="chartContainer">
  <div id="stats" class="info-panel">
    <div class="stat-row"><span class="label">Preço</span><span class="value" id="currentPrice">--</span></div>
    <div class="stat-row"><span class="label">Variação</span><span class="value" id="priceChange">--</span></div>
    <div class="stat-row"><span class="label">Vol 24h</span><span class="value" id="volatility">--</span></div>
    <div class="stat-row"><span class="label">Ticks</span><span class="value" id="tickCount">0</span></div>
  </div>

  <div id="indicators" class="info-panel">
    <div class="indicator-row"><span class="label">RSI(14)</span><span class="value" id="rsi">--</span></div>
    <div class="indicator-row"><span class="label">MACD</span><span class="value" id="macd">--</span></div>
    <div class="indicator-row"><span class="label">EMA(9)</span><span class="value" id="ema9">--</span></div>
    <div class="indicator-row"><span class="label">ADX</span><span class="value" id="adx">--</span></div>
  </div>

  <canvas id="chart"></canvas>

  <div id="aiPrediction" class="info-panel">
    <div class="ai-signal"><span class="pulse" id="signalPulse" style="background:${warningColor};"></span><span id="aiSignal">ANALISANDO...</span></div>
    <div class="stat-row"><span class="label">Confiança</span><span class="value" id="confidence">--</span></div>
    <div class="confidence-bar"><div class="confidence-fill" id="confidenceBar" style="width:0%"></div></div>
    <div class="stat-row" style="margin-top:8px;"><span class="label">Próx. Movimento</span><span class="value" id="nextMove">--</span></div>
  </div>

  <div id="marketInfo" class="info-panel">
    <div style="color:${textSecondary};font-size:12px;">${safeMarketName}</div>
    <div style="color:${infoColor};margin-top:6px;font-weight:700;">${marketConfig['type']}</div>
  </div>
</div>

<!-- libs -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-chart-financial@4.0.0/dist/chartjs-chart-financial.min.js"></script>

<script>
(function(){
  // CONFIGURÁVEL:
  const DERIV_WS_URL = 'wss://ws.binaryws.com/websockets/v3?app_id=${usedAppId}';
  let ws = null;
  let currentMarket = '${safeMarketName}';
  let reconnectDelay = 1000;
  let maxReconnect = 20000;
  let manualStop = false;

  // Dados
  let rawData = [${initialData}];
  if (!Array.isArray(rawData)) rawData = [];
  let timestamps = [];
  let candleData = [];
  let startPrice = rawData.length > 0 ? rawData[0] : 0;

  const colors = { success:'${successColor}', error:'${errorColor}', info:'${infoColor}', warning:'${warningColor}', grid:'${gridColor}', text:'${textPrimary}', textSecondary:'${textSecondary}' };
  Chart.defaults.font.family = 'SF Pro Display, -apple-system, BlinkMacSystemFont';

  // auxiliares indicadores (mantidos do ficheiro anterior)
  function calculateEMA(data, period){ if(!data||data.length===0) return []; const k=2/(period+1); const ema=[]; ema[0]=data[0]; for(let i=1;i<data.length;i++){ema[i]=data[i]*k + ema[i-1]*(1-k);} return ema;}
  function calculateMACD(data){ const ema12=calculateEMA(data,12); const ema26=calculateEMA(data,26); const macd = data.map((_,i)=> ((ema12[i]||0)-(ema26[i]||0))); const signal=calculateEMA(macd,9); const hist=macd.map((v,i)=> v-(signal[i]||0)); return {macd,signal,hist};}
  function calculateRSI(data, period=14){ if(!data||data.length<period+1) return 50; let gains=0,losses=0; for(let i=data.length-period;i<data.length;i++){const c=data[i]-data[i-1]; if(c>0) gains+=c; else losses+=Math.abs(c);} const avgG=gains/period; const avgL=losses/period||1; const rs=avgG/avgL; return 100 - (100/(1+rs));}
  function calculateADX(data, period=14){ if(!data||data.length<period*2) return 25; let sum=0; for(let i=data.length-period;i<data.length-1;i++){sum+=Math.abs(data[i+1]-data[i]);} return Math.min(100,(sum/period)*100);}
  function calculateBollingerBands(data, period=20, stdDev=2){ const out=[]; for(let i=0;i<data.length;i++){ if(i<period-1){ out.push({upper:null,middle:null,lower:null}); continue;} const slice=data.slice(i-period+1,i+1); const mean=slice.reduce((a,b)=>a+b,0)/period; const variance=slice.reduce((s,v)=>s+Math.pow(v-mean,2),0)/period; const std=Math.sqrt(variance); out.push({upper:mean+stdDev*std,middle:mean,lower:mean-stdDev*std}); } return out; }

  // Chart setup
  function initTimestamps(){ timestamps = rawData.map((_,i)=>{const now=new Date(); now.setSeconds(now.getSeconds() - (rawData.length - i)); return now; }); }
  function convertToCandlesticks(data, interval){ const candles=[]; const size = Math.max(1, Math.floor(interval)); for(let i=0;i<data.length;i+=size){ const slice=data.slice(i, Math.min(i+size,data.length)); if(slice.length===0) continue; const t = timestamps[i] || new Date(); candles.push({x:t,o:slice[0],h:Math.max(...slice),l:Math.min(...slice),c:slice[slice.length-1]}); } return candles; }

  initTimestamps();
  candleData = convertToCandlesticks(rawData,1);
  const ema9 = calculateEMA(rawData,9);
  const bbands = calculateBollingerBands(rawData);
  const macd = calculateMACD(rawData);

  const datasetLine = {
    label:'Preço', data: rawData, fill:true,
    backgroundColor: function(ctx){ const chart = ctx.chart; const {ctx:gc, chartArea} = chart; if(!chartArea) return null; const g = gc.createLinearGradient(0, chartArea.top, 0, chartArea.bottom); const isUp = rawData.length>1 && rawData[rawData.length-1]>=rawData[rawData.length-2]; if(isUp){ g.addColorStop(0,'rgba(52,199,89,0.28)'); g.addColorStop(1,'rgba(52,199,89,0)'); } else { g.addColorStop(0,'rgba(255,59,48,0.28)'); g.addColorStop(1,'rgba(255,59,48,0)'); } return g;},
    borderColor: function(){ return rawData.length>1 && rawData[rawData.length-1]>=rawData[rawData.length-2] ? colors.success : colors.error; },
    tension:0.36, pointRadius:0, borderWidth:2
  };

  const datasets = ${datasetsJs};

  const config = {
    type: '${chartTypeJs}',
    data: { labels: timestamps, datasets: datasets },
    options: {
      responsive:true, maintainAspectRatio:false, animation:{duration:150},
      interaction:{intersect:false,mode:'index'},
      scales:{
        x:{type:'time', time:{unit:'second'}, grid:{color:colors.grid, drawTicks:false}, ticks:{color:colors.textSecondary,font:{size:10}}},
        y:{position:'right', grid:{color:colors.grid}, ticks:{color:colors.textSecondary,font:{size:10,weight:'700'}, callback: v => Number(v).toFixed(4)}}
      },
      plugins:{legend:{display:false}, tooltip:{enabled:true, callbacks:{ title:ctx => { try{ return new Date(ctx[0].parsed.x).toLocaleTimeString(); }catch(e){return ''; }}, label: ctx => { if(ctx.dataset && ctx.dataset.type==='candlestick'){ const d=ctx.raw; return ['O: '+d.o.toFixed(4),'H: '+d.h.toFixed(4),'L: '+d.l.toFixed(4),'C: '+d.c.toFixed(4)]; } return ctx.dataset.label + ': ' + ctx.parsed.y.toFixed(4); } } } }
    }
  };

  // Create chart
  const canvas = document.getElementById('chart');
  const ctx = canvas.getContext('2d');
  let myChart;
  try {
    myChart = new Chart(ctx, config);
  } catch(e) { console.error('chart init', e); }

  // UTILS: recalcula indicadores, atualiza UI e chart
  function updateAllStats(){
    if(!rawData || rawData.length===0) return;
    const current = rawData[rawData.length-1];
    const change = current - (startPrice || current);
    const changePct = startPrice ? ((change/startPrice)*100) : 0;
    document.getElementById('currentPrice').textContent = current.toFixed(4);
    const changeEl = document.getElementById('priceChange');
    changeEl.textContent = (change>=0?'+':'')+change.toFixed(4) + ' (' + (changePct>=0?'+':'') + changePct.toFixed(2) + '%)';
    changeEl.className = 'value ' + (change>=0 ? 'positive' : 'negative');
    document.getElementById('volatility').textContent = Math.abs(changePct).toFixed(2) + '%';
    document.getElementById('tickCount').textContent = rawData.length;

    const rsi = calculateRSI(rawData);
    const macd = calculateMACD(rawData);
    const adx = calculateADX(rawData);
    const ema9c = calculateEMA(rawData,9);

    document.getElementById('rsi').textContent = (rsi||0).toFixed(1);
    document.getElementById('rsi').className = 'value ' + (rsi>70 ? 'negative' : rsi<30 ? 'positive' : 'neutral');
    const macdEl = document.getElementById('macd'); const macdVal = macd.macd[macd.macd.length-1]||0;
    macdEl.textContent = macdVal.toFixed(4); macdEl.className = 'value ' + (macdVal>0?'positive':'negative');
    document.getElementById('ema9').textContent = (ema9c[ema9c.length-1]||current).toFixed(4);
    document.getElementById('adx').textContent = (adx||0).toFixed(0); document.getElementById('adx').className = 'value ' + (adx>25?'positive':'neutral');

    // simple AI prediction (same logic)
    const prediction = predictNextMove(rawData, {rsi, macd, adx, ema9: ema9c, bbands: calculateBollingerBands(rawData)});
    document.getElementById('aiSignal').textContent = prediction.signal;
    document.getElementById('confidence').textContent = prediction.confidence.toFixed(0) + '%';
    document.getElementById('confidenceBar').style.width = Math.max(0, Math.min(100, prediction.confidence)) + '%';
    document.getElementById('nextMove').textContent = prediction.direction;
    const pulse = document.getElementById('signalPulse');
    pulse.style.backgroundColor = (prediction.score>30) ? colors.success : (prediction.score<-30) ? colors.error : colors.warning;
  }

  function predictNextMove(data, indicators){
    // copied simplified predictor from the original file — keep same scoring
    const rsi = indicators.rsi || 50;
    const macd = indicators.macd || {macd:[0],signal:[0]};
    const adx = indicators.adx || 0;
    const ema9 = indicators.ema9 || [data[data.length-1]];
    const bb = indicators.bbands || [];
    if(!data || data.length<6) return {signal:'NEUTRO',confidence:10,direction:'→',score:0,signals:[]};
    const current = data[data.length-1], prev=data[data.length-2];
    let score=0, signals=[];
    if(rsi<30){score+=25; signals.push('RSI oversold');} else if(rsi>70){score-=25; signals.push('RSI overbought');} else if(rsi<40){score+=12;} else if(rsi>60){score-=12;}
    const macdVal = macd.macd[macd.macd.length-1]||0, signalVal = macd.signal[macd.signal.length-1]||0;
    if(macdVal>signalVal && macdVal<0){score+=30; signals.push('MACD bullish cross');}
    else if(macdVal<signalVal && macdVal>0){score-=30; signals.push('MACD bearish cross');}
    else if(macdVal>signalVal){score+=15;} else {score-=15;}
    const emaVal = ema9[ema9.length-1]||current;
    if(current>emaVal && prev<emaVal){score+=20; signals.push('EMA breakout up');} else if(current<emaVal && prev>emaVal){score-=20; signals.push('EMA breakout down');} else if(current>emaVal){score+=10;} else{score-=10;}
    const lastBB = bb[bb.length-1]||{};
    if(lastBB.lower != null && current < lastBB.lower) {score+=15; signals.push('BB oversold');}
    else if(lastBB.upper != null && current > lastBB.upper) {score-=15; signals.push('BB overbought');}
    if(adx>25){score *= 1.08; signals.push('Strong trend');}
    const lookBack = Math.min(5, data.length-1);
    const momentum = current - data[data.length - lookBack -1] || 0;
    if(momentum>0) score+=5; else score-=5;
    score = Math.max(-100, Math.min(100, score)); const confidence = Math.abs(score);
    let signal='NEUTRO', direction='→';
    if(score>60){signal='🚀 COMPRA FORTE'; direction='↗↗';} else if(score>30){signal='📈 COMPRA'; direction='↗';} else if(score<-60){signal='📉 VENDA FORTE'; direction='↘↘';} else if(score<-30){signal='📊 VENDA'; direction='↘';}
    return {signal,confidence,direction,score,signals};
  }

  // WS management (Deriv)
  function startWS(){
    manualStop = false;
    if(ws && (ws.readyState===1 || ws.readyState===0)) return; // já aberto
    try {
      ws = new WebSocket(DERIV_WS_URL);
      ws.onopen = function(){ reconnectDelay=1000; postFlutter('ws-open'); subscribeMarket(currentMarket); postFlutter('ws-ready'); };
      ws.onmessage = function(ev){ try{ const msg = JSON.parse(ev.data); handleDerivMessage(msg); }catch(e){ console.error('msg parse err', e); } };
      ws.onclose = function(e){ postFlutter('ws-closed'); if(!manualStop) { setTimeout(()=>{ reconnectDelay = Math.min(reconnectDelay*1.5, ${20000}); startWS(); }, reconnectDelay); } };
      ws.onerror = function(err){ postFlutter('ws-error:'+JSON.stringify(err)); ws.close(); };
    } catch(e) { console.error('ws start err', e); setTimeout(()=>startWS(), reconnectDelay); }
  }

  function stopWS(){
    manualStop = true;
    try{ if(ws) { ws.close(); ws = null; postFlutter('ws-stopped'); } }catch(e){}
  }

  function postFlutter(msg){ try{ FlutterChannel.postMessage(msg); }catch(e){} }

  function subscribeMarket(mkt){
    try{
      if(!ws || ws.readyState!==1){
        // se ws ainda não está ready, guardamos mercado e garantimos start
        currentMarket = mkt;
        startWS();
        return;
      }
      // enviar pedido de ticks
      // esquece subscrições antigas pedindo "forget_all" (v3 permite forget_all)
      ws.send(JSON.stringify({forget_all: "ticks"}));
      ws.send(JSON.stringify({ticks: mkt}));
      postFlutter('subscribed:'+mkt);
    }catch(e){ console.error('subscribe err', e); }
  }

  function handleDerivMessage(msg){
    // Deriv retorna "tick" messages e outros
    if(msg.error){
      postFlutter('deriv-error:' + JSON.stringify(msg.error));
      return;
    }
    if(msg.tick){
      const t = msg.tick;
      // tick.quote contém o preço atual
      if(typeof t.quote === 'number'){
        rawData.push(Number(t.quote));
        // limit history length to avoid memory blow
        if(rawData.length > 1200) rawData.shift();
        initTimestamps();
        candleData = convertToCandlesticks(rawData,1);
        // update chart dataset
        try {
          if(myChart){
            if(myChart.config.type === 'candlestick'){
              const newCandles = convertToCandlesticks(rawData,1);
              myChart.data.labels = newCandles.map(c=>c.x);
              myChart.data.datasets[0].data = newCandles;
            } else {
              myChart.data.labels = timestamps;
              if(myChart.data.datasets.length === 0){
                myChart.data.datasets = [ { label:'Preço', data: rawData, fill:true, borderWidth:2 } ];
              } else {
                myChart.data.datasets[0].data = rawData;
              }
            }
            myChart.update('none');
          }
        } catch(e){ console.error('chart update err', e); }
        updateAllStats();
      }
      return;
    }
    // outros tipos de mensagens (authorize, balance, etc.) podem ser tratados aqui
    if(msg.echo_req && msg.echo_req.ticks){
      postFlutter('subscribed-ack:' + JSON.stringify(msg.echo_req));
    }
  }

  // Exposed to Flutter: setMarket, updateData, stopWS, startWS
  window.setMarket = function(mkt){
    try{
      currentMarket = String(mkt);
      postFlutter('market-changed:'+currentMarket);
      // limpa dados iniciais ao trocar de market
      rawData = [];
      startPrice = 0;
      initTimestamps();
      if(ws && ws.readyState===1){
        // pedir forget e subscrever novo mercado
        try{ ws.send(JSON.stringify({forget_all:"ticks"})); }catch(e){}
        try{ ws.send(JSON.stringify({ticks: currentMarket})); }catch(e){}
      } else {
        startWS();
      }
      // actualiza label no ui
      document.getElementById('marketInfo').querySelector('div').textContent = currentMarket;
    } catch(e){ console.error('setMarket err', e); postFlutter('setMarket-err:'+e.toString()); }
  };

  window.startWS = function(){ startWS(); };
  window.stopWS = function(){ stopWS(); };

  window.updateData = function(newArr){
    try{
      if(!Array.isArray(newArr) || newArr.length===0) return;
      rawData = newArr.map(Number);
      if(!startPrice || startPrice===0) startPrice = rawData[0] || rawData[rawData.length-1];
      initTimestamps();
      candleData = convertToCandlesticks(rawData,1);
      // update chart quickly
      if(myChart){
        if(myChart.config.type === 'candlestick'){
          const newCandles = convertToCandlesticks(rawData,1);
          myChart.data.labels = newCandles.map(c=>c.x);
          myChart.data.datasets[0].data = newCandles;
        } else {
          myChart.data.labels = timestamps;
          if(myChart.data.datasets.length === 0){
            myChart.data.datasets = [ { label:'Preço', data: rawData, fill:true, borderWidth:2 } ];
          } else {
            myChart.data.datasets[0].data = rawData;
          }
        }
        myChart.update('none');
      }
      updateAllStats();
      postFlutter('updateData-ack');
    } catch(e){ console.error('updateData err', e); postFlutter('updateData-err:'+e.toString()); }
  };

  // inicializa WS e chart
  // startWS(); // não iniciar automaticamente se preferires controlar a partir do Flutter
  postFlutter('chart-loaded');
  // iniciar automaticamente:
  startWS();

})();
</script>
</body></html>
''';
  }
}