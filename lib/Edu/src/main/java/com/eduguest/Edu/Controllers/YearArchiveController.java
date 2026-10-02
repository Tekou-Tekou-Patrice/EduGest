package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Service.YearArchiveService;
import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/school/years/{yearId}/archives")
public class YearArchiveController {
    private final YearArchiveService yearArchiveService;

    public YearArchiveController(YearArchiveService yearArchiveService) {
        this.yearArchiveService = yearArchiveService;
    }

    @PutMapping(path = "/{type}", consumes = {
            MediaType.APPLICATION_PDF_VALUE, "application/gzip"
    })
    public ResponseEntity<Map<String, Object>> upload(@PathVariable Long yearId,
                                                       @PathVariable String type,
                                                       @RequestBody byte[] content,
                                                       @RequestHeader("Content-Type") String contentType)
            throws IOException {
        yearArchiveService.upload(yearId, type, content, contentType);
        String extension = "year_data".equals(type) ? ".json.gz" : ".pdf";
        return ResponseEntity.ok(Map.of("success", true, "type", type, "fileName", type + extension));
    }

    @GetMapping
    public ResponseEntity<List<String>> list(@PathVariable Long yearId) {
        return ResponseEntity.ok(yearArchiveService.list(yearId));
    }

    @GetMapping("/{type}")
    public ResponseEntity<Resource> download(
            @PathVariable Long yearId,
            @PathVariable String type) throws IOException {
        PathResource resource = new PathResource(yearArchiveService.download(yearId, type));
        return ResponseEntity.ok()
                .contentType("year_data".equals(type) ? MediaType.parseMediaType("application/gzip")
                        : MediaType.APPLICATION_PDF)
                .contentLength(resource.contentLength())
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + type
                                + ("year_data".equals(type) ? ".json.gz" : ".pdf") + "\"")
                .body(resource);
    }

    @PostMapping("/finalize")
    public ResponseEntity<Map<String, Object>> finalizeYear(@PathVariable Long yearId) {
        yearArchiveService.finalizeYear(yearId);
        return ResponseEntity.ok(Map.of("success", true, "message", "Année scolaire finalisée"));
    }
}
