// Lab test master list with pricing for different patient types
class LabTest {
  final String testId;
  final String testName;
  final String description;
  final double feeStudent;
  final double feeEmployee;
  final double feeOutPatient;
  final bool available;

  LabTest({
    required this.testId,
    required this.testName,
    required this.description,
    required this.feeStudent,
    required this.feeEmployee,
    required this.feeOutPatient,
    required this.available,
  });

  double getFee(String patientType) {
    switch (patientType) {
      case 'student':
        return feeStudent;
      case 'employee':
        return feeEmployee;
      case 'out_patient':
        return feeOutPatient;
      default:
        return feeStudent;
    }
  }
}

List<LabTest> labTests = [
  LabTest(
    testId: "01",
    testName: "Hb%",
    description: "Hemoglobin test",
    feeStudent: 60.0,
    feeEmployee: 80.0,
    feeOutPatient: 100.0,
    available: true,
  ),
  LabTest(
    testId: "02",
    testName: "CBC",
    description: "Complete Blood Count",
    feeStudent: 200.0,
    feeEmployee: 230.0,
    feeOutPatient: 280.0,
    available: true,
  ),
  LabTest(
    testId: "03",
    testName: "Lipid Profile",
    description: "CHO, TG, HDL, LDL",
    feeStudent: 450.0,
    feeEmployee: 500.0,
    feeOutPatient: 600.0,
    available: true,
  ),
  LabTest(
    testId: "04",
    testName: "Serum Bilirubin Total",
    description: "Serum Bilirubin Total",
    feeStudent: 120.0,
    feeEmployee: 150.0,
    feeOutPatient: 200.0,
    available: true,
  ),
  LabTest(
    testId: "05",
    testName: "SGPT",
    description: "SGPT",
    feeStudent: 130.0,
    feeEmployee: 150.0,
    feeOutPatient: 220.0,
    available: true,
  ),
  LabTest(
    testId: "06",
    testName: "SGOT",
    description: "SGOT",
    feeStudent: 130.0,
    feeEmployee: 150.0,
    feeOutPatient: 220.0,
    available: true,
  ),
  LabTest(
    testId: "07",
    testName: "Serum Creatinine",
    description: "Serum Creatinine",
    feeStudent: 100.0,
    feeEmployee: 120.0,
    feeOutPatient: 200.0,
    available: true,
  ),
  LabTest(
    testId: "08",
    testName: "Glucose (Single Sample)",
    description: "Glucose (Single Sample)",
    feeStudent: 60.0,
    feeEmployee: 80.0,
    feeOutPatient: 100.0,
    available: true,
  ),
  LabTest(
    testId: "09",
    testName: "Serum Uric Acid",
    description: "Serum Uric Acid",
    feeStudent: 120.0,
    feeEmployee: 150.0,
    feeOutPatient: 220.0,
    available: true,
  ),
  LabTest(
    testId: "10",
    testName: "Serum Calcium",
    description: "Serum Calcium",
    feeStudent: 150.0,
    feeEmployee: 200.0,
    feeOutPatient: 250.0,
    available: true,
  ),
  LabTest(
    testId: "11",
    testName: "HbA1C",
    description: "HbA1C",
    feeStudent: 300.0,
    feeEmployee: 350.0,
    feeOutPatient: 500.0,
    available: true,
  ),
  LabTest(
    testId: "12",
    testName: "Blood Grouping & Rh Factor",
    description: "Blood Grouping & Rh Factor",
    feeStudent: 100.0,
    feeEmployee: 120.0,
    feeOutPatient: 150.0,
    available: true,
  ),
  LabTest(
    testId: "13",
    testName: "CRP (Titre)",
    description: "CRP (Titre)",
    feeStudent: 150.0,
    feeEmployee: 180.0,
    feeOutPatient: 250.0,
    available: true,
  ),
  LabTest(
    testId: "14",
    testName: "RA",
    description: "RA",
    feeStudent: 150.0,
    feeEmployee: 180.0,
    feeOutPatient: 250.0,
    available: true,
  ),
  LabTest(
    testId: "15",
    testName: "ASO",
    description: "ASO",
    feeStudent: 180.0,
    feeEmployee: 220.0,
    feeOutPatient: 300.0,
    available: true,
  ),
  LabTest(
    testId: "16",
    testName: "Widal",
    description: "Widal",
    feeStudent: 150.0,
    feeEmployee: 200.0,
    feeOutPatient: 250.0,
    available: true,
  ),
  LabTest(
    testId: "17",
    testName: "Febrile Antigen",
    description: "Febrile Antigen",
    feeStudent: 300.0,
    feeEmployee: 400.0,
    feeOutPatient: 500.0,
    available: true,
  ),
  LabTest(
    testId: "18",
    testName: "HBsAg (ICT)",
    description: "HBsAg (ICT)",
    feeStudent: 120.0,
    feeEmployee: 150.0,
    feeOutPatient: 200.0,
    available: true,
  ),
  LabTest(
    testId: "19",
    testName: "Syphilis/TPHA (ICT)",
    description: "Syphilis/TPHA (ICT)",
    feeStudent: 100.0,
    feeEmployee: 120.0,
    feeOutPatient: 160.0,
    available: true,
  ),
  LabTest(
    testId: "20",
    testName: "Dengue Ns1",
    description: "Dengue Ns1",
    feeStudent: 200.0,
    feeEmployee: 220.0,
    feeOutPatient: 250.0,
    available: true,
  ),
  LabTest(
    testId: "21",
    testName: "Dengue IgG/IgM",
    description: "Dengue IgG/IgM",
    feeStudent: 250.0,
    feeEmployee: 250.0,
    feeOutPatient: 350.0,
    available: true,
  ),
  LabTest(
    testId: "22",
    testName: "Malaria Parasite",
    description: "Malaria Parasite",
    feeStudent: 150.0,
    feeEmployee: 200.0,
    feeOutPatient: 250.0,
    available: true,
  ),
  LabTest(
    testId: "23",
    testName: "Pregnancy Test (ICT)",
    description: "Pregnancy Test (ICT)",
    feeStudent: 80.0,
    feeEmployee: 100.0,
    feeOutPatient: 120.0,
    available: true,
  ),
  LabTest(
    testId: "24",
    testName: "Urine R/M/E",
    description: "Urine R/M/E",
    feeStudent: 60.0,
    feeEmployee: 80.0,
    feeOutPatient: 100.0,
    available: true,
  ),
  LabTest(
    testId: "25",
    testName: "Dope Test (5 Parameters)",
    description: "Dope Test (5 Parameters)",
    feeStudent: 600.0,
    feeEmployee: 700.0,
    feeOutPatient: 700.0,
    available: true,
  ),
];
