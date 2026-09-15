package com.eduguest.Edu.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "classrooms")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Classroom implements SchoolScoped {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 60)
    private String name;

    @Column(length = 40)
    private String level;

    @Column(name = "exam_class", nullable = false)
    private boolean examClass = false;

    @Column(nullable = false)
    private Integer capacity;

    @Column(length = 255)
    private String description;

    @Column(name = "tuition_fee")
    private Double tuitionFee;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id")
    private Teacher teacher;

    @ManyToMany
    @JoinTable(
            name = "classroom_teachers",
            joinColumns = @JoinColumn(name = "classroom_id"),
            inverseJoinColumns = @JoinColumn(name = "teacher_id"),
            uniqueConstraints = @UniqueConstraint(name = "uk_classroom_teacher", columnNames = {"classroom_id", "teacher_id"})
    )
    private Set<Teacher> teachers = new LinkedHashSet<>();

    @OneToMany(mappedBy = "classroom", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Student> students = new ArrayList<>();
}
