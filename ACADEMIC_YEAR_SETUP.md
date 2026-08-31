# Academic Year Management - Setup Guide

## Overview

This guide explains how to properly set up and manage academic years in EduGuest to avoid the "Année scolaire clôturée" (Academic year closed) error.

## What Was Fixed

Three comprehensive fixes have been implemented:

### Option A: Graceful Error Handling
- Better error messages when no academic year is active
- Services now handle missing academic years more gracefully
- Users can still create records even if the year needs to be set up

### Option B: Auto-Activation of New Academic Year
- New method `getOrAutoCreateActiveYear()` automatically creates a new academic year if none exists
- Uses intelligent defaults based on current date
- Automatically activates the new year for immediate use

### Option C: API Endpoints for Academic Year Management
- New REST endpoints at `/api/academique/years` for managing academic years
- Comprehensive year lifecycle management (create, close, list, check status)

---

## API Endpoints

### 1. Check Current Setup Status
```
GET /api/academique/years/setup-status
```
**Response:**
```json
{
  "hasActive": false,
  "isWaitingForNew": true,
  "activeYear": null
}
```

### 2. Get Active Academic Year
```
GET /api/academique/years/active
```
**Response:**
```json
{
  "id": 1,
  "label": "2025-2026",
  "startDate": "2025-09-01",
  "endDate": "2026-06-30",
  "active": true,
  "status": "ACTIVE",
  "totalRevenue": 50000,
  "totalExpenses": 12000,
  "balance": 38000,
  "studentCount": 150,
  "teacherCount": 10
}
```

### 3. Auto-Activate New Year (Recommended for First-Time Setup)
```
POST /api/academique/years/auto-activate
```
This automatically creates and activates a new academic year with intelligent defaults.
- Start date: September 1st of current year
- End date: June 30th of next year
- Label: "YYYY-YYYY+1" (e.g., "2025-2026")

**Response:** Returns the newly created active year

### 4. Manually Create New Year (With Custom Dates)
```
POST /api/academique/years/new
Content-Type: application/json

{
  "label": "2025-2026",
  "startDate": "2025-09-01",
  "archiveDate": "2026-06-30"
}
```

**Requirements:**
- `label`: Required (e.g., "2025-2026")
- `startDate`: Optional (defaults to today)
- `archiveDate`: Optional (defaults to 10 months after start date)

**Response:** The created academic year

### 5. Update/Upsert Active Year
```
POST /api/academique/years/upsert
Content-Type: application/json

{
  "label": "2025-2026",
  "startDate": "2025-09-01",
  "archiveDate": "2026-06-30"
}
```
Updates the currently active year, or creates one if none exists.

### 6. Close Current Year
```
POST /api/academique/years/close-current
```
Archives the current academic year and computes statistics:
- Total revenue
- Total expenses
- Student count
- Teacher count
- Absence count
- Exam count
- Lesson count

**Note:** Close the current year before starting a new one.

### 7. List All Years
```
GET /api/academique/years
```
Returns all academic years (active and closed) ordered by start date descending.

### 8. List Closed Year Recaps
```
GET /api/academique/years/recaps
```
Returns all closed/archived years with their statistics.

### 9. Check if Waiting for New Year
```
GET /api/academique/years/waiting-for-new
```
Returns `true` if no active year exists but prior years have been closed.

---

## Step-by-Step Setup Instructions

### Initial Setup (First Time)

**Option 1: Automatic Setup (Recommended)**
```bash
curl -X POST http://localhost:8003/api/academique/years/auto-activate
```

This will:
1. Check if an active year exists
2. If not, create "2025-2026" (or current year + 1)
3. Set start date to September 1st
4. Set end date to June 30th of next year
5. Activate the year immediately

**Option 2: Manual Setup with Custom Dates**
```bash
curl -X POST http://localhost:8003/api/academique/years/new \
  -H "Content-Type: application/json" \
  -d '{
    "label": "2024-2025",
    "startDate": "2024-09-01",
    "archiveDate": "2025-06-30"
  }'
```

### Transitioning to a New Year

**When the current year ends:**

1. **Check status:**
   ```bash
   curl http://localhost:8003/api/academique/years/setup-status
   ```

2. **Close current year:**
   ```bash
   curl -X POST http://localhost:8003/api/academique/years/close-current
   ```
   This computes statistics for the completed year.

3. **Create and activate new year:**
   ```bash
   curl -X POST http://localhost:8003/api/academique/years/auto-activate
   ```
   Or use `/new` endpoint with custom dates.

---

## Automatic Fallback Behavior

All services that create records now handle missing academic years gracefully:

### Services Updated:
- ✅ EventService (createEvent)
- ✅ LessonService (createLesson)
- ✅ ExamService (createExam, saveGrade, saveGradesBatch)
- ✅ DisciplineService (createAbsence, createSanction)
- ✅ FinanceService (createPayment, createExpense)
- ✅ ScheduleService (createScheduleItem)
- ✅ AppNotificationService (createNotification, notifyUsers)

### How It Works:
```
When creating a record that requires an academic year:
1. Try to use the active year
2. If no active year exists → auto-create one with intelligent defaults
3. Assign the record to the newly created year
4. Continue processing
```

This means users can continue working even if the academic year setup was forgotten!

---

## Database Queries

### Check if any active year exists:
```sql
SELECT * FROM academic_years WHERE is_active = true;
```

### Check closed years:
```sql
SELECT * FROM academic_years WHERE is_active = false ORDER BY end_date DESC;
```

### Get all years:
```sql
SELECT * FROM academic_years ORDER BY start_date DESC;
```

---

## Code Examples

### Java/Spring Usage

```java
// Auto-create and activate a year if needed
AcademicYear year = academicYearService.getOrAutoCreateActiveYear();

// Get active year (throws exception if none exists)
AcademicYear activeYear = academicYearService.requireActiveYear();

// Get active year or empty if none
Optional<AcademicYear> optional = academicYearService.findActive();

// Create new year manually
academicYearService.startNewYear("2025-2026", 
    LocalDate.of(2025, 9, 1), 
    LocalDate.of(2026, 6, 30));

// Close current year
AcademicYearDto closed = academicYearService.closeCurrentYear();
```

### Flutter/Dart Usage

```dart
// Check setup status
final response = await http.get(
  Uri.parse('http://localhost:8003/api/academique/years/setup-status'),
);
final status = jsonDecode(response.body);

// Auto-activate if needed
if (!status['hasActive']) {
  final activateResponse = await http.post(
    Uri.parse('http://localhost:8003/api/academique/years/auto-activate'),
  );
  print('Year activated: ${activateResponse.body}');
}

// Get active year
final yearResponse = await http.get(
  Uri.parse('http://localhost:8003/api/academique/years/active'),
);
final activeYear = jsonDecode(yearResponse.body);
```

---

## Troubleshooting

### Issue: "Année scolaire clôturée" Error

**Cause:** No active academic year is set.

**Solutions:**
1. Quick fix - Call auto-activate endpoint:
   ```bash
   curl -X POST http://localhost:8003/api/academique/years/auto-activate
   ```

2. Check what's wrong:
   ```bash
   curl http://localhost:8003/api/academique/years/setup-status
   ```

3. If waiting for new year (closed years exist):
   ```bash
   curl -X POST http://localhost:8003/api/academique/years/new \
     -H "Content-Type: application/json" \
     -d '{"label": "2025-2026"}'
   ```

### Issue: Cannot Close Year Because Another Year is Active

**Solution:** Close the active year first:
```bash
curl -X POST http://localhost:8003/api/academique/years/close-current
```

Then create a new one.

### Issue: Year Data Not Persisting

**Check:**
1. Database connection is active
2. School ID is properly set (school scoping)
3. No active transactions are rolling back

---

## Migration from Old System

If you have existing data without academic years:

1. **List all existing records:**
   ```sql
   SELECT COUNT(*) as event_count FROM events WHERE academic_year_id IS NULL;
   ```

2. **Create/activate an academic year:**
   ```bash
   curl -X POST http://localhost:8003/api/academique/years/auto-activate
   ```

3. **The system auto-assigns:** When you close the current year, any records with `NULL` academic_year_id will be assigned to that year.

---

## Best Practices

1. **Setup immediately after installation:** Create an academic year before allowing users to create records.

2. **Use auto-activate for standard calendars:** Most schools use Sept-June. Auto-activate handles this.

3. **Update dates only for special cases:** Use the `/upsert` endpoint if you need custom dates.

4. **Close year before transition:** Always close the academic year at the end before creating a new one.

5. **Monitor status regularly:** Check `/setup-status` endpoint in your app dashboard.

6. **Backup before transition:** Close year records statistics before starting new year.

---

## Contact & Support

For issues with academic year management, check:
- Application logs for detailed error messages
- Database for year records: `academic_years` table
- School settings: ensure school_id is set
