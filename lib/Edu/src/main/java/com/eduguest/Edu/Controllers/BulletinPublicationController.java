package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.BulletinPublicationDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.BulletinPublicationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/academique/bulletin-publications")
public class BulletinPublicationController {

    private final BulletinPublicationService service;

    public BulletinPublicationController(BulletinPublicationService service) {
        this.service = service;
    }

    @GetMapping("/check")
    public ResponseEntity<Map<String, Object>> checkStatus(
            @RequestParam String className,
            @RequestParam String period,
            @RequestParam(required = false) String studentId) {
        BulletinPublicationDto pub = service.checkStatus(className, period, studentId);
        Map<String, Object> response = new HashMap<>();
        response.put("published", pub != null && pub.isPublished());
        response.put("publication", pub);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<List<BulletinPublicationDto>> getPublications(
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String period) {
        return ResponseEntity.ok(service.getPublications(className, period));
    }

    @GetMapping("/readiness")
    public ResponseEntity<Map<String, Object>> readiness(
            @RequestParam String className,
            @RequestParam(required = false) String period,
            @RequestParam(required = false) String studentId) {
        return ResponseEntity.ok(service.getReadiness(className, period, studentId));
    }

    @PostMapping("/publish")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE})
    public ResponseEntity<BulletinPublicationDto> publish(@RequestBody Map<String, Object> payload) {
        String className = payload.get("className") != null ? payload.get("className").toString() : "";
        String period = payload.get("period") != null ? payload.get("period").toString() : "";
        String studentId = payload.get("studentId") != null ? payload.get("studentId").toString() : null;
        String publishedBy = payload.get("publishedBy") != null ? payload.get("publishedBy").toString() : "Direction";
        String publishedByRole = payload.get("publishedByRole") != null ? payload.get("publishedByRole").toString() : "Direction";

        return ResponseEntity.ok(service.publish(className, period, studentId, publishedBy, publishedByRole));
    }

    @PostMapping("/unpublish")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE})
    public ResponseEntity<BulletinPublicationDto> unpublish(@RequestBody Map<String, Object> payload) {
        String className = payload.get("className") != null ? payload.get("className").toString() : "";
        String period = payload.get("period") != null ? payload.get("period").toString() : "";
        String studentId = payload.get("studentId") != null ? payload.get("studentId").toString() : null;

        return ResponseEntity.ok(service.unpublish(className, period, studentId));
    }
}
