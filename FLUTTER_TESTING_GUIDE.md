# Flutter App Testing Guide

## 🚀 **Current Status**
- ✅ **Flutter App**: Running on http://localhost:8080
- ✅ **Backend API**: Running on http://localhost:8000
- ✅ **Database**: MySQL running on Docker
- ✅ **Admin Dashboard**: Running on http://localhost:8501

## 🧪 **Testing Checklist**

### **1. Profile Features Testing**

#### **A. Gender Field Integration**
- [ ] **Navigate to Profile Screen**
  - Open the app and go to Profile tab
  - Verify gender is displayed under user type
  - Check if gender shows correctly for existing users

- [ ] **Edit Profile with Gender**
  - Tap "Edit Profile" button
  - Verify gender dropdown is present with options: Male, Female, Other
  - Select a gender and save
  - Verify gender is updated in profile display

#### **B. Profile Completion Widget**
- [ ] **Profile Completion Display**
  - Check if profile completion percentage is shown
  - Verify progress bar color changes based on completion:
    - Red: < 60%
    - Orange: 60-80%
    - Green: > 80%

- [ ] **Missing Fields Identification**
  - Verify missing fields are listed
  - Check if "Complete Profile" button appears when fields are missing
  - Test navigation to edit profile when button is tapped

#### **C. Profile Picture Upload**
- [ ] **Upload Profile Picture**
  - Tap profile picture in edit profile
  - Test camera option
  - Test gallery option
  - Verify upload progress indicator
  - Check if picture appears after upload

#### **D. Medical Records Upload**
- [ ] **Upload Medical Records** (for non-patient users)
  - Navigate to edit profile
  - Test "Upload Medical Records" button
  - Select file from device
  - Choose record type and description
  - Verify upload progress and success message

### **2. Messages Features Testing**

#### **A. Enhanced Messages Screen**
- [ ] **Messages List Display**
  - Navigate to Messages tab
  - Verify conversation list loads
  - Check if mock data is displayed correctly

- [ ] **Search Functionality**
  - Use search bar to filter conversations
  - Test real-time search filtering
  - Verify clear button works

- [ ] **Filter System**
  - Test filter chips: All, Unread, Medical, Support
  - Verify conversations are filtered correctly
  - Check if filter state persists

- [ ] **Quick Actions**
  - Test "Medical Team" quick action card
  - Test "Support" quick action card
  - Verify filter is applied when cards are tapped

#### **B. Message Management**
- [ ] **Conversation Actions**
  - Long press on conversation to open menu
  - Test "Mark as Read" option
  - Test "Archive" option
  - Test "Delete" option

- [ ] **New Message Flow**
  - Tap floating action button
  - Test "Contact Medical Team" option
  - Test "Contact Support" option

### **3. Authentication Testing**

#### **A. Login Flow**
- [ ] **User Login**
  - Use test credentials:
    - Email: `patient1@example.com`
    - Password: `password123`
  - Verify successful login
  - Check if user data loads correctly

- [ ] **Different User Types**
  - Test login with different user types:
    - Patient: `patient1@example.com`
    - Hospital: `hospital1@example.com`
    - Donor: `donor1@example.com`

#### **B. Profile Data Loading**
- [ ] **User Data Display**
  - Verify all user fields display correctly
  - Check if gender field shows
  - Verify profile completion calculation

### **4. Navigation Testing**

#### **A. Bottom Navigation**
- [ ] **Tab Navigation**
  - Test Home tab
  - Test Appointments tab
  - Test Hospitals tab
  - Test Messages tab
  - Test Profile tab

#### **B. Screen Navigation**
- [ ] **Profile Screens**
  - Test navigation to Edit Profile
  - Test navigation to Security settings
  - Test navigation to Notifications settings
  - Test navigation to Payments screen

### **5. UI/UX Testing**

#### **A. Visual Consistency**
- [ ] **Theme Consistency**
  - Verify consistent colors throughout app
  - Check if UI constants are applied correctly
  - Test light/dark theme if available

#### **B. Responsive Design**
- [ ] **Screen Adaptability**
  - Test on different screen sizes
  - Verify layout adapts correctly
  - Check if text is readable

#### **C. Loading States**
- [ ] **Loading Indicators**
  - Verify loading overlays appear during API calls
  - Check if progress indicators work
  - Test error states and retry functionality

### **6. Error Handling Testing**

#### **A. Network Errors**
- [ ] **Offline Handling**
  - Disconnect internet and test app behavior
  - Verify appropriate error messages
  - Test retry functionality

#### **B. API Errors**
- [ ] **Server Errors**
  - Test with invalid credentials
  - Verify error messages are user-friendly
  - Check if app doesn't crash on errors

### **7. Performance Testing**

#### **A. App Performance**
- [ ] **Loading Speed**
  - Test app startup time
  - Verify screen transitions are smooth
  - Check if images load efficiently

#### **B. Memory Usage**
- [ ] **Memory Management**
  - Test app over extended use
  - Verify no memory leaks
  - Check if app remains responsive

## 🔧 **Test Data**

### **Available Test Users**
```
Patient Users:
- Email: patient1@example.com, Password: password123
- Email: patient2@example.com, Password: password123

Hospital Users:
- Email: hospital1@example.com, Password: password123
- Email: hospital2@example.com, Password: password123

Donor Users:
- Email: donor1@example.com, Password: password123
- Email: donor2@example.com, Password: password123

Admin User:
- Email: admin@example.com, Password: password123
```

### **Test Files for Upload**
- Create test images (JPG, PNG) for profile pictures
- Create test documents (PDF, DOC) for medical records

## 📱 **Testing Platforms**

### **Web Testing (Current)**
- **URL**: http://localhost:8080
- **Browser**: Chrome/Edge
- **Features**: All features available

### **Mobile Testing (Optional)**
- **Android Device**: V2109 (connected)
- **Command**: `flutter run -d 34580871350039F`

### **Desktop Testing (Optional)**
- **Windows**: Available
- **Command**: `flutter run -d windows`

## 🐛 **Known Issues to Monitor**

### **Current Warnings (Non-Critical)**
- [ ] Deprecated `withOpacity` usage (cosmetic)
- [ ] Unused imports (cleanup needed)
- [ ] BuildContext async gaps (minor)

### **Critical Issues Fixed**
- ✅ Gender field integration
- ✅ Profile completion widget
- ✅ Enhanced messages screen
- ✅ API service configuration
- ✅ Medical record model compatibility

## 📊 **Testing Results Template**

```
Test Date: _______________
Tester: _________________

### Profile Features
- [ ] Gender field display: PASS/FAIL
- [ ] Gender field editing: PASS/FAIL
- [ ] Profile completion widget: PASS/FAIL
- [ ] Profile picture upload: PASS/FAIL
- [ ] Medical records upload: PASS/FAIL

### Messages Features
- [ ] Messages list display: PASS/FAIL
- [ ] Search functionality: PASS/FAIL
- [ ] Filter system: PASS/FAIL
- [ ] Quick actions: PASS/FAIL
- [ ] Conversation actions: PASS/FAIL

### Authentication
- [ ] Login flow: PASS/FAIL
- [ ] User data loading: PASS/FAIL
- [ ] Profile data display: PASS/FAIL

### UI/UX
- [ ] Visual consistency: PASS/FAIL
- [ ] Responsive design: PASS/FAIL
- [ ] Loading states: PASS/FAIL

### Error Handling
- [ ] Network errors: PASS/FAIL
- [ ] API errors: PASS/FAIL

### Performance
- [ ] App startup: PASS/FAIL
- [ ] Screen transitions: PASS/FAIL
- [ ] Memory usage: PASS/FAIL

### Issues Found:
1. _________________
2. _________________
3. _________________

### Recommendations:
1. _________________
2. _________________
3. _________________
```

## 🎯 **Next Steps After Testing**

1. **Document Issues**: Record any bugs or UX problems found
2. **Prioritize Fixes**: Categorize issues by severity
3. **Implement Improvements**: Address critical issues first
4. **User Feedback**: Gather feedback on new features
5. **Performance Optimization**: Address any performance issues
6. **Code Cleanup**: Remove unused imports and fix warnings

## 🚀 **Ready to Test!**

The Flutter app is now running with all the enhanced profile and message features. Use this guide to systematically test each feature and ensure everything works as expected.

**Access the app at**: http://localhost:8080
