package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "school_info")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolInfo implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;
    @Id
    private String id; // ID unique pour l'école

    private String name;
    private String address;
    private String phone;
    private String email;
    private String logoUrl;

    @Column(name = "current_year_id")
    private String currentYearId;
}
