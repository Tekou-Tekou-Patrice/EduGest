package com.eduguest.Edu.DTO;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class EventDto {
    private Long id;
    private String title;
    private LocalDateTime date;
    private int hour;
    private int minute;
    private String category;
}
