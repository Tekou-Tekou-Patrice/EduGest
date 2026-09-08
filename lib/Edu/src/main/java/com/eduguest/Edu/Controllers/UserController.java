package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Config.RequireRoles;
import com.eduguest.Edu.DTO.LoginRequest;
import com.eduguest.Edu.DTO.LoginResponse;
import com.eduguest.Edu.DTO.PasswordChangeRequest;
import com.eduguest.Edu.DTO.RegisterRequest;
import com.eduguest.Edu.DTO.StudentDto;
import com.eduguest.Edu.DTO.TeacherDto;
import com.eduguest.Edu.DTO.UserDto;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Service.ScolariteService;
import com.eduguest.Edu.Service.UserService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;
    private final ScolariteService scolariteService;
    private final UserSecurityContextService securityContextService;

    public UserController(UserService userService, ScolariteService scolariteService,
                          UserSecurityContextService securityContextService) {
        this.userService = userService;
        this.scolariteService = scolariteService;
        this.securityContextService = securityContextService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(userService.login(request));
    }

    @PostMapping("/register")
    public ResponseEntity<UserDto> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(userService.register(request));
    }

    @PostMapping("/{id}/change-password")
    public ResponseEntity<Void> changePassword(@PathVariable Long id, @Valid @RequestBody PasswordChangeRequest request) {
        securityContextService.requireUserOrStaff(id);
        userService.changePassword(id, request);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<List<UserDto>> getAllUsers() {
        return ResponseEntity.ok(userService.findAll());
    }

    @GetMapping("/staff")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<?> getStaff(
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String query) {
        if (role != null && "ENSEIGNANT".equalsIgnoreCase(role.trim())) {
            return ResponseEntity.ok(scolariteService.getTeachers(query));
        }
        return ResponseEntity.ok(userService.findStaff());
    }

    @PostMapping("/staff")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR})
    public ResponseEntity<TeacherDto> createStaffTeacher(@Valid @RequestBody TeacherDto dto) {
        return ResponseEntity.ok(scolariteService.createTeacher(dto));
    }

    @DeleteMapping("/staff/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR})
    public ResponseEntity<Void> deleteStaffTeacher(@PathVariable Long id) {
        scolariteService.deleteTeacher(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/students")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE, UserRole.ENSEIGNANT})
    public ResponseEntity<List<StudentDto>> getStudents(
            @RequestParam(required = false) String className,
            @RequestParam(required = false) String query) {
        return ResponseEntity.ok(scolariteService.getStudents(className, query));
    }

    @GetMapping("/parents/{parentUserId}/students")
    public ResponseEntity<List<StudentDto>> getStudentsForParent(@PathVariable Long parentUserId) {
        securityContextService.requireUserOrStaff(parentUserId);
        return ResponseEntity.ok(scolariteService.getStudentsForParent(parentUserId));
    }

    @PostMapping("/students")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<StudentDto> createStudent(@Valid @RequestBody StudentDto dto) {
        return ResponseEntity.ok(scolariteService.createStudent(dto));
    }

    @DeleteMapping("/students/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR, UserRole.SECRETAIRE})
    public ResponseEntity<Void> deleteStudent(@PathVariable Long id) {
        scolariteService.deleteStudent(id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    @RequireRoles({UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.CENSEUR})
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
