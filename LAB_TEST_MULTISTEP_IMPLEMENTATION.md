# Lab Test Booking System - Multi-Step Implementation

## Overview

Implemented a complete multi-step lab test booking system with 4 distinct steps for patient data collection, test selection, and doctor assignment. Removed appointment scheduling as requested.

## Features Implemented

### Step 1: Patient Type Selection

- **Options**: Student, Employee/Family, Out Patient
- **Student-Specific**:
  - Shows report delivery method selection
  - Choose between Email or Patient ID delivery
- **Pricing**: Automatic differentiation based on patient type

### Step 2: Test Selection

- **Total Tests**: All 25 available lab tests
- **Search Functionality**: Real-time test search by name and description
- **Categories**: 6 categories
  - All
  - Hematology (CBC, Hb%, Blood Grouping)
  - Biochemistry (Glucose, Bilirubin, SGPT, SGOT, Creatinine, Calcium)
  - Serology (HBsAg, Dengue, Widal, Syphilis, Febrile, Malaria)
  - Immunology (CRP, RA, ASO)
  - Special Tests (Pregnancy, Urine, Dope)
- **Visual Feedback**: Selected tests highlighted with checkmark
- **Dynamic Pricing**: Total calculated based on selected patient type

### Step 3: Patient Information

- Patient Full Name
- Email Address
- Phone Number
- Age
- Gender (Male/Female/Other)

### Step 4: Doctor Information

- Doctor Name
- Doctor Email
- **Booking Summary Display**:
  - Patient name, type, and number of tests
  - Total fee calculation
  - Report delivery method

## Technical Details

### Architecture

- **Stateful Widget**: Full state management with `setState`
- **Multi-Step Navigation**: Progress indicator showing 4 steps
- **Validation**: Each step validates before proceeding

### Data Flow

1. Select patient type → Unlock report delivery method option
2. Select tests → Calculate fee based on type
3. Enter patient info → Validate all fields
4. Enter doctor info → Confirm and complete

### 25 Lab Tests with 3-Tier Pricing

- **Student Rates** (STU prefix)
- **Employee Rates** (EMP prefix)
- **Out-Patient Rates** (OUT prefix)

Example pricing:

```
- Hb%: ৳60 (Student) / ৳80 (Employee) / ৳100 (Out-Patient)
- CBC: ৳200 (Student) / ৳250 (Employee) / ৳300 (Out-Patient)
- Lipid Profile: ৳450 (Student) / ৳550 (Employee) / ৳600 (Out-Patient)
```

### Theme Support

- Dark mode and light mode toggle
- Theme preference saved to SharedPreferences
- Colors:
  - Primary Teal: #26A69A
  - Dark Background: #1A1F2E
  - Card Background: #252B3D

### Report Delivery (Student-Only Feature)

When student is selected, shows option to choose:

- **Email**: Report sent to patient email
- **Patient ID**: Report accessible via patient portal

## UI/UX Features

- **Progress Indicator**: Visual step tracker at top
- **Responsive Layout**: Works on all screen sizes
- **Form Validation**: Prevents advancing without required data
- **Summary Display**: Final review before confirmation
- **Success Feedback**: Toast notification upon booking

## File Structure

```
lib/src/lab_test/
├── lab_test_booking.dart (UPDATED - Multi-step form, 785 lines)
├── lab_test_list.dart (Contains 25 tests with pricing)
├── lab_booking_entry.dart (Entry point for booking)
├── lab_test_panel.dart (Technician dashboard)
└── lab_test_results.dart (Result upload interface)
```

## Next Steps for Backend Integration

1. **API Endpoints**:

   - POST /api/lab/booking/create
   - GET /api/lab/booking/{bookingId}
   - POST /api/lab/result/upload
   - POST /api/notification/email

2. **Email Service**:

   - Send confirmation to patient
   - Send confirmation to doctor
   - Send results upon completion

3. **Database**:
   - LabBooking table with patient, tests, and totals
   - LabTestResult table with status tracking

## Testing Checklist

- [ ] All patient types selectable
- [ ] Search functionality working
- [ ] Category filtering working
- [ ] Price calculation correct for each type
- [ ] Form validation preventing empty submissions
- [ ] Dark/light mode toggle working
- [ ] Report delivery method showing only for students
- [ ] Booking confirmation showing all details
- [ ] Theme preference persisting after app restart
