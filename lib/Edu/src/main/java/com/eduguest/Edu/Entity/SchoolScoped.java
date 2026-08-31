package com.eduguest.Edu.Entity;

/**
 * Marks records that belong to a school. The relation is nullable so existing
 * installations can be upgraded without breaking old rows.
 */
public interface SchoolScoped {
    School getSchool();
    void setSchool(School school);
}
