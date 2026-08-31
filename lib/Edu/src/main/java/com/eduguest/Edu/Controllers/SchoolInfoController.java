package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.AcademicYearDto;
import com.eduguest.Edu.DTO.SchoolInfoDto;
import com.eduguest.Edu.Service.AcademicYearService;
import com.eduguest.Edu.Service.SchoolInfoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/school")
public class SchoolInfoController {

    private final SchoolInfoService schoolInfoService;
    private final AcademicYearService academicYearService;

    public SchoolInfoController(SchoolInfoService schoolInfoService,
                                AcademicYearService academicYearService) {
        this.schoolInfoService = schoolInfoService;
        this.academicYearService = academicYearService;
    }

    @GetMapping("/info")
    public ResponseEntity<SchoolInfoDto> getSchoolInfo() {
        return ResponseEntity.ok(schoolInfoService.getSchoolInfo());
    }

    @PutMapping("/info")
    public ResponseEntity<SchoolInfoDto> updateSchoolInfo(@Valid @RequestBody SchoolInfoDto dto) {
        return ResponseEntity.ok(schoolInfoService.updateSchoolInfo(dto));
    }

    @GetMapping("/years")
    public ResponseEntity<List<AcademicYearDto>> listYears() {
        return ResponseEntity.ok(academicYearService.listAll());
    }

    @GetMapping("/years/recaps")
    public ResponseEntity<List<AcademicYearDto>> listRecaps() {
        return ResponseEntity.ok(academicYearService.listRecaps());
    }

    @PostMapping("/years")
    public ResponseEntity<AcademicYearDto> startYear(@RequestBody Map<String, Object> body) {
        String label = body.get("label") != null ? body.get("label").toString()
                : (body.get("currentYearId") != null ? body.get("currentYearId").toString() : null);
        LocalDate startDate = parseDate(body.get("startDate"));
        LocalDate archiveDate = parseDate(body.get("archiveDate") != null ? body.get("archiveDate") : body.get("endDate"));
        return ResponseEntity.ok(academicYearService.startNewYear(label, startDate, archiveDate));
    }

    @PostMapping("/years/close")
    public ResponseEntity<AcademicYearDto> closeYear() {
        return ResponseEntity.ok(academicYearService.closeCurrentYear());
    }

    private LocalDate parseDate(Object value) {
        if (value == null) return null;
        String text = value.toString().trim();
        if (text.isEmpty()) return null;
        if (text.length() >= 10) {
            return LocalDate.parse(text.substring(0, 10));
        }
        return LocalDate.parse(text);
    }
}
