package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    private String username;

    @Email
    @NotBlank
    private String email;

    @NotBlank
    private String password;

    @JsonProperty("fullName")
    @JsonAlias({"name", "full_name"})
    private String fullName;

    private String phone;

    private UserRole role;

    /** Optional for existing clients; required only when creating a founder school. */
    @JsonAlias({"school_name", "school"})
    private String schoolName;

    @JsonAlias({"school_code", "code"})
    private String schoolCode;

    private Long schoolId;
}
