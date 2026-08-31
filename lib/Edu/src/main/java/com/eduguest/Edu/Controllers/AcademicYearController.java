package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.AcademicYearDto;
import com.eduguest.Edu.Service.AcademicYearService;
import com.eduguest.Edu.Service.SchoolContextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/academique/years")
public class AcademicYearController {

    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;

    public AcademicYearController(AcademicYearService academicYearService,
                                  SchoolContextService schoolContextService) {
        this.academicYearService = academicYearService;
        this.schoolContextService = schoolContextService;
    }

    @GetMapping
    public ResponseEntity<List<AcademicYearDto>> listAll() {
        try {
            return ResponseEntity.ok(academicYearService.listAll());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/active")
    public ResponseEntity<AcademicYearDto> getActive() {
        try {
            return academicYearService.findActive()
                    .map(year -> ResponseEntity.ok(academicYearService.toDto(year)))
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/recaps")
    public ResponseEntity<List<AcademicYearDto>> listRecaps() {
        try {
            return ResponseEntity.ok(academicYearService.listRecaps());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/waiting-for-new")
    public ResponseEntity<Boolean> isWaitingForNewYear() {
        try {
            return ResponseEntity.ok(academicYearService.isWaitingForNewYear());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/setup-status")
    public ResponseEntity<Map<String, Object>> getSetupStatus() {
        try {
            Map<String, Object> status = new HashMap<>();
            status.put("hasActive", academicYearService.findActive().isPresent());
            status.put("isWaitingForNew", academicYearService.isWaitingForNewYear());
            status.put("schoolId", schoolContextService.currentSchoolId());
            academicYearService.findActive().ifPresent(year -> {
                status.put("activeYear", academicYearService.toDto(year));
            });
            return ResponseEntity.ok(status);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("hasActive", false);
            error.put("isWaitingForNew", false);
            error.put("error", e.getMessage());
            error.put("schoolId", schoolContextService.currentSchoolId());
            return ResponseEntity.ok(error);
        }
    }

    @PostMapping("/new")
    public ResponseEntity<Map<String, Object>> startNewYear(@RequestBody Map<String, Object> request) {
        try {
            String label = (String) request.getOrDefault("label", null);
            LocalDate startDate = request.containsKey("startDate") 
                ? LocalDate.parse((String) request.get("startDate")) 
                : null;
            LocalDate archiveDate = request.containsKey("archiveDate")
                ? LocalDate.parse((String) request.get("archiveDate"))
                : null;
            
            AcademicYearDto result = academicYearService.startNewYear(label, startDate, archiveDate);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("year", result);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping("/auto-activate")
    public ResponseEntity<Map<String, Object>> autoActivateYear() {
        try {
            var year = academicYearService.getOrAutoCreateActiveYear();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("year", academicYearService.toDto(year));
            response.put("message", "Academic year activated successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            error.put("schoolId", schoolContextService.currentSchoolId());
            return ResponseEntity.ok(error);
        }
    }

    @PostMapping("/close-current")
    public ResponseEntity<Map<String, Object>> closeCurrentYear() {
        try {
            AcademicYearDto result = academicYearService.closeCurrentYear();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("year", result);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping("/upsert")
    public ResponseEntity<Map<String, Object>> upsertActiveYear(@RequestBody Map<String, Object> request) {
        try {
            String label = (String) request.getOrDefault("label", null);
            LocalDate startDate = request.containsKey("startDate") 
                ? LocalDate.parse((String) request.get("startDate")) 
                : null;
            LocalDate archiveDate = request.containsKey("archiveDate")
                ? LocalDate.parse((String) request.get("archiveDate"))
                : null;
            
            var result = academicYearService.upsertActiveYear(label, startDate, archiveDate);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("year", academicYearService.toDto(result));
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PostMapping("/init-if-needed")
    public ResponseEntity<Map<String, Object>> initializeIfNeeded() {
        try {
            Map<String, Object> response = new HashMap<>();
            
            var activeYear = academicYearService.findActive();
            if (activeYear.isPresent()) {
                response.put("status", "already_active");
                response.put("year", academicYearService.toDto(activeYear.get()));
                return ResponseEntity.ok(response);
            }
            
            var created = academicYearService.getOrAutoCreateActiveYear();
            response.put("status", "created");
            response.put("year", academicYearService.toDto(created));
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", e.getMessage());
            return ResponseEntity.ok(error);
        }
    }
}
