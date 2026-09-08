package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.SchoolMembershipDto;
import com.eduguest.Edu.Service.SchoolService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users/{userId}/schools")
public class UserSchoolController {
    private final SchoolService schoolService;
    private final UserSecurityContextService securityContextService;

    public UserSchoolController(SchoolService schoolService,
                                UserSecurityContextService securityContextService) {
        this.schoolService = schoolService;
        this.securityContextService = securityContextService;
    }

    @GetMapping
    public ResponseEntity<List<SchoolMembershipDto>> list(@PathVariable Long userId) {
        securityContextService.requireUserOrStaff(userId);
        return ResponseEntity.ok(schoolService.membershipsForUser(userId));
    }

    @PostMapping("/{schoolId}/select")
    public ResponseEntity<SchoolMembershipDto> select(@PathVariable Long userId,
                                                       @PathVariable Long schoolId) {
        securityContextService.requireUserOrStaff(userId);
        SchoolMembershipDto selected = schoolService.select(userId, schoolId);
        return ResponseEntity.ok()
                .header("X-School-Id", String.valueOf(selected.getSchoolId()))
                .body(selected);
    }
}
