package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AppNotificationDto {
    private Long id;
    private String title;
    private String message;
    private LocalDateTime timestamp;
    private boolean read;
    private String type;
    private Long recipientUserId;
}
