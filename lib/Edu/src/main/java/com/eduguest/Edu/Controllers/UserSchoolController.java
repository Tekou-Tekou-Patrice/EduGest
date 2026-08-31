package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.SchoolMembershipDto;
import com.eduguest.Edu.Service.SchoolService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users/{userId}/schools")
public class UserSchoolController {
    private final SchoolService schoolService;

    public UserSchoolController(SchoolService schoolService) {
        this.schoolService = schoolService;
    }

    @GetMapping
    public ResponseEntity<List<SchoolMembershipDto>> list(@PathVariable Long userId) {
        return ResponseEntity.ok(schoolService.membershipsForUser(userId));
    }

    @PostMapping("/{schoolId}/select")
    public ResponseEntity<SchoolMembershipDto> select(@PathVariable Long userId,
                                                       @PathVariable Long schoolId) {
        SchoolMembershipDto selected = schoolService.select(userId, schoolId);
        return ResponseEntity.ok()
                .header("X-School-Id", String.valueOf(selected.getSchoolId()))
                .body(selected);
    }
}
