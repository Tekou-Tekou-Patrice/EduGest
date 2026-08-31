package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
public class UserDto {
    private Long id;
    private String username;
    private String email;
    @JsonProperty("name")
    @JsonAlias("fullName")
    private String fullName;
    private String phone;
    private UserRole role;
    private boolean active;
    private Long selectedSchoolId;
    private List<SchoolMembershipDto> schools;
}
