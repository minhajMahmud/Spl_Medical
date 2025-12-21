import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';
import 'package:pdf/widgets.dart' as pw;
// Conditional imports
import 'package:universal_html/html.dart' as html;
import 'dart:io' show File;
import 'package:path_provider/path_provider.dart';

class PatientPrescriptions extends StatefulWidget {
  const PatientPrescriptions({super.key});

  @override
  State<PatientPrescriptions> createState() => _PatientPrescriptionsPageState();
}

class _PatientPrescriptionsPageState extends State<PatientPrescriptions> {
  pw.Font? _bengaliFont;
  pw.Font? _openSansFont;
  Uint8List? _logoBytes;
  bool _isLoading = true;
  bool _isDisposed = false;

  final List<Map<String, dynamic>> prescriptions = [
    {
      "date": "2025-09-01",
      "doctor": "Dr. Wakil Ahmed",
      "roll": "2022331001",
      "name": "Abtahee",
      "age": "22",
      "gender": "Male",
      "complaints": "Fever and headache for 2 days",
      "examination": "BP: 120/80, Temp: 100F, Pulse: 80/min",
      "medicines": [
        {
          "name": "1. Paracetamol",
          "dosage": "1+1+1",
          "duration": "3 days after meal",
        },
        {
          "name": "2. Vitamin C",
          "dosage": "0+1+1",
          "duration": "5 days after meal",
        },
        {
          "name": "3. Amoxicillin",
          "dosage": "0+1+1",
          "duration": "5 days before meal",
        },
      ],
      "advice": "Take rest and drink plenty of water. Avoid cold food.",
      "tests": "CBC, Urine R/E",
    },
    {
      "date": "2025-08-20",
      "doctor": "Mr. Muhammad Jahidur Rahman",
      "roll": "2022331050",
      "name": "Sarah Islam",
      "age": "21",
      "gender": "Female",
      "complaints": "Cough, cold and sore throat",
      "examination": "Temp: 98.6F, Throat: Inflamed, Chest: Clear",
      "medicines": [
        {
          "name": "1. Antihistamine",
          "dosage": "1+1+1",
          "duration": "5 days before meal",
        },
        {
          "name": "2. Cough Syrup",
          "dosage": "1+0+1",
          "duration": "7 days after meal",
        },
      ],
      "advice": "Gargle with warm salt water. Avoid cold drinks.",
      "tests": "None",
    },
    {
      "date": "2025-08-05",
      "doctor": "Dr. Salma Akter",
      "roll": "2022331080",
      "name": "Rahim Khan",
      "age": "23",
      "gender": "Male",
      "complaints": "Stomach pain and indigestion",
      "examination": "Abdomen: Soft, tender in epigastric region",
      "medicines": [
        {
          "name": "1. Antacid",
          "dosage": "1+0+1",
          "duration": "3 days before meal",
        },
        {
          "name": "2. Domperidone",
          "dosage": "1+1+1",
          "duration": "5 days after meals",
        },
      ],
      "advice": "Avoid spicy food. Eat small frequent meals.",
      "tests": "Stool R/E, LFT",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _logoBytes = null;
    _bengaliFont = null;
    _openSansFont = null; // <-- ensure disposed
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadResources() async {
    try {
      await Future.wait([_loadFont(), _loadLogo()]);
      _safeSetState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        print('Error loading resources: $e');
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/images/nstu_logo.jpg');
      _logoBytes = bytes.buffer.asUint8List();
    } catch (e) {
      if (!_isDisposed) print('Logo loading failed: $e');
    }
  }

  Future<void> _loadFont() async {
    try {
      // Try to load OpenSans first (for Latin text)
      try {
        final openSansData = await rootBundle.load(
          'assets/fonts/OpenSans-VariableFont.ttf',
        );
        _openSansFont = pw.Font.ttf(openSansData);
        if (!_isDisposed) print('OpenSans font loaded successfully.');
      } catch (e) {
        if (!_isDisposed) print('OpenSans not found or failed to load: $e');
      }

      // Try to load Bengali font (Kalpurush) as before
      try {
        final fontData = await rootBundle.load('assets/fonts/Kalpurush.ttf');
        _bengaliFont = pw.Font.ttf(fontData);
        if (!_isDisposed)
          print('Bengali font (Kalpurush) loaded successfully.');
      } catch (e) {
        if (!_isDisposed) print('Kalpurush font loading failed: $e');
      }
    } catch (e) {
      if (!_isDisposed) print('Font loading failed: $e');
    }
  }

  Future<Uint8List> _generatePrescriptionPDF(
    Map<String, dynamic> prescription,

  ) async {
    await BanglaFontManager().initialize();
    return await Future.microtask(() async {
      final pdf = pw.Document();
      final hasBengaliFont = _bengaliFont != null;
      // final defaultFont = pw.Font.helvetica();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final baseTextStyle = pw.TextStyle(
              fontSize: 10,
              // Prefer OpenSans for general text, fallback to Bengali font, then helvetica
              font: _openSansFont ?? _bengaliFont ?? pw.Font.helvetica(),
              fontFallback: [_bengaliFont ?? pw.Font.helvetica()],
            );

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (_logoBytes != null)
                        pw.Container(
                          height: 90,
                          width: 90,
                          child: pw.Center(
                            child: pw.Image(
                              pw.MemoryImage(_logoBytes!),
                              width: 90,
                              height: 90,
                            ),
                          ),
                        )
                      else
                        pw.Container(
                          height: 40,
                          width: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 1,
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              "LOGO",
                              style: baseTextStyle.copyWith(fontSize: 8),
                            ),
                          ),
                        ),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (hasBengaliFont) ...[
                            pw.Text(
                              "মেডিকেল সেন্টার",
                              style: pw.TextStyle(
                                fontSize: 14,
                                font: _bengaliFont!,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              "নোয়াখালী বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয়",
                              style: pw.TextStyle(
                                fontSize: 14,
                                font: _bengaliFont!,
                                lineSpacing: 1.5,
                              ),
                            ),
                          ],
                          pw.Text(
                            "Noakhali Science and Technology University",
                            style: baseTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              lineSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                // Patient Info
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Patient Name:',
                            style: baseTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  prescription['name'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            'Date:',
                            style: baseTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  prescription['date'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Roll:',
                            style: baseTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  prescription['roll'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            'Age:',
                            style: baseTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  prescription['age'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            'Gender:',
                            style: baseTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  prescription['gender'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                // Main Content
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "C/C:",
                              style: baseTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.white,
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  prescription['complaints'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              "O/E:",
                              style: baseTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.white,
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  prescription['examination'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              "Adv:",
                              style: baseTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.white,
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  prescription['advice'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              "Inv:",
                              style: baseTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.white,
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  prescription['tests'],
                                  style: baseTextStyle.copyWith(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical Divider before Rx section
                      pw.VerticalDivider(
                        thickness: 1, // Set the thickness of the line
                        color: PdfColors.black, // Set the color
                        indent: 0, // Space before the divider
                        endIndent: 0, // Space after the divider
                      ),

                      // Right Column (Rx)
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Rx:",
                              style: baseTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            // Table Rows
                            ...prescription['medicines'].map<pw.Widget>((
                              medicine,
                            ) {
                              return _buildMedicineRow(medicine, baseTextStyle);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                // Footer/Signature
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 130,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Doctor's Signature",
                        style: baseTextStyle.copyWith(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(prescription['doctor'], style: baseTextStyle),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      return pdf.save();
    });
  }

  pw.Container _buildMedicineRow(
    Map<String, dynamic> medicine,
    pw.TextStyle baseStyle,
  ) {
    return pw.Container(
      child: pw.Row(
        children: [
          _buildMedicineCell(medicine['name'], 5, baseStyle),
          _buildMedicineCell(
            medicine['dosage'],
            2,
            baseStyle,
            hasRightBorder: false,
          ),
          _buildMedicineCell(
            medicine['duration'],
            2,
            baseStyle,
            hasRightBorder: false,
          ),
        ],
      ),
    );
  }

  pw.Expanded _buildMedicineCell(
    String text,
    int flex,
    pw.TextStyle baseStyle, {
    bool hasRightBorder = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: hasRightBorder
                ? pw.BorderSide(color: PdfColors.black, width: 1)
                : pw.BorderSide.none,
          ),
          color: PdfColors.white,
        ),
        constraints: const pw.BoxConstraints(minHeight: 30),
        child: pw.Text(text, style: baseStyle.copyWith(fontSize: 11)),
      ),
    );
  }

  Future<void> _downloadPrescriptionPDF(
    Map<String, dynamic> prescription,
  ) async {
    if (_isDisposed || !mounted) return;

    _safeSetState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    if (_isDisposed || !mounted) {
      _safeSetState(() => _isLoading = false);
      return;
    }

    try {
      final pdfBytes = await _generatePrescriptionPDF(prescription);

      if (!mounted || _isDisposed) return;

      final fileName =
          "Prescription_${prescription['roll']}_${prescription['date']}.pdf";

      if (kIsWeb) {
        // Web platform
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("PDF downloaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mobile/Desktop platform
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("PDF saved at: ${file.path}"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving PDF: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Prescriptions"),
        centerTitle: true,
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
      ),
      body: _isLoading && prescriptions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading resources...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final item = prescriptions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(128, 128, 128, 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Date: ${item["date"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            item["doctor"] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Patient: ${item["name"]} (Roll: ${item["roll"]})",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Complaints: ${item["complaints"]}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Medicines: ${(item["medicines"] as List).map((m) => m["name"]).join(", ")}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _downloadPrescriptionPDF(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          label: Text(
                            _isLoading ? "Generating..." : "Download PDF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
