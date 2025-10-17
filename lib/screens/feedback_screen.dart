import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  final String currentLocale;
  final bool isDark;

  const FeedbackScreen({
    required this.currentLocale,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();
  bool _isSending = false;

  // Email de destino para feedback
  final String _feedbackEmail = 'feedback@seuapp.com'; // Altere para o seu email

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _subjectFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Map<String, String> _getTexts() {
    switch (widget.currentLocale) {
      case 'en':
        return {
          'title': 'Feedback',
          'subtitle': 'We appreciate your opinion',
          'subjectLabel': 'Subject',
          'subjectPlaceholder': 'What is your feedback about?',
          'messageLabel': 'Message',
          'messagePlaceholder': 'Tell us your suggestion, compliment or report an issue...',
          'sendButton': 'Send Feedback',
          'cancelButton': 'Cancel',
          'successTitle': 'Success!',
          'successMessage': 'Thank you for your feedback!',
          'errorTitle': 'Error',
          'errorMessage': 'Could not send feedback. Please try again.',
          'emptyFieldsTitle': 'Empty Fields',
          'emptyFieldsMessage': 'Please fill in all fields before sending.',
          'okButton': 'OK',
          'charactersRemaining': 'characters remaining',
        };
      case 'es':
        return {
          'title': 'Comentarios',
          'subtitle': 'Apreciamos tu opinión',
          'subjectLabel': 'Asunto',
          'subjectPlaceholder': '¿Sobre qué es tu comentario?',
          'messageLabel': 'Mensaje',
          'messagePlaceholder': 'Cuéntanos tu sugerencia, elogio o reporta un problema...',
          'sendButton': 'Enviar Comentarios',
          'cancelButton': 'Cancelar',
          'successTitle': '¡Éxito!',
          'successMessage': '¡Gracias por tus comentarios!',
          'errorTitle': 'Error',
          'errorMessage': 'No se pudo enviar los comentarios. Inténtalo de nuevo.',
          'emptyFieldsTitle': 'Campos Vacíos',
          'emptyFieldsMessage': 'Por favor completa todos los campos antes de enviar.',
          'okButton': 'OK',
          'charactersRemaining': 'caracteres restantes',
        };
      default: // pt
        return {
          'title': 'Feedback',
          'subtitle': 'Valorizamos a sua opinião',
          'subjectLabel': 'Assunto',
          'subjectPlaceholder': 'Sobre o que é o seu feedback?',
          'messageLabel': 'Mensagem',
          'messagePlaceholder': 'Conte-nos a sua sugestão, elogio ou reporte um problema...',
          'sendButton': 'Enviar Feedback',
          'cancelButton': 'Cancelar',
          'successTitle': 'Sucesso!',
          'successMessage': 'Obrigado pelo seu feedback!',
          'errorTitle': 'Erro',
          'errorMessage': 'Não foi possível enviar o feedback. Tente novamente.',
          'emptyFieldsTitle': 'Campos Vazios',
          'emptyFieldsMessage': 'Por favor, preencha todos os campos antes de enviar.',
          'okButton': 'OK',
          'charactersRemaining': 'caracteres restantes',
        };
    }
  }

  Future<void> _sendFeedback() async {
    final texts = _getTexts();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(texts['emptyFieldsTitle']!),
          content: Text(texts['emptyFieldsMessage']!),
          actions: [
            CupertinoDialogAction(
              child: Text(texts['okButton']!),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: _feedbackEmail,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': message,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(texts['successTitle']!),
              content: Text(texts['successMessage']!),
              actions: [
                CupertinoDialogAction(
                  child: Text(texts['okButton']!),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(texts['errorTitle']!),
            content: Text(texts['errorMessage']!),
            actions: [
              CupertinoDialogAction(
                child: Text(texts['okButton']!),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final texts = _getTexts();
    final isDark = widget.isDark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: const Color(0xFFFF444F),
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          texts['title']!,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            _subjectFocus.unfocus();
            _messageFocus.unfocus();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header com ícone
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF444F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.chat_bubble_text_fill,
                        size: 40,
                        color: Color(0xFFFF444F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      texts['subtitle']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Campo Assunto
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        texts['subjectLabel']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoTextField(
                        controller: _subjectController,
                        focusNode: _subjectFocus,
                        placeholder: texts['subjectPlaceholder']!,
                        maxLength: 100,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        decoration: const BoxDecoration(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        '${100 - _subjectController.text.length} ${texts['charactersRemaining']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo Mensagem
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        texts['messageLabel']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoTextField(
                        controller: _messageController,
                        focusNode: _messageFocus,
                        placeholder: texts['messagePlaceholder']!,
                        maxLines: 8,
                        maxLength: 500,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                        placeholderStyle: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        decoration: const BoxDecoration(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        '${500 - _messageController.text.length} ${texts['charactersRemaining']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botão Enviar
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: const Color(0xFFFF444F),
                borderRadius: BorderRadius.circular(100),
                onPressed: _isSending ? null : _sendFeedback,
                child: _isSending
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.paperplane_fill,
                            size: 20,
                            color: CupertinoColors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            texts['sendButton']!,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              
              // Informação adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF444F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF444F).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle_fill,
                      color: Color(0xFFFF444F),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.currentLocale == 'en'
                            ? 'Your feedback helps us improve the app!'
                            : widget.currentLocale == 'es'
                                ? '¡Tus comentarios nos ayudan a mejorar la app!'
                                : 'O seu feedback ajuda-nos a melhorar a app!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}