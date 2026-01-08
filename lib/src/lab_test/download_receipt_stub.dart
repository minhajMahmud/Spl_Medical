// Fallback implementation used on non-web platforms (mobile / desktop).
// This generates a PDF receipt file and attempts to open it.

import 'dart:io';
import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'lab_booking_pdf.dart';

Future<void> downloadBookingReceipt(Map<String, dynamic> bookingData) async {
  // Build the PDF in memory.
  final Uint8List bytes = await buildBookingReceiptPdf(bookingData);

  // Choose a reasonable directory depending on platform.
  Directory baseDir;
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      // Desktop platforms
      baseDir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  } catch (_) {
    baseDir = await getApplicationDocumentsDirectory();
  }

  final bookingId = (bookingData['bookingId'] ?? '').toString();
  final baseName = bookingId.isNotEmpty
      ? 'lab_booking_$bookingId.pdf'
      : 'lab_booking_receipt.pdf';

  // Ensure filename is safe.
  final safeName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final file = File('${baseDir.path}/$safeName');

  await file.writeAsBytes(bytes, flush: true);

  // Try to open the file with the default handler.
  try {
    await OpenFile.open(file.path);
  } catch (_) {
    // If open fails, the file is still saved; caller can notify user.
  }
}
