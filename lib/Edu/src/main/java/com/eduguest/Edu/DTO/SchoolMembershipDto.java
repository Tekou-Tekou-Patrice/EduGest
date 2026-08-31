package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolMembershipDto {
    private Long id;
    private Long userId;
    private Long schoolId;
    private String schoolName;
    private String schoolCode;
    private UserRole role;
    private boolean active;
}
