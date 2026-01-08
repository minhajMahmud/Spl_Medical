import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';

Future<Uint8List> buildBookingReceiptPdf(Map<String, dynamic> booking) async {
  // Ensure Bangla font manager is initialized for character shaping
  await BanglaFontManager().initialize();

  // Load fonts and images
  final kalpurushData = await rootBundle.load('assets/fonts/Kalpurush.ttf');
  final kalpurushFont = pw.Font.ttf(kalpurushData);

  final logoData = await rootBundle.load('assets/images/nstu_logo.jpg');
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

  // Load the banner image for the university name (replacing broken Bangla font)
  // Ensure 'assets/images/nstu_banner.png' exists in your project
  final bannerData = await rootBundle.load('assets/images/nstu_banner.png');
  final bannerImage = pw.MemoryImage(bannerData.buffer.asUint8List());

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: kalpurushFont,
      bold: kalpurushFont,
      italic: kalpurushFont,
      boldItalic: kalpurushFont,
    ),
  );

  String _string(dynamic v) => v == null ? '' : v.toString();

  final bookingId = _string(booking['bookingId']);
  final patientName = _string(booking['patient']);
  final patientId = _string(booking['patientId']);
  final patientPhone = _string(booking['patientPhone']);
  final patientEmail = _string(booking['patientEmail']);
  final patientType = _string(booking['patientType']);
  final bookingDate = _string(booking['bookingDate']);
  final amount = _string(booking['amount']);
  final paymentMethod =
      'Cash'; // Hardcoded as per UI for now, or fetch if available

  final tests = (booking['tests'] as List?) ?? const [];

  // Helper for labeled rows
  pw.Widget _buildInfoRow(String label, String value, String iconText) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Icon placeholder (using text as icon is not available)
          pw.Container(
            width: 45,
            child: pw.Text(
              iconText,
              style: pw.TextStyle(
                color: PdfColors.blue,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return [
          // --- Custom Header ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(logoImage),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 280,
                        child: pw.Image(bannerImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Noakhali Science and Technology University',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Noakhali-3814, Bangladesh',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Removed Right side column as requested
            ],
          ),

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.blueGrey100, thickness: 0.5),
          pw.SizedBox(height: 10),

          // --- Booking Title & ID Box ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Lab Test Booking Receipt',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Official booking confirmation document',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.amber, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Booking ID',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      bookingId,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // --- Patient Information ---
          pw.Text(
            'Patient Information',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(color: PdfColors.blue200, thickness: 1),
          pw.SizedBox(height: 10),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Full Name', patientName, 'User'),
                    _buildInfoRow('Patient ID', patientId, 'ID'),
                    _buildInfoRow('Patient Type', patientType, 'Type'),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Phone', patientPhone, 'Ph'),
                    _buildInfoRow('Email', patientEmail, 'Email'),
                    _buildInfoRow('Booking Date', bookingDate, 'Date'),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // --- Test Details ---
          pw.Text(
            'Test Details',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(color: PdfColors.blue200, thickness: 1),
          pw.SizedBox(height: 10),

          pw.Table(
            border: null,
            columnWidths: {
              0: const pw.FixedColumnWidth(40), // S/N
              1: const pw.FlexColumnWidth(), // Test Name
              2: const pw.FixedColumnWidth(100), // Price
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'S/N',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Test Name',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Price (BDT)',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              // Data
              ...tests.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final t = (entry.value as Map).cast<String, dynamic>();
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$idx',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _string(t['test']),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '৳${_string(t['price'])}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 20),

          // --- Totals ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Total Amount:   ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        '৳$amount',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Payment Method:  $paymentMethod',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.Spacer(),

          // --- Footer Signatures ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Patient Signature',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: _______________',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Opacity(
                opacity: 0.5,
                child: pw.Image(
                  logoImage,
                  width: 60,
                  height: 60,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Lab In-Charge',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Thank you for choosing NSTU Medical Center',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          pw.Align(
            alignment: pw.Alignment.bottomLeft,
            child: pw.Text(
              'This is a computer-generated receipt.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ];
      },
    ),
  );

  return await doc.save();
}
