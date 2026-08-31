package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.SchoolCreateRequest;
import com.eduguest.Edu.DTO.SchoolMembershipDto;
import com.eduguest.Edu.DTO.RegisterRequest;
import com.eduguest.Edu.DTO.UserDto;
import com.eduguest.Edu.Service.SchoolService;
import com.eduguest.Edu.Service.UserService;
import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schools")
public class SchoolController {
    private final SchoolService schoolService;
    private final UserService userService;

    public SchoolController(SchoolService schoolService, UserService userService) {
        this.schoolService = schoolService;
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<List<SchoolMembershipDto>> list(@RequestParam(required = false) Long userId) {
        return ResponseEntity.ok(schoolService.accessibleSchools(userId));
    }

    @GetMapping("/accessible")
    public ResponseEntity<List<SchoolMembershipDto>> accessible(@RequestParam Long userId) {
        return ResponseEntity.ok(schoolService.membershipsForUser(userId));
    }

    /**
     * Stable Flutter contract: returns memberships as school summaries
     * containing at least schoolId/schoolName (and the membership role).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<SchoolMembershipDto>> forUser(@PathVariable Long userId) {
        return ResponseEntity.ok(schoolService.membershipsForUser(userId));
    }

    @PostMapping
    public ResponseEntity<?> create(@Valid @RequestBody SchoolCreateRequest request) {
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
        SchoolMembershipDto selected = schoolService.select(userId, schoolId);
        return ResponseEntity.ok()
                .header("X-School-Id", String.valueOf(selected.getSchoolId()))
                .body(selected);
    }

    @PostMapping("/join")
    public ResponseEntity<SchoolMembershipDto> join(@RequestParam Long userId,
                                                     @RequestParam String code) {
        return ResponseEntity.ok(schoolService.joinByCode(userId, code));
    }

    @GetMapping("/all")
    public ResponseEntity<List<com.eduguest.Edu.DTO.SchoolDto>> getAllSchools() {
        return ResponseEntity.ok(schoolService.getAllSchools());
    }

    @GetMapping("/stats")
    public ResponseEntity<java.util.Map<String, Object>> getStats() {
        return ResponseEntity.ok(schoolService.getGlobalStats());
    }

    @GetMapping("/{schoolId}")
    public ResponseEntity<com.eduguest.Edu.DTO.SchoolDto> getSchool(@PathVariable Long schoolId) {
        return ResponseEntity.ok(new com.eduguest.Edu.DTO.SchoolDto(
                schoolService.getRequired(schoolId).getId(),
                schoolService.getRequired(schoolId).getName(),
                schoolService.getRequired(schoolId).getCode(),
                schoolService.getRequired(schoolId).isActive(),
                schoolService.getRequired(schoolId).getCreatedAt(),
                null
        ));
    }

    @PatchMapping("/{schoolId}/toggle")
    public ResponseEntity<com.eduguest.Edu.DTO.SchoolDto> toggleSchool(@PathVariable Long schoolId) {
        return ResponseEntity.ok(schoolService.toggleStatus(schoolId));
    }

    @DeleteMapping("/{schoolId}")
    public ResponseEntity<Void> deleteSchool(@PathVariable Long schoolId) {
        schoolService.deleteSchool(schoolId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{schoolId}/code")
    public ResponseEntity<Void> updateCode(@PathVariable Long schoolId,
                                            @RequestParam Long userId,
                                            @RequestParam String code) {
        schoolService.updateCode(userId, schoolId, code);
        return ResponseEntity.noContent().build();
    }
}
