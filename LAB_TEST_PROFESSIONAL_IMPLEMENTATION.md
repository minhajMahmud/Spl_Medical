# Lab Test Booking System - Professional Edition

## Overview

The Lab Test Booking System has been upgraded to a comprehensive, professional workflow that provides detailed information capture and a user-friendly step-by-step process for booking lab tests.

## Architecture

### Main Components

1. **Lab Tester Home** (`lab_tester_home.dart`)

   - Dashboard with overview statistics
   - Quick access to Tests panel and Profile
   - Real-time notifications

2. **Lab Test Panel** (`lab_test_panel.dart`)

   - Booking management dashboard
   - Search and filter capabilities
   - Sample collection status tracking
   - Result entry interface

3. **Patient Booking Entry** (`lab_booking_entry.dart`)

   - Patient identification screen
   - Supports registered patients and walk-ins
   - Patient type selection (Student, Employee, Out Patient)

4. **Professional Booking System** (`lab_test_booking_professional.dart`)
   - 5-step comprehensive booking workflow
   - Advanced features and validation

## Professional Booking Workflow

### Step 1: Patient Information

- **Captures:**
  - Full name (required)
  - Age and gender (required)
  - Phone number (required)
  - Email (optional)
  - Address (optional)
- **Features:**
  - Pre-filled patient ID display
  - Patient type badge
  - Comprehensive form validation

### Step 2: Test Selection

- **Features:**
  - Search by test name or code
  - Category filtering:
    - Hematology
    - Biochemistry
    - Serology
    - Immunology
    - Microbiology
    - Special Tests
  - Visual test cards with:
    - Test name and code
    - Description
    - Pricing (based on patient type)
    - Turnaround time (TAT)
  - Real-time cost calculation
  - Automatic discount application
  - Summary card showing total tests and amount

### Step 3: Doctor & Clinical Information

- **Captures:**
  - Referring doctor name (required)
  - Doctor phone and email (optional)
  - Urgency level (Normal, Urgent, Emergency)
  - Fasting status toggle
  - Clinical notes/symptoms (optional)
- **Features:**
  - Color-coded urgency levels
  - Important fasting indicator for applicable tests

### Step 4: Sample Collection Details

- **Collection Methods:**
  - In-Lab: Patient visits lab
  - Home Collection: Lab technician visits patient (+৳200 fee)
- **Scheduling:**
  - Preferred collection date picker
  - Preferred time selection
  - Collection address (for home service)
  - Special instructions
- **Features:**
  - Calendar date picker
  - Time picker with AM/PM
  - Conditional address field for home collection

### Step 5: Payment & Confirmation

- **Order Summary:**
  - Patient details review
  - Complete test list with individual prices
  - Cost breakdown:
    - Subtotal
    - Discounts (if applicable)
    - Home collection fee (if applicable)
    - Grand total
- **Payment Methods:**
  - Cash
  - bKash
  - Card
  - Nagad
- **Report Delivery:**
  - Email
  - SMS
  - Print
  - All methods
- **Terms & Conditions:**
  - Required agreement checkbox
  - Privacy policy acknowledgment

## Pricing & Discounts

### Patient Types & Base Pricing

- **Student**: Special discounted rates
- **Employee**: Special discounted rates
- **Out Patient**: Standard rates

### Automatic Discounts

- **Students**: 10% discount for 3 or more tests
- **Employees**: 15% discount for 5 or more tests
- **Additional Fees**: ৳200 for home sample collection

## UI/UX Features

### Visual Design

- **Dark/Light Mode Support**
  - Persistent theme preference
  - Smooth theme transitions
  - Optimized colors for both modes

### Progress Indicator

- 5-step visual progress bar
- Completed steps marked with checkmark
- Current step highlighted
- Step names displayed

### Navigation

- **Back Button**: Returns to previous step
- **Next Button**: Advances to next step with validation
- **Confirm Button**: Final step with confirmation dialog
- Form validation on each step

### Responsive Design

- Scrollable content
- Adaptive layouts
- Mobile-friendly interface
- Card-based design system

## Validation Rules

### Patient Information (Step 1)

- Name, phone, and age are required
- Email must be valid format if provided
- All fields properly formatted

### Test Selection (Step 2)

- At least one test must be selected
- Cannot proceed without selection

### Doctor Information (Step 3)

- Doctor name is required
- Contact information optional
- Urgency level preselected

### Sample Collection (Step 4)

- Home collection requires address
- Date and time validation
- Future dates only

### Payment & Confirmation (Step 5)

- Terms and conditions must be agreed
- All information reviewed
- Confirmation dialog before submission

## Data Flow

```
Lab Test Panel → Patient Booking Entry → Professional Booking System
                                               ↓
                                         Step 1: Patient Info
                                               ↓
                                         Step 2: Test Selection
                                               ↓
                                         Step 3: Doctor Info
                                               ↓
                                         Step 4: Collection
                                               ↓
                                         Step 5: Payment
                                               ↓
                                       Confirmation & Submit
```

## Patient ID Formats

### Registered Patients

- **Students**: `STU` prefix (e.g., STU2024001)
- **Employees**: `EMP` prefix (e.g., EMP456)
- **Out Patients**: `OUT` prefix (e.g., OUT789)

### Walk-in Patients

- Format: `WALKIN:{identifier}`
- Identifier can be name, phone, or email
- Examples:
  - `WALKIN:John Doe`
  - `WALKIN:017xxxxxxxx`
  - `WALKIN:student@nstu.edu.bd`

## Key Improvements Over Previous System

### 1. Enhanced User Experience

- Step-by-step workflow reduces cognitive load
- Clear progress indication
- Validation at each step prevents errors
- Confirmation dialog before final submission

### 2. Comprehensive Information Capture

- Detailed patient information
- Clinical notes and symptoms
- Doctor information for better coordination
- Flexible scheduling options

### 3. Professional Features

- Multiple payment methods
- Home collection service
- Urgency level tracking
- Fasting status indicator
- Report delivery preferences

### 4. Better Cost Transparency

- Real-time cost calculation
- Clear discount display
- Itemized pricing
- Additional fees clearly shown

### 5. Improved Search & Discovery

- Category-based browsing
- Search functionality
- Detailed test information
- Visual test selection

## Technical Implementation

### State Management

- Local state with `setState`
- Form validation with `GlobalKey<FormState>`
- Persistent theme preferences with `SharedPreferences`

### UI Components

- Material Design components
- Custom card layouts
- FilterChip for categories
- ChoiceChip for urgency levels
- RadioListTile for selections
- SwitchListTile for toggles

### Data Models

- Uses `LabTest` model from `lab_test_list.dart`
- Patient type-based pricing
- Discount calculation logic
- Order summary aggregation

## Future Enhancements

1. **Backend Integration**

   - Save bookings to database
   - Fetch patient information from API
   - Real-time availability checking

2. **Payment Gateway**

   - Integrate bKash, Nagad APIs
   - Card payment processing
   - Payment receipt generation

3. **Notifications**

   - SMS/Email confirmations
   - Reminder notifications
   - Status update alerts

4. **Reports & Analytics**

   - Booking statistics
   - Revenue reports
   - Popular tests analysis

5. **Additional Features**
   - Appointment rescheduling
   - Booking cancellation
   - Patient history view
   - Test result viewing

## Usage Instructions

### For Lab Staff

1. **Starting a New Booking:**

   - Navigate to Tests tab
   - Click "Select Patient/Type" button
   - Choose registered patient or walk-in option

2. **For Registered Patients:**

   - Enter patient ID (STU/EMP/OUT prefix)
   - Click "Search and Start Booking"
   - System will proceed to professional booking

3. **For Walk-in Patients:**

   - Select patient type (Student/Employee/Out Patient)
   - Enter identifier (name, phone, or email)
   - Click "Start Booking"
   - Complete all steps in booking workflow

4. **Completing Booking:**
   - Fill all required information in each step
   - Review order summary carefully
   - Select payment and delivery methods
   - Agree to terms
   - Confirm booking

### Tips for Efficient Booking

- Use search to quickly find tests
- Use category filters for test groups
- Check turnaround time (TAT) before booking
- Note fasting requirements for applicable tests
- Select urgency level appropriately
- Provide complete address for home collection
- Verify phone/email for report delivery

## Troubleshooting

### Common Issues

1. **Cannot proceed to next step**

   - Check all required fields are filled
   - Verify email format if provided
   - Ensure at least one test is selected

2. **Wrong pricing displayed**

   - Verify patient type is correct
   - Check if discounts are applicable
   - Confirm number of tests selected

3. **Home collection not available**
   - Verify collection address is provided
   - Check service area availability
   - Confirm date/time selection

## Maintenance Notes

### File Structure

```
lib/src/lab_test/
├── lab_tester_home.dart              # Main dashboard
├── lab_test_panel.dart               # Booking management panel
├── lab_booking_entry.dart            # Patient identification
├── lab_test_booking_professional.dart # Professional booking workflow
├── lab_test_booking.dart             # Legacy booking (deprecated)
├── lab_test_list.dart                # Test definitions and pricing
├── lab_test_results.dart             # Results viewing
└── lab_staff_profile.dart            # Staff profile management
```

### Key Dependencies

- `flutter/material.dart` - UI framework
- `shared_preferences` - Theme persistence
- `intl` - Date/time formatting
- `file_picker` - File selection (results)

### Code Quality

- Follow Dart style guidelines
- Maintain consistent naming conventions
- Add comments for complex logic
- Keep functions focused and concise
- Use proper error handling

---

**Last Updated:** December 29, 2025
**Version:** 2.0.0
**Maintained by:** Development Team
