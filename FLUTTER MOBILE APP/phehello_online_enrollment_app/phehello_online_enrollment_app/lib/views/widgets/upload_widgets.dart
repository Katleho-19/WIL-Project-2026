import 'package:flutter/material.dart';

import '../../models/picked_document.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import 'buttons.dart';

/// One supporting-document row (Birth Certificate, Progress Report, ...).
class DocumentUploadTile extends StatelessWidget {
  const DocumentUploadTile({
    super.key,
    required this.label,
    required this.hint,
    required this.file,
    required this.onPick,
    required this.onRemove,
    this.showError = false,
  });

  final String label;
  final String hint;
  final PickedDocument? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: showError && !hasFile ? AppColors.error : AppColors.border,
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          if (hasFile && file!.isImage)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(file!.bytes, width: 42, height: 42, fit: BoxFit.cover),
              ),
            )
          else if (hasFile)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.picture_as_pdf_outlined, size: 32, color: AppColors.brown),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  hasFile ? '${file!.name} • ${Formatters.fileSize(file!.size)}' : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: showError && !hasFile ? AppColors.error : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!hasFile)
            SmallOutlineButton(label: 'Upload', onPressed: onPick)
          else ...[
            SmallOutlineButton(label: 'Replace', onPressed: onPick),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dashed drop-zone with "Choose File" (Proof of Payment screen).
class UploadDropZone extends StatelessWidget {
  const UploadDropZone({super.key, required this.onChoose, this.error = false});

  final VoidCallback onChoose;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: error ? AppColors.error : const Color(0xFFBDB27A)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 54, color: Color(0xFF9DB8D8)),
            const SizedBox(height: 10),
            const Text('Upload Payment Proof',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('JPG, PNG or PDF • Maximum 5 MB',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Choose File', onPressed: onChoose),
          ],
        ),
      ),
    );
  }
}

/// Card showing the file the parent selected (name, size, remove X).
class SelectedFileCard extends StatelessWidget {
  const SelectedFileCard({super.key, required this.file, required this.onRemove});

  final PickedDocument file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.3),
      ),
      child: Row(
        children: [
          if (file.isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(file.bytes, width: 46, height: 46, fit: BoxFit.cover),
            )
          else
            const Icon(Icons.picture_as_pdf_outlined, size: 38, color: AppColors.brown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(Formatters.fileSize(file.size),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 26),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + 7).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
