package com.eduguest.Edu.DTO;

import com.eduguest.Edu.Entity.UserRole;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank
    private String username;

    @NotBlank
    private String password;

    /** Rôle demandé par le front (optionnel, validé s'il est fourni). */
    private UserRole role;
}
