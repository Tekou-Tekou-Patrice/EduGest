package com.eduguest.Edu.DTO;

import lombok.Data;

@Data
public class TeacherDto {
    private Long id;
    private String firstName;
    private String lastName;
    private String speciality;
    private String email;
    private String phone;
    private String password; // Ajouté pour le recrutement
}
