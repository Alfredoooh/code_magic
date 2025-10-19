import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

class FeedbackScreen extends StatefulWidget {
  final String currentLocale;

  const FeedbackScreen({
    required this.currentLocale,
    Key? key,
  }) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  // Email de destino para feedback
  final String _feedbackEmail = 'feedback@seuapp.com'; // Altere para o seu email

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
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
          'successTitle': 'Success!',
          'successMessage': 'Thank you for your feedback!',
          'errorTitle': 'Error',
          'errorMessage': 'Could not send feedback. Please try again.',
          'emptyFieldsTitle': 'Empty Fields',
          'emptyFieldsMessage': 'Please fill in all fields before sending.',
          'infoMessage': 'Your feedback helps us improve the app!',
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
          'successTitle': '¡Éxito!',
          'successMessage': '¡Gracias por tus comentarios!',
          'errorTitle': 'Error',
          'errorMessage': 'No se pudo enviar los comentarios. Inténtalo de nuevo.',
          'emptyFieldsTitle': 'Campos Vacíos',
          'emptyFieldsMessage': 'Por favor completa todos los campos antes de enviar.',
          'infoMessage': '¡Tus comentarios nos ayudan a mejorar la app!',
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
          'successTitle': 'Sucesso!',
          'successMessage': 'Obrigado pelo seu feedback!',
          'errorTitle': 'Erro',
          'errorMessage': 'Não foi possível enviar o feedback. Tente novamente.',
          'emptyFieldsTitle': 'Campos Vazios',
          'emptyFieldsMessage': 'Por favor, preencha todos os campos antes de enviar.',
          'infoMessage': 'O seu feedback ajuda-nos a melhorar a app!',
        };
    }
  }

  Future<void> _sendFeedback() async {
    final texts = _getTexts();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      AppDialogs.showError(
        context,
        texts['emptyFieldsTitle']!,
        texts['emptyFieldsMessage']!,
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
          AppDialogs.showSuccess(
            context,
            texts['successTitle']!,
            texts['successMessage']!,
            onClose: () {
              Navigator.pop(context);
            },
          );
        }
      } else {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(
          context,
          texts['errorTitle']!,
          texts['errorMessage']!,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: texts['title']!,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Center(
                child: Column(
                  children: [
                    AppIconCircle(
                      icon: Icons.chat_bubble_outline,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    AppSectionTitle(
                      text: texts['subtitle']!,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Campo Assunto
              AppFieldLabel(text: texts['subjectLabel']!),
              SizedBox(height: 8),
              AppTextField(
                controller: _subjectController,
                hintText: texts['subjectPlaceholder']!,
                maxLines: 1,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 4),
              Text(
                '${100 - _subjectController.text.length} caracteres restantes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 24),

              // Campo Mensagem
              AppFieldLabel(text: texts['messageLabel']!),
              SizedBox(height: 8),
              AppTextField(
                controller: _messageController,
                hintText: texts['messagePlaceholder']!,
                maxLines: 8,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 4),
              Text(
                '${500 - _messageController.text.length} caracteres restantes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 32),

              // Botão Enviar
              AppPrimaryButton(
                text: texts['sendButton']!,
                onPressed: _sendFeedback,
                isLoading: _isSending,
              ),
              SizedBox(height: 24),

              // Informação adicional
              AppInfoCard(
                icon: Icons.info_outline,
                text: texts['infoMessage']!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}