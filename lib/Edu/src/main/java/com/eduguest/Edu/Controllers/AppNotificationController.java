package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.AppNotificationDto;
import com.eduguest.Edu.Service.AppNotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class AppNotificationController {

    private final AppNotificationService notificationService;

    public AppNotificationController(AppNotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping("/unread")
    public ResponseEntity<List<AppNotificationDto>> getUnreadNotifications(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long userHeader) {
        try {
            return ResponseEntity.ok(notificationService.getUnreadNotifications(
                    userId != null ? userId : userHeader));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable Long id,
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long userHeader) {
        notificationService.markAsRead(id, userId != null ? userId : userHeader);
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    public ResponseEntity<AppNotificationDto> createNotification(@RequestBody AppNotificationDto dto) {
        return ResponseEntity.ok(notificationService.createNotification(dto));
    }
}
