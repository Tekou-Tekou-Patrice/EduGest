package com.eduguest.Edu.DTO;

import lombok.Data;
import java.util.List;

@Data
public class ParentDto {
    private Long id;
    private String firstName;
    private String lastName;
    private String phone;
    private String email;
    private String address;
    private List<String> studentIds;
}
