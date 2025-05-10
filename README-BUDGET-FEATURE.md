# Flutter Finance App - Budget Feature Implementation Guide

This guide explains how to implement the Monthly Budget feature in the Flutter Finance App with NPR (Nepalese Rupees) currency support and fix the database issues.

## Database Fixes

The app has several database-related issues that need to be fixed:

1. **Missing Budgets Table**: The budgets table doesn't exist in the database schema.
2. **Recursive RLS Policies**: The group_members table has recursive Row Level Security (RLS) policies causing infinite recursion.
3. **Currency Support**: We need to ensure proper support for NPR currency throughout the app.

### How to Apply Database Fixes

1. **Option 1: Using the SQL Editor in Supabase Dashboard**:
   - Open your Supabase project dashboard
   - Navigate to the SQL Editor
   - Copy the entire content of `complete_database_fix.sql`
   - Paste it into the SQL Editor and run the script

2. **Option 2: Using PowerShell Script**:
   - Open PowerShell
   - Navigate to your project directory
   - Run the application script with your Supabase URL and service key:

```powershell
.\apply_database_fixes.ps1 -SupabaseUrl 'https://your-project.supabase.co' -ServiceRoleKey 'your-service-role-key'
```

## App Features Implemented

1. **Monthly Budget Setting**:
   - Users can set a monthly budget in NPR
   - Default currency is set to NPR
   - Budget is associated with the current month and year

2. **Budget Tracking**:
   - Shows current budget amount
   - Tracks total expenses against budget
   - Calculates remaining budget
   - Displays warning when budget is exceeded

3. **NPR Currency Support**:
   - All monetary values displayed in NPR format
   - Used locale settings for proper formatting

## File Changes

1. **Database Schema**:
   - Created budgets table with RLS policies
   - Fixed recursive policies in group_members table
   - Added support for NPR currency

2. **Flutter Code**:
   - Updated BudgetProvider to format NPR currency
   - Enhanced budget card UI to show warnings when budget is exceeded
   - Fixed currency formatting across expense listings

## Verification Steps

After applying the database fixes, verify the implementation:

1. **Check Budget Table Creation**:
   - In Supabase, go to Table Editor
   - Verify that the budgets table exists with the correct structure

2. **Test Budget Setting**:
   - Launch the app and navigate to the Budget Setting screen
   - Set a monthly budget (try various amounts)
   - Verify the budget is saved correctly

3. **Check NPR Currency Display**:
   - Verify that all monetary values are displayed with NPR format
   - Add expenses and check if they are correctly deducted from the budget

4. **Group Members Fix**:
   - Create a new group and add members
   - Verify that you can view group members without errors
   - Check that expense splitting works correctly

## Troubleshooting

If you encounter issues after applying the fixes:

1. **Database Issues**:
   - Check the Supabase logs for SQL errors
   - Verify that all tables and policies were created correctly
   - Try running individual sections of the SQL script separately

2. **App Issues**:
   - Check Flutter logs for errors
   - Verify that all required packages are installed
   - Clear app cache and restart the app

## Next Steps

After implementing the budget feature, consider these enhancements:

1. **Budget Categories**: Allow users to set budget limits for different expense categories
2. **Budget History**: Track budget usage over time with historical data
3. **Notifications**: Alert users when they approach their budget limit
4. **Currency Conversion**: Add support for multiple currencies with conversion
