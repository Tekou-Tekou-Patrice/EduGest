package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.AppNotificationDto;
import com.eduguest.Edu.Service.AppNotificationService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class AppNotificationController {

    private final AppNotificationService notificationService;
    private final UserSecurityContextService securityContextService;

    public AppNotificationController(AppNotificationService notificationService,
                                     UserSecurityContextService securityContextService) {
        this.notificationService = notificationService;
        this.securityContextService = securityContextService;
    }

    @GetMapping("/unread")
    public ResponseEntity<List<AppNotificationDto>> getUnreadNotifications(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long userHeader) {
        try {
            Long currentUserId = securityContextService.getCurrentUserId();
            return ResponseEntity.ok(notificationService.getUnreadNotifications(currentUserId));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable Long id,
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long userHeader) {
        notificationService.markAsRead(id, securityContextService.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    public ResponseEntity<AppNotificationDto> createNotification(@RequestBody AppNotificationDto dto) {
        return ResponseEntity.ok(notificationService.createNotification(dto));
    }

    @PostMapping("/remind-payment")
    public ResponseEntity<Void> remindPayment(@RequestBody java.util.Map<String, Object> payload) {
        String studentId = payload.get("studentId") != null ? payload.get("studentId").toString() : "";
        String studentName = payload.get("studentName") != null ? payload.get("studentName").toString() : "";
        double amount = payload.get("amount") != null ? Double.parseDouble(payload.get("amount").toString()) : 0;
        String reason = payload.get("reason") != null ? payload.get("reason").toString() : "";
        notificationService.notifyPaymentReminder(studentId, studentName, amount, reason);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/announcement")
    public ResponseEntity<Void> broadcastAnnouncement(@RequestBody java.util.Map<String, Object> payload) {
        String title = payload.get("title") != null ? payload.get("title").toString() : "Annonce";
        String message = payload.get("message") != null ? payload.get("message").toString() : "";
        String audience = payload.get("audience") != null ? payload.get("audience").toString() : "TOUS";
        notificationService.notifyImportantAnnouncement(title, message, audience);
        return ResponseEntity.ok().build();
    }
}
