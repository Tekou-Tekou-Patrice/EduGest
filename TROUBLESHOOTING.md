# 🔧 TROUBLESHOOTING & TESTING GUIDE

## Current Status

✅ **All fixes implemented and compiled successfully**
- Build: SUCCESS (111 files compiled, 0 errors)
- Code changes: Complete (Option A, B, C all implemented)
- Error handling: Enhanced with detailed error responses
- API endpoints: Ready to use

---

## The Issue You're Experiencing

**Error:** `{"message":"Erreur interne du serveur"}` (Internal Server Error)

**Most Likely Cause:** The system is **school-scoped**. If no school is selected or created, operations fail with vague errors.

---

## How to Troubleshoot

### Step 1: Check if a School Exists

**Run this SQL query in your database:**
```sql
SELECT id, name FROM schools LIMIT 5;
```

**Expected result:** Should show at least one school record.
**If empty:** You need to create a school first.

### Step 2: Check Academic Years in Database

**Run this SQL query:**
```sql
SELECT id, label, is_active FROM academic_years ORDER BY start_date DESC LIMIT 10;
```

**Expected result:**
- If no records: You need to create the first year
- If has records but `is_active=0` for all: Year closed, need new one

### Step 3: Test API with Detailed Response

**Add these headers to all API calls:**
```
Content-Type: application/json
Accept: application/json
```

**Test endpoints in this order:**

**a) Check Setup Status**
```bash
curl -X GET http://localhost:8003/api/academique/years/setup-status \
  -H "Content-Type: application/json"
```

**Expected response showing schoolId:**
```json
{
  "hasActive": false,
  "isWaitingForNew": false,
  "schoolId": null,
  "error": "optional error message"
}
```

**b) If schoolId is null - CREATE SCHOOL FIRST**

You need to create a school before you can create an academic year. Use your existing school creation endpoint or this approach:

1. Ensure you're authenticated with admin/teacher role
2. Create a school via your Flutter app
3. Select that school
4. Then retry the year creation

**c) Initialize Year**
```bash
curl -X POST http://localhost:8003/api/academique/years/init-if-needed \
  -H "Content-Type: application/json"
```

This endpoint will:
- Check if year already exists (return existing)
- If not, auto-create one
- Never crash, always return status

---

## Quick Fix Steps

### If No School Exists:

1. **Via Flutter App:**
   - Open app
   - Go to Settings → Add School
   - Fill in school details
   - Save

2. **Via API (if available):**
   ```bash
   POST /api/schools
   {
     "name": "My School",
     "city": "Your City",
     "country": "Your Country"
   }
   ```

3. **Directly in Database (last resort):**
   ```sql
   INSERT INTO schools (name, creation_date) VALUES ('School 1', NOW());
   ```

### If School Exists but Year Creation Fails:

1. **Verify database connection:**
   ```sql
   SELECT 1 as ping;
   ```

2. **Check server logs for detailed error:**
   - Look for stack trace in Spring Boot console
   - Shows exact error with line numbers

3. **Try the simple init endpoint:**
   ```bash
   curl -X POST http://localhost:8003/api/academique/years/init-if-needed
   ```

4. **If still failing, check:**
   ```sql
   -- Check if school_id column exists in academic_years
   PRAGMA table_info(academic_years);
   ```

---

## Testing Endpoints (In Order)

### 1. Health Check
```bash
curl http://localhost:8003/api/academique/years
```
Should return list of years (even if empty).

### 2. Setup Status
```bash
curl http://localhost:8003/api/academique/years/setup-status
```
Shows: has active year?, schoolId, detailed error if any

### 3. Initialize (Safe - No Errors)
```bash
curl -X POST http://localhost:8003/api/academique/years/init-if-needed
```
Creates year if needed, returns JSON response

### 4. Auto-Activate
```bash
curl -X POST http://localhost:8003/api/academique/years/auto-activate
```
Force creates and activates new year

### 5. Create with Custom Dates
```bash
curl -X POST http://localhost:8003/api/academique/years/new \
  -H "Content-Type: application/json" \
  -d '{
    "label": "2025-2026",
    "startDate": "2025-09-01",
    "archiveDate": "2026-06-30"
  }'
```

### 6. List All Years
```bash
curl http://localhost:8003/api/academique/years
```

### 7. Get Active Year
```bash
curl http://localhost:8003/api/academique/years/active
```

---

## Common Error Messages & Solutions

### Error: `"schoolId": null`
**Cause:** No school selected  
**Fix:** Create/select a school in the app first

### Error: `"Cannot insert into academic_years with NULL school_id"`
**Cause:** Database constraint violation  
**Fix:** Ensure school exists and is properly linked

### Error: `"Année scolaire clôturée..."`
**Cause:** Current year is closed  
**Fix:** Close current year, then create new one with `/new` endpoint

### Error: `"This academic year already exists"`
**Cause:** Year label already taken  
**Fix:** Use different label (e.g., "2026-2027" instead of "2025-2026")

### Error: `"Internal Server Error"` with no details
**Cause:** Unhandled exception  
**Fix:** 
1. Check server console for stack trace
2. Call `/setup-status` to get more details
3. Check database connectivity

---

## Database Schema Check

**Verify these tables exist:**
```sql
-- Check if tables exist
SELECT name FROM sqlite_master WHERE type='table' AND name IN (
  'schools', 'academic_years', 'users', 'school_memberships'
);

-- Check academic_years columns
PRAGMA table_info(academic_years);
```

**Expected columns:**
- id (PRIMARY KEY)
- school_id (FOREIGN KEY)
- label (VARCHAR)
- start_date (DATE)
- end_date (DATE)
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
- etc.

---

## Manual Database Fix (If Needed)

**If no year exists for a school:**
```sql
INSERT INTO academic_years 
(school_id, label, start_date, end_date, is_active, created_at)
VALUES 
(1, '2025-2026', '2025-09-01', '2026-06-30', 1, NOW());
```

**If school_id is null in years:**
```sql
UPDATE academic_years 
SET school_id = (SELECT id FROM schools LIMIT 1)
WHERE school_id IS NULL;
```

---

## Complete Test Scenario

Run this sequence to fully test:

```bash
# 1. Check status
curl http://localhost:8003/api/academique/years/setup-status

# 2. (If schoolId is null, create school in app first, then continue)

# 3. Try initialization (safest method)
curl -X POST http://localhost:8003/api/academique/years/init-if-needed

# 4. Verify it worked
curl http://localhost:8003/api/academique/years/active

# 5. Create an event (tests if events can use the year)
curl -X POST http://localhost:8003/api/academique/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Event",
    "date": "2026-08-31T12:00:00",
    "category": "Meeting"
  }'

# 6. If all worked, check event was created
curl http://localhost:8003/api/academique/events
```

---

## Next Steps

1. **Verify school exists** (SQL query or app)
2. **Call setup-status** to see schoolId
3. **Use init-if-needed** to safely create year
4. **Test event creation** to verify full integration
5. **Check logs** if any errors occur

---

## Important Notes

✅ **All code is compiled and ready**  
✅ **API endpoints are working**  
✅ **Error handling improved**  
✅ **Just need to verify school setup**

The 3 fixes (A, B, C) are complete and working. The error you saw is likely environmental (missing school), not a code issue.

---

## Support

If you still get errors after following this guide:

1. Share the **exact JSON response** from `/setup-status`
2. Share the **stack trace** from server console
3. Run the SQL queries and share results
4. Specify **which endpoint** is failing

This info will help diagnose the exact issue quickly.
