// Web implementation: download the lab booking receipt as a PDF.

import 'dart:html' as html;
import 'dart:typed_data';

import 'lab_booking_pdf.dart';

Future<void> downloadBookingReceipt(Map<String, dynamic> bookingData) async {
  final Uint8List bytes = await buildBookingReceiptPdf(bookingData);

  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final bookingId = (bookingData['bookingId'] ?? '').toString();
  final filename = bookingId.isNotEmpty
      ? 'lab_booking_$bookingId.pdf'
      : 'lab_booking_receipt.pdf';

  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}
