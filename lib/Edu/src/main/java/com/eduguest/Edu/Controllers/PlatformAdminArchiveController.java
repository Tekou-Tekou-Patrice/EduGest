package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.AcademicYearDto;
import com.eduguest.Edu.Service.YearArchiveService;
import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/platform-admin/schools/{schoolId}")
public class PlatformAdminArchiveController {
    private final YearArchiveService yearArchiveService;

    public PlatformAdminArchiveController(YearArchiveService yearArchiveService) {
        this.yearArchiveService = yearArchiveService;
    }

    @GetMapping("/years/recaps")
    public ResponseEntity<List<AcademicYearDto>> listRecaps(
            @PathVariable Long schoolId,
            @RequestHeader("X-School-Private-Code") String privateCode) {
        return ResponseEntity.ok(yearArchiveService.listRecapsForPlatformAdmin(schoolId, privateCode));
    }

    @GetMapping("/years/{yearId}/archives")
    public ResponseEntity<List<String>> listArchives(
            @PathVariable Long schoolId,
            @PathVariable Long yearId,
            @RequestHeader("X-School-Private-Code") String privateCode) {
        return ResponseEntity.ok(yearArchiveService.listForPlatformAdmin(schoolId, yearId, privateCode));
    }

    @GetMapping("/years/{yearId}/archives/{type}")
    public ResponseEntity<Resource> downloadArchive(
            @PathVariable Long schoolId,
            @PathVariable Long yearId,
            @PathVariable String type,
            @RequestHeader("X-School-Private-Code") String privateCode) throws IOException {
        PathResource resource = new PathResource(
                yearArchiveService.downloadForPlatformAdmin(schoolId, yearId, type, privateCode));
        return ResponseEntity.ok()
                .contentType("year_data".equals(type) ? MediaType.parseMediaType("application/gzip")
                        : MediaType.APPLICATION_PDF)
                .contentLength(resource.contentLength())
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + type
                        + ("year_data".equals(type) ? ".json.gz" : ".pdf") + "\"")
                .body(resource);
    }
}
