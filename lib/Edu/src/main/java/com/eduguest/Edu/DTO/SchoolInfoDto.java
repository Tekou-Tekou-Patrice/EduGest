package com.eduguest.Edu.DTO;

import lombok.Data;

import java.time.LocalDate;

@Data
public class SchoolInfoDto {
    private String id;
    private String name;
    private String code;
    private String address;
    private String phone;
    private String email;
    private String logoUrl;
    private String currentYearId;
    private Long currentYearNumericId;
    private LocalDate startDate;
    private LocalDate archiveDate;
    private String yearStatus;
    private boolean waitingForNewYear;
}
