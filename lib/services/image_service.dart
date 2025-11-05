// lib/services/image_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Seleciona imagem da galeria e converte para Base64
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final compressed = await compressImage(bytes);
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Captura imagem da câmera e converte para Base64
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final compressed = await compressImage(bytes);
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('Erro ao capturar imagem: $e');
      return null;
    }
  }

  /// Comprime imagem para reduzir tamanho
  static Future<Uint8List> compressImage(Uint8List bytes) async {
    try {
      // Decodifica imagem
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Redimensiona se necessário
      if (image.width > 1920 || image.height > 1920) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
      }

      // Comprime como JPEG
      final compressed = img.encodeJpg(image, quality: 85);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Erro ao comprimir imagem: $e');
      return bytes;
    }
  }

  /// Converte Base64 para Uint8List
  static Uint8List base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Erro ao decodificar Base64: $e');
      return Uint8List(0);
    }
  }

  /// Verifica se string é Base64 válido
  static bool isValidBase64(String? value) {
    if (value == null || value.isEmpty) return false;
    try {
      base64Decode(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cria thumbnail de imagem Base64
  static Future<String?> createThumbnail(String base64String, {int size = 200}) async {
    try {
      final bytes = base64Decode(base64String);
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Cria thumbnail quadrado
      final thumbnail = img.copyResizeCropSquare(image, size: size);
      final compressed = img.encodeJpg(thumbnail, quality: 80);
      
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('Erro ao criar thumbnail: $e');
      return null;
    }
  }

  /// Widget para exibir imagem Base64
  static Widget buildImageFromBase64(
    String? base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (base64String == null || base64String.isEmpty) {
      return errorWidget ?? _buildDefaultPlaceholder();
    }

    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultPlaceholder();
        },
      );
    } catch (e) {
      return errorWidget ?? _buildDefaultPlaceholder();
    }
  }

  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: const Color(0xFFF0F2F5),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Color(0xFFB0B3B8),
        ),
      ),
    );
  }

  /// Mostra dialog para escolher fonte da imagem
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final result = await pickImageFromGallery();
                if (context.mounted && result != null) {
                  Navigator.pop(context, result);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final result = await pickImageFromCamera();
                if (context.mounted && result != null) {
                  Navigator.pop(context, result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget customizado para exibir avatar com suporte a Base64
class Base64Avatar extends StatelessWidget {
  final String? base64Image;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  const Base64Avatar({
    super.key,
    this.base64Image,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (base64Image != null && ImageService.isValidBase64(base64Image)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFF1877F2),
        backgroundImage: MemoryImage(ImageService.base64ToBytes(base64Image!)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF1877F2),
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Widget para exibir imagem de post com carregamento
class PostImageWidget extends StatelessWidget {
  final String base64Image;
  final double? height;
  final VoidCallback? onTap;

  const PostImageWidget({
    super.key,
    required this.base64Image,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF0F2F5),
        child: ImageService.buildImageFromBase64(
          base64Image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
