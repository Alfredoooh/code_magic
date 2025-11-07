// lib/services/image_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Service centralizado para manipulação de imagens:
/// - seleção (câmera / galeria)
/// - compressão / redimensionamento
/// - conversão Base64 <-> bytes
/// - criação de thumbnail
/// - widgets para exibir imagens (base64 / url) com placeholders e fallback
class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pega imagem (gallery ou camera) e retorna Base64 (ou null se cancelado)
  /// usa compressão interna antes de converter
  static Future<String?> pickImageAsBase64({
    required ImageSource source,
    int maxDimension = 1920,
    int quality = 85,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension.toDouble(),
        maxHeight: maxDimension.toDouble(),
        imageQuality: quality,
      );

      if (file == null) return null;

      final bytes = await file.readAsBytes();
      final compressed = await compressImage(bytes, maxDimension: maxDimension, quality: quality);
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('ImageService.pickImageAsBase64 error: $e');
      return null;
    }
  }

  /// Pega imagem (gallery/camera) e retorna os bytes comprimidos (Uint8List) ou null
  static Future<Uint8List?> pickImageAsBytes({
    required ImageSource source,
    int maxDimension = 1920,
    int quality = 85,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension.toDouble(),
        maxHeight: maxDimension.toDouble(),
        imageQuality: quality,
      );

      if (file == null) return null;

      final bytes = await file.readAsBytes();
      final compressed = await compressImage(bytes, maxDimension: maxDimension, quality: quality);
      return compressed;
    } catch (e) {
      debugPrint('ImageService.pickImageAsBytes error: $e');
      return null;
    }
  }

  /// Compress / resize usando package:image (funciona em mobile e web)
  /// Retorna bytes comprimidos (JPEG)
  static Future<Uint8List> compressImage(
    Uint8List bytes, {
    int maxDimension = 1920,
    int quality = 85,
  }) async {
    try {
      // Decodifica
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        // se não decodificou, retorna original
        return bytes;
      }

      // Rotacionamento baseado em EXIF (se existir) - image package lê orientação automaticamente ao decodificar
      // Redimensiona mantendo proporção
      final int width = image.width;
      final int height = image.height;
      if (width > maxDimension || height > maxDimension) {
        if (width >= height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      // Codifica em JPEG com qualidade
      final encoded = img.encodeJpg(image, quality: quality);
      return Uint8List.fromList(encoded);
    } catch (e) {
      debugPrint('ImageService.compressImage error: $e');
      return bytes;
    }
  }

  /// Converte Base64 para bytes
  static Uint8List base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('ImageService.base64ToBytes error: $e');
      return Uint8List(0);
    }
  }

  /// Verifica se string é Base64 válida (simples)
  static bool isValidBase64(String? value) {
    if (value == null || value.isEmpty) return false;
    try {
      base64Decode(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cria thumbnail quadrado a partir de Base64 (retorna Base64 do thumbnail)
  static Future<String?> createThumbnailFromBase64(String base64String, {int size = 200, int quality = 80}) async {
    try {
      final bytes = base64Decode(base64String);
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      final thumb = img.copyResizeCropSquare(image, size);
      final encoded = img.encodeJpg(thumb, quality: quality);
      return base64Encode(encoded);
    } catch (e) {
      debugPrint('ImageService.createThumbnailFromBase64 error: $e');
      return null;
    }
  }

  /// Cria thumbnail quadrado a partir de bytes (retorna bytes)
  static Future<Uint8List?> createThumbnailFromBytes(Uint8List bytes, {int size = 200, int quality = 80}) async {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      final thumb = img.copyResizeCropSquare(image, size);
      final encoded = img.encodeJpg(thumb, quality: quality);
      return Uint8List.fromList(encoded);
    } catch (e) {
      debugPrint('ImageService.createThumbnailFromBytes error: $e');
      return null;
    }
  }

  /// Constrói widget a partir de Base64. Placeholder e errorWidget podem ser passados.
  static Widget buildImageFromBase64(
    String? base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool useFadeIn = true,
  }) {
    final ph = placeholder ?? _defaultPlaceholder(width: width, height: height);
    final err = errorWidget ?? _defaultPlaceholder(width: width, height: height);

    if (base64String == null || base64String.isEmpty) return ph;

    try {
      final bytes = base64Decode(base64String);
      if (useFadeIn) {
        return FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          image: MemoryImage(bytes),
          width: width,
          height: height,
          fit: fit,
          imageErrorBuilder: (_, __, ___) => err,
        );
      } else {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => err,
        );
      }
    } catch (e) {
      debugPrint('ImageService.buildImageFromBase64 error: $e');
      return err;
    }
  }

  /// Constrói widget a partir de URL com loading e error handling.
  /// Tenta usar cache manager em mobile/web; se falhar, usa Image.network direto.
  static Widget buildImageFromUrl(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool useFadeIn = true,
  }) {
    final ph = placeholder ?? _defaultPlaceholder(width: width, height: height);
    final err = errorWidget ?? _defaultPlaceholder(width: width, height: height);

    if (url.isEmpty) return ph;

    // se for web, Image.network com loadingBuilder é suficiente e compatível
    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(width: width, height: height, child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null)));
        },
        errorBuilder: (_, __, ___) => err,
      );
    }

    // mobile: tentar usar cache manager para reduzir requests
    return FutureBuilder<FileInfo?>(
      future: DefaultCacheManager().getFileFromCache(url).then((v) async {
        if (v != null) return v;
        try {
          // tenta baixar e guardar no cache
          final f = await DefaultCacheManager().getSingleFile(url);
          return await DefaultCacheManager().getFileFromCache(url);
        } catch (_) {
          return null;
        }
      }),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(width: width, height: height, child: Center(child: CircularProgressIndicator()));
        }
        final fileInfo = snap.data;
        if (fileInfo != null && fileInfo.file.existsSync()) {
          try {
            return Image.file(
              fileInfo.file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => err,
            );
          } catch (_) {
            return err;
          }
        }
        // fallback para Image.network
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(width: width, height: height, child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null)));
          },
          errorBuilder: (_, __, ___) => err,
        );
      },
    );
  }

  /// Widget placeholder padrão
  static Widget _defaultPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F2F5),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 36, color: Color(0xFFB0B3B8)),
      ),
    );
  }

  /// Mostra diálogo para escolher entre galeria ou câmera e retorna Base64 (ou null).
  /// Uso seguro: evita múltiplos Navigator.pop no fluxo.
  static Future<String?> showImageSourceDialogAsBase64(BuildContext context, {int maxDimension = 1920, int quality = 85}) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Selecionar imagem'),
          children: [
            SimpleDialogOption(
              child: const ListTile(leading: Icon(Icons.photo_library), title: Text('Galeria')),
              onPressed: () async {
                Navigator.pop(ctx, 'gallery');
              },
            ),
            SimpleDialogOption(
              child: const ListTile(leading: Icon(Icons.camera_alt), title: Text('Câmera')),
              onPressed: () async {
                Navigator.pop(ctx, 'camera');
              },
            ),
            SimpleDialogOption(
              child: const ListTile(leading: Icon(Icons.close), title: Text('Cancelar')),
              onPressed: () => Navigator.pop(ctx, null),
            ),
          ],
        );
      },
    );

    if (result == 'gallery') {
      return await pickImageAsBase64(source: ImageSource.gallery, maxDimension: maxDimension, quality: quality);
    } else if (result == 'camera') {
      return await pickImageAsBase64(source: ImageSource.camera, maxDimension: maxDimension, quality: quality);
    }
    return null;
  }

  /// Download de imagem remota e retorno de bytes (útil para gerar thumbnail etc).
  static Future<Uint8List?> fetchUrlBytes(String url) async {
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) return resp.bodyBytes;
      return null;
    } catch (e) {
      debugPrint('ImageService.fetchUrlBytes error: $e');
      return null;
    }
  }

  /// Pequeno helper para verificar se string parece ser uma URL de imagem
  static bool looksLikeImageUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.contains('image') || lower.contains('imgur') || lower.contains('cdn');
  }

  // Transparent 1x1 PNG in memory for FadeInImage placeholder
  static final kTransparentImage = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
  );
}

/// Widget customizado para exibir avatar com suporte a Base64 (mantém compatibilidade)
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
    final bg = backgroundColor ?? const Color(0xFF1877F2);
    if (base64Image != null && ImageService.isValidBase64(base64Image)) {
      final bytes = ImageService.base64ToBytes(base64Image!);
      if (bytes.isNotEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: MemoryImage(bytes),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
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

/// Widget para exibir imagem de post (aceita Base64 ou URL) e abre fullscreen ao tocar
class PostImageWidget extends StatelessWidget {
  final String source; // pode ser base64 ou url
  final double? height;
  final VoidCallback? onTap;

  const PostImageWidget({
    super.key,
    required this.source,
    this.height,
    this.onTap,
  });

  bool _isBase64(String s) => ImageService.isValidBase64(s);
  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_isBase64(source)) {
      child = ImageService.buildImageFromBase64(source, height: height, width: double.infinity, fit: BoxFit.cover);
    } else if (_isUrl(source)) {
      child = ImageService.buildImageFromUrl(source, height: height, width: double.infinity, fit: BoxFit.cover);
    } else {
      child = ImageService._defaultPlaceholder(width: double.infinity, height: height);
    }

    return GestureDetector(
      onTap: onTap ??
          () {
            // Fullscreen viewer
            Navigator.of(context).push(MaterialPageRoute(builder: (_) {
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
                body: Center(
                  child: InteractiveViewer(
                    child: _isBase64(source)
                        ? Image.memory(ImageService.base64ToBytes(source))
                        : _isUrl(source)
                            ? Image.network(source)
                            : ImageService._defaultPlaceholder(),
                  ),
                ),
              );
            }));
          },
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF0F2F5),
        child: child,
      ),
    );
  }
}