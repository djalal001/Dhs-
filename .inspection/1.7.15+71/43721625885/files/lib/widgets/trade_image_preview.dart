import 'dart:io';

import 'package:flutter/material.dart';

import '../data/trade_file_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// A tappable local trade-image preview that opens a zoomable full-screen view.
class TradeImagePreview extends StatelessWidget {
  const TradeImagePreview({
    super.key,
    required this.path,
    required this.label,
    required this.fileNamePrefix,
    this.height = 100,
  });

  final String path;
  final String label;
  final String fileNamePrefix;
  final double height;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final tokens = TdTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: tokens.text2),
        ),
        const SizedBox(height: 8),
        Material(
          color: tokens.surface2,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('trade-image-preview-$fileNamePrefix-$path'),
            onTap: () => _openViewer(context),
            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.lineSubtle),
              ),
              child: file.existsSync()
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _unavailable(context),
                    )
                  : _unavailable(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unavailable(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 28,
          color: TdTokens.of(context).text3,
        ),
        if (height >= 96) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              tr(context, 'imageUnavailable'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TdTokens.of(context).text3,
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _openViewer(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _TradeImageViewerScreen(
        path: path,
        label: label,
        fileNamePrefix: fileNamePrefix,
      ),
    ),
  );
}

class _TradeImageViewerScreen extends StatefulWidget {
  const _TradeImageViewerScreen({
    required this.path,
    required this.label,
    required this.fileNamePrefix,
  });

  final String path;
  final String label;
  final String fileNamePrefix;

  @override
  State<_TradeImageViewerScreen> createState() =>
      _TradeImageViewerScreenState();
}

class _TradeImageViewerScreenState extends State<_TradeImageViewerScreen> {
  bool _saving = false;
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleZoom(Size viewportSize) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    const targetScale = 2.5;
    final offsetX = viewportSize.width * (1 - targetScale) / 2;
    final offsetY = viewportSize.height * (1 - targetScale) / 2;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(offsetX, offsetY, 0, 1)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1);
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final file = File(widget.path);
      if (!await file.exists()) {
        throw const FileSystemException('Image file is unavailable');
      }
      final extension = _imageExtension(widget.path);
      final bytes = await file.readAsBytes();
      final saved = await TradeFileService.saveImage(
        bytes,
        fileName:
            '${_safeFileName(widget.fileNamePrefix)}_${_timestamp()}.$extension',
        extension: extension,
        mimeType: _mimeType(extension),
      );
      if (!mounted) return;
      if (saved != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(tr(context, 'imageSaved'))),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${tr(context, 'operationFailed')}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.path);
    final tokens = TdTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.bgBase,
      appBar: AppBar(
        backgroundColor: tokens.bgBase,
        foregroundColor: tokens.text1,
        title: Text(widget.label),
        actions: [
          IconButton(
            key: const ValueKey('save-trade-image'),
            tooltip: tr(context, 'saveImage'),
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            onPressed: _saving ? null : _saveImage,
            icon: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.text1,
                    ),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: file.existsSync()
            ? LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  key: const ValueKey('trade-image-viewer-gestures'),
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => _toggleZoom(
                    Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  child: InteractiveViewer(
                    key: const ValueKey('zoomable-trade-image'),
                    transformationController: _transformationController,
                    minScale: 1,
                    maxScale: 5,
                    boundaryMargin: const EdgeInsets.all(96),
                    clipBehavior: Clip.none,
                    child: SizedBox.expand(
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _viewerUnavailable(context),
                      ),
                    ),
                  ),
                ),
              )
            : _viewerUnavailable(context),
      ),
    );
  }

  Widget _viewerUnavailable(BuildContext context) => Center(
    child: Text(
      tr(context, 'imageUnavailable'),
      style: const TextStyle(color: Colors.white),
    ),
  );
}

String _safeFileName(String prefix) {
  final safe = prefix.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return safe.isEmpty ? 'traderdesk_image' : safe;
}

String _imageExtension(String path) {
  final basename = path.split(Platform.pathSeparator).last;
  final dot = basename.lastIndexOf('.');
  final extension = dot < 0 ? '' : basename.substring(dot + 1).toLowerCase();
  const supported = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};
  return supported.contains(extension) ? extension : 'jpg';
}

String _mimeType(String extension) => switch (extension) {
  'png' => 'image/png',
  'webp' => 'image/webp',
  'gif' => 'image/gif',
  'bmp' => 'image/bmp',
  _ => 'image/jpeg',
};

String _timestamp() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
}
