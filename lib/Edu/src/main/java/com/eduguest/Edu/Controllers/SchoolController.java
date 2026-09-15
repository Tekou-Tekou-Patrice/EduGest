package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.SchoolCreateRequest;
import com.eduguest.Edu.DTO.SchoolMembershipDto;
import com.eduguest.Edu.DTO.RegisterRequest;
import com.eduguest.Edu.DTO.UserDto;
import com.eduguest.Edu.Service.SchoolService;
import com.eduguest.Edu.Service.UserService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/schools")
public class SchoolController {
    private final SchoolService schoolService;
    private final UserService userService;
    private final UserSecurityContextService securityContextService;

    public SchoolController(SchoolService schoolService, UserService userService,
                            UserSecurityContextService securityContextService) {
        this.schoolService = schoolService;
        this.userService = userService;
        this.securityContextService = securityContextService;
    }

    @GetMapping
    public ResponseEntity<List<SchoolMembershipDto>> list(@RequestParam(required = false) Long userId) {
        Long currentUserId = securityContextService.getCurrentUserId();
        return ResponseEntity.ok(schoolService.accessibleSchools(currentUserId));
    }

    @GetMapping("/accessible")
    public ResponseEntity<List<SchoolMembershipDto>> accessible(@RequestParam Long userId) {
        securityContextService.requireUserOrStaff(userId);
        return ResponseEntity.ok(schoolService.membershipsForUser(userId));
    }

    /**
     * Stable Flutter contract: returns memberships as school summaries
     * containing at least schoolId/schoolName (and the membership role).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<SchoolMembershipDto>> forUser(@PathVariable Long userId) {
        securityContextService.requireUserOrStaff(userId);
        return ResponseEntity.ok(schoolService.membershipsForUser(userId));
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody SchoolCreateRequest request) {
        if (request.getUserId() == null) {
            request.setUserId(securityContextService.getCurrentUserId());
        } else if (!request.getUserId().equals(securityContextService.getCurrentUserId())) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Le créateur doit être l'utilisateur authentifié.");
        }
        return ResponseEntity.ok(schoolService.create(request));
    }

    /**
     * Same payload as POST /api/users/register. This alias always creates a
     * founder account, school, and founder membership.
     */
    @PostMapping("/register-founder")
     public ResponseEntity<UserDto> registerFounder(@RequestBody RegisterRequest request) {
        request.setRole(UserRole.FONDATEUR);
        return ResponseEntity.ok(userService.register(request));
    }

    @PostMapping("/select")
    public ResponseEntity<SchoolMembershipDto> select(@RequestParam Long userId,
                                                       @RequestParam Long schoolId) {
        securityContextService.requireUserOrStaff(userId);
        SchoolMembershipDto selected = schoolService.select(userId, schoolId);
        return ResponseEntity.ok()
                .header("X-School-Id", String.valueOf(selected.getSchoolId()))
                .body(selected);
    }

    @PostMapping("/join")
    public ResponseEntity<SchoolMembershipDto> join(@RequestParam Long userId,
                                                     @RequestParam String code) {
        securityContextService.requireUserOrStaff(userId);
        return ResponseEntity.ok(schoolService.joinByCode(userId, code));
    }

    @GetMapping("/all")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<List<com.eduguest.Edu.DTO.SchoolDto>> getAllSchools() {
        return ResponseEntity.ok(schoolService.getAllSchools());
    }

    @GetMapping("/stats")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<java.util.Map<String, Object>> getStats() {
        return ResponseEntity.ok(schoolService.getGlobalStats());
    }

    @GetMapping("/expiring-soon")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<List<com.eduguest.Edu.DTO.SchoolDto>> getSchoolsExpiringSoon() {
        return ResponseEntity.ok(schoolService.getSchoolsExpiringWithinSevenDays());
    }

    @PostMapping("/{schoolId}/subscription/renew")
    @RequireRoles({UserRole.FONDATEUR, UserRole.COMPTABLE})
    public ResponseEntity<com.eduguest.Edu.DTO.SchoolDto> renewSubscription(
            @PathVariable Long schoolId,
            @RequestParam Long actorId,
            @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(schoolService.renewSubscription(
                schoolId,
                actorId,
                body.get("months") == null ? null : Integer.valueOf(body.get("months").toString()),
                body.get("amount") == null ? null : Double.valueOf(body.get("amount").toString()),
                body.get("paymentMethod") == null ? null : body.get("paymentMethod").toString(),
                body.get("transactionRef") == null ? null : body.get("transactionRef").toString(),
                body.get("notes") == null ? null : body.get("notes").toString()));
    }

    @PostMapping("/{schoolId}/staff-renewal")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<Void> saveStaffRenewal(
            @PathVariable Long schoolId,
            @RequestParam Long founderId,
            @RequestBody Map<String, Object> body) {
        if (!founderId.equals(securityContextService.getCurrentUserId())) {
            throw new org.springframework.security.access.AccessDeniedException("Action non autorisée.");
        }
        schoolService.saveStaffRenewal(schoolId, founderId, body);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{schoolId}")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<com.eduguest.Edu.DTO.SchoolDto> getSchool(@PathVariable Long schoolId) {
        return ResponseEntity.ok(schoolService.getSchoolDto(schoolId));
    }

    @PatchMapping("/{schoolId}/toggle")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<com.eduguest.Edu.DTO.SchoolDto> toggleSchool(@PathVariable Long schoolId) {
        return ResponseEntity.ok(schoolService.toggleStatus(schoolId));
    }

    @DeleteMapping("/{schoolId}")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<Void> deleteSchool(@PathVariable Long schoolId) {
        schoolService.deleteSchool(schoolId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{schoolId}/code")
    @RequireRoles(UserRole.FONDATEUR)
    public ResponseEntity<Void> updateCode(@PathVariable Long schoolId,
                                            @RequestParam Long userId,
                                            @RequestParam String code) {
        if (!userId.equals(securityContextService.getCurrentUserId())) {
            throw new org.springframework.security.access.AccessDeniedException("Action non autorisée.");
        }
        schoolService.updateCode(userId, schoolId, code);
        return ResponseEntity.noContent().build();
    }
}
