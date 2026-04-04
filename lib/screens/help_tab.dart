// lib/screens/help_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class HelpTab extends StatelessWidget {
  const HelpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = Provider.of<AppState>(context, listen: false).config;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Contact card ──
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF112F6C), Color(0xFF1A4A9E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF268CD4).withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cfg?.operatorInfo.isNotEmpty == true
                    ? cfg!.operatorInfo.first
                    : 'ElephantBet Angola',
                style: const TextStyle(
                    color: Color(0xFFFFCE00),
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (cfg?.phone.isNotEmpty == true)
                _contactRow(Icons.phone_rounded, cfg!.phone),
              if (cfg?.email.isNotEmpty == true)
                _contactRow(Icons.email_outlined, cfg!.email),
              _contactRow(
                  Icons.language_rounded, 'elephantbetzone.com'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── FAQ ──
        _Faq(
          question: 'Como fazer uma aposta?',
          answer:
              'Vá ao separador Desportos, escolha um jogo, toque numa odd (1, X ou 2) e confirme o bilhete. Pode combinar vários jogos para apostas múltiplas.',
        ),
        _Faq(
          question: 'Como verificar um bilhete?',
          answer:
              'No separador Bilhete, digitalize o QR code ou insira o número manualmente para verificar o estado e eventuais ganhos.',
        ),
        _Faq(
          question: 'Como funciona o cálculo de ganhos?',
          answer:
              'Ganho Bruto = Aposta × Índice Total. É aplicado IVA de 15%. Ganho Líquido = Ganho Bruto − IVA.',
        ),
        _Faq(
          question: 'Segurança',
          answer:
              'Todas as comunicações usam HTTPS com tokens JWT. Cada pedido é assinado com SHA-256(token + chave privada + nonce).',
        ),
        _Faq(
          question: 'Versão',
          answer: 'ElephantBet AO POS Player v1.0.0\nPlataforma Koralplay.',
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
}

class _Faq extends StatefulWidget {
  final String question;
  final String answer;
  const _Faq({required this.question, required this.answer});
  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 10),
                Text(widget.answer,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}