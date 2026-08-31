package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class StudentDto {
    private Long id;
    private String firstName;
    private String lastName;
    private String className;
    private LocalDate birthDate;
    private String parentName;
    private String parentPhone;
    private String parentEmail;
    private String parentPassword;
    private String photoUrl;
    private Long classroomId;
    private Long registeredById;
    private String registeredByName;
    private LocalDateTime registrationDate;
}
