package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class BulletinPublicationDto {
    private Long id;
    private String className;
    private String period;
    private String studentId;
    private String publishedBy;
    private String publishedByRole;
    private LocalDateTime publishedAt;
    private boolean published = true;
}
