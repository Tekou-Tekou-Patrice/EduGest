package com.eduguest.Edu.Config;

import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Repository.SchoolRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/** Blocks all school-scoped application requests for suspended schools. */
@Component
public class ActiveSchoolFilter extends OncePerRequestFilter {
    private final SchoolRepository schoolRepository;

    public ActiveSchoolFilter(SchoolRepository schoolRepository) {
        this.schoolRepository = schoolRepository;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/")
                || request.getRequestURI().startsWith("/api/schools")
                || request.getRequestURI().startsWith("/api/saas-settings");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        Long schoolId = parseSchoolId(request);
        if (schoolId != null) {
            School school = schoolRepository.findById(schoolId).orElse(null);
            if (school == null) {
                sendError(response, HttpStatus.NOT_FOUND, "École introuvable");
                return;
            }
            if (!school.isActive()) {
                sendError(response, HttpStatus.FORBIDDEN,
                        "Cette école est désactivée. Aucune activité n'est autorisée.");
                return;
            }
        }
        filterChain.doFilter(request, response);
    }

    private Long parseSchoolId(HttpServletRequest request) {
        String raw = request.getParameter("schoolId");
        if (raw == null || raw.isBlank()) raw = request.getHeader("X-School-Id");
        if (raw == null || raw.isBlank()) raw = request.getHeader("School-Id");
        try {
            return raw == null || raw.isBlank() ? null : Long.valueOf(raw.trim());
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private void sendError(HttpServletResponse response, HttpStatus status, String message) throws IOException {
        response.setStatus(status.value());
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"message\":\"" + message + "\"}");
    }
}
