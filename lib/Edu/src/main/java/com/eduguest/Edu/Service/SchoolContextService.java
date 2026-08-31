package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolScoped;
import com.eduguest.Edu.Repository.SchoolRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Collection;
import java.util.List;
import java.util.Objects;

/**
 * Resolves the optional school context without requiring a token. Flutter can
 * send ?schoolId=... or X-School-Id/School-Id.
 */
@Service
public class SchoolContextService {
    public static final String SCHOOL_HEADER = "X-School-Id";

    private final SchoolRepository schoolRepository;

    public SchoolContextService(SchoolRepository schoolRepository) {
        this.schoolRepository = schoolRepository;
    }

    public Long currentSchoolId() {
        ServletRequestAttributes attributes =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes != null) {
            HttpServletRequest request = attributes.getRequest();
            Long parsed = parse(request.getParameter("schoolId"));
            if (parsed == null) parsed = parse(request.getHeader(SCHOOL_HEADER));
            if (parsed == null) parsed = parse(request.getHeader("School-Id"));
            if (parsed != null && schoolRepository.existsById(parsed)) return parsed;
        }
        return null;
    }

    public School currentSchool() {
        Long id = currentSchoolId();
        return id == null ? null : schoolRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("École introuvable"));
    }

    public <T extends SchoolScoped> List<T> scope(Collection<T> records) {
        Long schoolId = currentSchoolId();
        if (schoolId == null) return List.of();
        return records.stream()
                .filter(record -> record.getSchool() != null
                        ? Objects.equals(record.getSchool().getId(), schoolId)
                        : false)
                .toList();
    }

    public <T extends SchoolScoped> T assign(T record) {
        School school = currentSchool();
        if (school == null) {
            throw new IllegalStateException("Aucune école active");
        }
        record.setSchool(school);
        return record;
    }

    public <T extends SchoolScoped> T verifyAndAssign(T record) {
        Long currentId = currentSchoolId();
        if (record.getSchool() != null && currentId != null
                && !Objects.equals(record.getSchool().getId(), currentId)) {
            throw new IllegalArgumentException("Cette ressource appartient à une autre école");
        }
        return assign(record);
    }

    private Long parse(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Long.valueOf(value.trim());
        } catch (NumberFormatException ignored) {
            return null;
        }
    }
}
