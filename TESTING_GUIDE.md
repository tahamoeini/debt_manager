# Phase 6 Testing Guide

This guide outlines the new features implemented in Phase 6 and how to test them.

## 1. Font Size Settings

**Location:** Settings > Appearance & Display > Font Size

**How to Test:**
1. Open Settings
2. Navigate to "Appearance & Display" section
3. Try each font size option:
   - Small (0.85x scale)
   - Default (1.0x scale)
   - Large (1.15x scale)
4. Verify that all text throughout the app scales appropriately
5. Check that UI elements don't overlap or break with larger text

**Expected Behavior:**
- Font size changes should apply immediately without restarting
- All screens should remain readable and properly laid out
- Buttons and interactive elements should maintain proper spacing

## 2. Language and Calendar Settings

**Location:** Settings > Language & Calendar

**How to Test:**
1. Open Settings
2. Find "Language & Calendar" section
3. Test language toggle:
   - Switch between English and Persian
   - Verify setting is saved
4. Test calendar type:
   - Switch between Jalali (Persian) and Gregorian
   - Verify setting is saved

**Expected Behavior:**
- Settings persist after app restart
- Future date displays should respect calendar preference
- No crashes or errors when switching

## 3. Notification Settings

**Location:** Settings > Notifications

**How to Test:**
1. Open Settings
2. Navigate to Notifications section
3. Test master toggle:
   - Disable "Enable All Notifications"
   - Verify loading message appears
   - Verify confirmation that notifications were canceled
4. Test individual toggles:
   - Toggle Bill Reminders
   - Toggle Budget Alerts
   - Verify they're disabled when master toggle is off

**Expected Behavior:**
- Master toggle disables all notification scheduling
- Individual toggles work when master is enabled
- Settings persist after app restart
- No notifications scheduled when disabled

## 4. Category Management

**Location:** Settings > Category Management

**How to Test:**
1. Open Settings
2. Tap "Manage Categories" button
3. Test adding a category:
   - Tap FAB (+ button)
   - Enter a category name (e.g., "Education")
   - Verify it appears in the list
4. Test renaming a custom category:
   - Tap edit icon on a custom category
   - Change the name
   - Verify the change is saved
5. Test deleting a category:
   - Create a budget using a custom category
   - Try to delete that category
   - Verify warning message appears
   - Confirm deletion
   - Check that budgets still work (just show deleted category name)
6. Try to rename/delete a default category:
   - Verify you cannot rename default categories (food, utilities, etc.)
   - Verify you cannot delete default categories

**Expected Behavior:**
- Custom categories can be added, renamed, and deleted
- Default categories are protected from modification
- Warning shows when deleting categories used by budgets
- Categories persist after app restart

## 5. Celebration Animation

**Location:** Loan Detail Screen

**How to Test:**
1. Navigate to a loan with multiple installments
2. Mark all installments as paid except one
3. Mark the last installment as paid
4. Observe the celebration animation

**Expected Behavior:**
- Confetti animation appears after marking final installment as paid
- Dialog shows "🎉 Congratulations! 🎉" message
- Animation auto-dismisses after 3 seconds
- Can manually close with "Great!" button

## 6. Accessibility Features

**How to Test:**
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate through the app using screen reader
3. Verify all buttons have labels:
   - FAB buttons announce their purpose
   - Navigation items are properly labeled
   - Settings options are clearly described
4. Test with large font size (system settings)
5. Verify all buttons are at least 48dp touch target
6. Test with high contrast mode enabled

**Expected Behavior:**
- All interactive elements should be announced by screen reader
- Buttons should have descriptive labels
- Touch targets should be easy to hit
- Layout shouldn't break with large system fonts

## 7. Performance

**How to Test:**
1. Create multiple loans with many installments
2. Create multiple budgets
3. Navigate between screens
4. Check scrolling performance
5. Check database query speed

**Expected Behavior:**
- Smooth scrolling in all lists
- Fast loading of installments and budgets
- No lag when switching screens
- Efficient database queries

## 8. Settings Persistence

**How to Test:**
1. Change each setting to a non-default value:
   - Theme: Light or Dark
   - Font Size: Small or Large
   - Language: English
   - Calendar: Gregorian
   - Notifications: Some disabled
2. Close the app completely
3. Reopen the app
4. Verify all settings are preserved

**Expected Behavior:**
- All settings persist after app restart
- App launches with last used settings
- No settings reset unexpectedly

## Common Issues to Watch For

1. **Font Scaling:** Text overlapping or cut off with large fonts
2. **Notifications:** Notifications still appearing when disabled
3. **Categories:** App crashes when using deleted categories
4. **Performance:** Slow queries with large datasets
5. **Celebration:** Animation not appearing or crashing
6. **Accessibility:** Missing labels or incorrect semantics

## Reporting Issues

When reporting an issue, please include:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Device/platform information
- Screenshots or screen recordings if applicable
