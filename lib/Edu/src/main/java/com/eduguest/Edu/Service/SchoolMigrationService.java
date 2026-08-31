package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.eduguest.Edu.Repository.UserRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Makes upgrades safe for installations created before multi-school support.
 */
@Component
@Order(0)
public class SchoolMigrationService implements CommandLineRunner {
    private static final List<String> SCHOOL_TABLES = List.of(
            "academic_years", "students", "teachers", "classrooms", "subjects",
            "exams", "grades", "absences", "sanctions", "payments", "expenses",
            "lessons", "schedule_items", "events", "notifications", "school_info",
            "parents");

    private final SchoolRepository schoolRepository;
    private final UserRepository userRepository;
    private final SchoolMembershipRepository membershipRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public SchoolMigrationService(SchoolRepository schoolRepository,
                                  UserRepository userRepository,
                                  SchoolMembershipRepository membershipRepository) {
        this.schoolRepository = schoolRepository;
        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        School defaultSchool = schoolRepository.findByCode("DEFAULT").orElse(null);
        if (defaultSchool == null) return;

        for (String table : SCHOOL_TABLES) {
            try {
                entityManager.createNativeQuery(
                                "UPDATE " + table + " SET school_id = :schoolId WHERE school_id IS NULL")
                        .setParameter("schoolId", defaultSchool.getId())
                        .executeUpdate();
            } catch (RuntimeException ignored) {
                // Older/custom schemas may not have every optional table yet.
            }
        }

        membershipRepository.deleteAll(
                membershipRepository.findAll().stream()
                        .filter(membership -> membership.getSchool().getId().equals(defaultSchool.getId()))
                        .toList());
        schoolRepository.delete(defaultSchool);
    }
}
