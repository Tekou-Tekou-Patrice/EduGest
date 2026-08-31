package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class LoginResponse {
    private Long id;
    private String name;
    private String email;
    private UserRole role;
    private String token; // Pour le futur JWT
    private Long selectedSchoolId;
    private List<SchoolMembershipDto> schools;
}
