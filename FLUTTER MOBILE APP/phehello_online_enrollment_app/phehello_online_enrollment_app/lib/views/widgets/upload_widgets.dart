//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: upload_widgets.dart defines the widgets used for choosing files: a row for each
// supporting document, the dashed drop zone for the proof of payment, and the card that shows the
// chosen file.

import 'package:flutter/material.dart';

import '../../models/picked_document.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import 'buttons.dart';

/// DocumentUploadTile (class) - one supporting-document row (e.g. Birth Certificate). It shows a thumbnail
/// or PDF icon once a file is chosen, the label, the file name and size (or the hint), and an Upload
/// button (or Replace and a remove X). showError turns the border and hint red when the file is missing.
/// One supporting-document row (Birth Certificate, Progress Report, ...).
class DocumentUploadTile extends StatelessWidget {
  /// Constructor - label, hint, file, onPick and onRemove are required; showError defaults to false.
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

  /// build() - lays out the thumbnail/icon, the text column and the action buttons inside a bordered container.
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
                child: Image.memory(
                  file!.bytes,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (hasFile)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                size: 32,
                color: AppColors.brown,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasFile
                      ? '${file!.name} • ${Formatters.fileSize(file!.size)}'
                      : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: showError && !hasFile
                        ? AppColors.error
                        : AppColors.textMuted,
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

/// UploadDropZone (class) - the dashed box on the Proof of Payment step with a cloud icon, the allowed file
/// types and a "Choose File" button. error makes the dashed border red.
/// Dashed drop-zone with "Choose File" (Proof of Payment screen).
class UploadDropZone extends StatelessWidget {
  /// Constructor - onChoose is required; error defaults to false.
  const UploadDropZone({super.key, required this.onChoose, this.error = false});

  final VoidCallback onChoose;
  final bool error;

  /// build() - paints the dashed border with a custom painter around the icon, text and button.
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: error ? AppColors.error : const Color(0xFFBDB27A),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 54,
              color: Color(0xFF9DB8D8),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload Payment Proof',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'JPG, PNG or PDF • Maximum 5 MB',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Choose File', onPressed: onChoose),
          ],
        ),
      ),
    );
  }
}

/// SelectedFileCard (class) - shows the chosen file (thumbnail or PDF icon, name, size) with an X button to remove it.
/// Card showing the file the parent selected (name, size, remove X).
class SelectedFileCard extends StatelessWidget {
  /// Constructor - file and onRemove are required.
  const SelectedFileCard({
    super.key,
    required this.file,
    required this.onRemove,
  });

  final PickedDocument file;
  final VoidCallback onRemove;

  /// build() - a bordered tile with the preview, the name and size, and the remove button.
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
              child: Image.memory(
                file.bytes,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            )
          else
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 38,
              color: AppColors.brown,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  Formatters.fileSize(file.size),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
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

/// _DashedBorderPainter (class) - a custom painter that draws a dashed rounded-rectangle border.
class _DashedBorderPainter extends CustomPainter {
  /// Constructor - the line colour is required.
  _DashedBorderPainter({required this.color});

  final Color color;

  /// paint() - builds a rounded-rectangle path, walks along it and draws short 7-pixel dashes every 12 pixels
  /// using the chosen colour.
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

  /// shouldRepaint() - tells Flutter to repaint only when the colour changes.
  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
