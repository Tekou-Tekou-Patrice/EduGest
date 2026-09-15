package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @JsonAlias({"userName", "user_name", "login"})
    private String username;

    @Email
    @JsonAlias({"emailAddress"})
    private String email;

    @NotBlank
    @Size(min = 6, message = "Le mot de passe doit contenir au moins 6 caractères")
    @JsonAlias({"pwd"})
    private String password;

    @JsonProperty("fullName")
    @JsonAlias({"name", "full_name"})
    @NotBlank(message = "Le nom est obligatoire")
    private String fullName;

    private String phone;

    @JsonAlias({"userRole", "roleName"})
    private UserRole role;

    /** Optional for existing clients; required only when creating a founder school. */
    @JsonAlias({"school_name", "school"})
    private String schoolName;

    @JsonAlias({"school_code", "code"})
    private String schoolCode;

    private Long schoolId;

    private Long registeredByUserId;

    private String language = "fr";
}
