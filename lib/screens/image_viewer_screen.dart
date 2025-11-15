// lib/screens/image_viewer_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../services/image_service.dart';
import '../widgets/custom_icons.dart';

enum ImageType { url, base64, file, bytes }

class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final String initialUrl;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    required this.initialUrl,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  bool _showControls = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.imageUrls.indexOf(widget.initialUrl);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  ImageType _detectImageType(String imageData) {
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return ImageType.url;
    } else if (imageData.startsWith('data:image')) {
      return ImageType.base64;
    } else if (imageData.startsWith('/') || imageData.contains('file://')) {
      return ImageType.file;
    } else if (imageData.length > 100 && !imageData.contains(' ')) {
      // Provavelmente base64 sem prefixo
      return ImageType.base64;
    }
    return ImageType.url;
  }

  Widget _buildImageWidget(String imageData) {
    final imageType = _detectImageType(imageData);

    try {
      switch (imageType) {
        case ImageType.url:
          return Image.network(
            imageData,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1877F2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando imagem...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget('Erro ao carregar imagem da URL');
            },
          );

        case ImageType.base64:
          try {
            Uint8List bytes;
            if (imageData.startsWith('data:image')) {
              // Remove o prefixo data:image/png;base64, ou similar
              final base64String = imageData.split(',').last;
              bytes = base64Decode(base64String);
            } else {
              bytes = base64Decode(imageData);
            }
            return Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget('Erro ao decodificar Base64');
              },
            );
          } catch (e) {
            return _buildErrorWidget('Base64 inválido: $e');
          }

        case ImageType.file:
          final filePath = imageData.replaceFirst('file://', '');
          return Image.file(
            File(filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget('Erro ao carregar arquivo local');
            },
          );

        case ImageType.bytes:
          return _buildErrorWidget('Tipo de imagem não suportado');
      }
    } catch (e) {
      return _buildErrorWidget('Erro ao processar imagem: $e');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final imageData = widget.imageUrls[_currentIndex];
      final imageType = _detectImageType(imageData);
      Uint8List? bytes;
      String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}';

      switch (imageType) {
        case ImageType.url:
          final response = await http.get(
            Uri.parse(imageData),
            headers: {'Accept': 'image/*'},
          );
          
          if (response.statusCode == 200) {
            bytes = response.bodyBytes;
            // Tenta extrair extensão da URL
            final uri = Uri.parse(imageData);
            final extension = uri.path.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
              fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.$extension';
            } else {
              fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
            }
          }
          break;

        case ImageType.base64:
          if (imageData.startsWith('data:image')) {
            final base64String = imageData.split(',').last;
            final mimeType = imageData.split(';').first.split(':').last;
            final extension = mimeType.split('/').last;
            bytes = base64Decode(base64String);
            fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.$extension';
          } else {
            bytes = base64Decode(imageData);
            fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          }
          break;

        case ImageType.file:
          final filePath = imageData.replaceFirst('file://', '');
          final file = File(filePath);
          bytes = await file.readAsBytes();
          fileName = filePath.split('/').last;
          break;

        case ImageType.bytes:
          break;
      }

      if (bytes != null && mounted) {
        setState(() => _downloadProgress = 0.5);

        // Salva no diretório de downloads
        final directory = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download')
            : await getApplicationDocumentsDirectory();

        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        setState(() => _downloadProgress = 1.0);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Imagem salva com sucesso!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filePath,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Compartilhar',
                textColor: Colors.white,
                onPressed: () async {
                  await Share.shareXFiles([XFile(filePath)]);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Erro ao baixar: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      final imageData = widget.imageUrls[_currentIndex];
      final imageType = _detectImageType(imageData);

      if (imageType == ImageType.url) {
        await Share.share(imageData, subject: 'Compartilhar imagem');
      } else {
        // Para outros tipos, primeiro salva temporariamente
        Uint8List? bytes;

        if (imageType == ImageType.base64) {
          if (imageData.startsWith('data:image')) {
            final base64String = imageData.split(',').last;
            bytes = base64Decode(base64String);
          } else {
            bytes = base64Decode(imageData);
          }
        } else if (imageType == ImageType.file) {
          final filePath = imageData.replaceFirst('file://', '');
          final file = File(filePath);
          bytes = await file.readAsBytes();
        }

        if (bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
            '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tempFile.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(tempFile.path)]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: SvgPicture.string(
                  CustomIcons.arrowLeft,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareImage,
                ),
                IconButton(
                  icon: _isDownloading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  onPressed: _isDownloading ? null : _downloadImage,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Imagem principal
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: _buildImageWidget(widget.imageUrls[index]),
                  ),
                );
              },
            ),

            // Indicador de tipo de imagem (canto superior direito)
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(_detectImageType(widget.imageUrls[_currentIndex])),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTypeLabel(_detectImageType(widget.imageUrls[_currentIndex])),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Controles de navegação (setas laterais)
            if (_showControls && widget.imageUrls.length > 1) ...[
              // Seta esquerda
              if (_currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),

              // Seta direita
              if (_currentIndex < widget.imageUrls.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // Miniaturas na parte inferior
            if (_showControls && widget.imageUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1877F2)
                                  : Colors.white30,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildImageWidget(widget.imageUrls[index]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(ImageType type) {
    switch (type) {
      case ImageType.url:
        return Icons.language;
      case ImageType.base64:
        return Icons.code;
      case ImageType.file:
        return Icons.folder;
      case ImageType.bytes:
        return Icons.memory;
    }
  }

  String _getTypeLabel(ImageType type) {
    switch (type) {
      case ImageType.url:
        return 'URL';
      case ImageType.base64:
        return 'Base64';
      case ImageType.file:
        return 'Arquivo';
      case ImageType.bytes:
        return 'Bytes';
    }
  }
}