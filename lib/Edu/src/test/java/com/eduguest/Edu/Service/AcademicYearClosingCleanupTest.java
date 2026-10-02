package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Repository.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.mockito.ArgumentCaptor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AcademicYearClosingCleanupTest {

    @Test
    void closingYearTriggersBackupTagsRecordsAndDefersAllDeletion() {
        AcademicYearRepository academicYearRepository = mock(AcademicYearRepository.class);
        SchoolInfoRepository schoolInfoRepository = mock(SchoolInfoRepository.class);
        PaymentRepository paymentRepository = mock(PaymentRepository.class);
        ExpenseRepository expenseRepository = mock(ExpenseRepository.class);
        StudentRepository studentRepository = mock(StudentRepository.class);
        TeacherRepository teacherRepository = mock(TeacherRepository.class);
        AbsenceRepository absenceRepository = mock(AbsenceRepository.class);
        SanctionRepository sanctionRepository = mock(SanctionRepository.class);
        ExamRepository examRepository = mock(ExamRepository.class);
        LessonRepository lessonRepository = mock(LessonRepository.class);
        GradeRepository gradeRepository = mock(GradeRepository.class);
        EventRepository eventRepository = mock(EventRepository.class);
        ScheduleItemRepository scheduleItemRepository = mock(ScheduleItemRepository.class);
        SchoolContextService schoolContextService = mock(SchoolContextService.class);
        BackupService backupService = mock(BackupService.class);
        EntityManager entityManager = mock(EntityManager.class);
        Query query = mock(Query.class);

        when(entityManager.createQuery(anyString())).thenReturn(query);
        when(query.setParameter(anyString(), any())).thenReturn(query);
        when(query.executeUpdate()).thenReturn(1);

        School school = new School();
        school.setId(5L);
        school.setName("Ecole Pilote");

        AcademicYear activeYear = new AcademicYear();
        activeYear.setId(100L);
        activeYear.setLabel("2025-2026");
        activeYear.setActive(true);
        activeYear.setSchool(school);
        activeYear.setStartDate(LocalDate.of(2025, 9, 1));
        activeYear.setEndDate(LocalDate.of(2026, 6, 30));

        when(academicYearRepository.findAll()).thenReturn(List.of(activeYear));
        when(schoolContextService.scope(anyList())).thenAnswer(invocation -> {
            List<?> records = invocation.getArgument(0);
            return !records.isEmpty() && records.get(0) instanceof AcademicYear ? records : List.of();
        });
        when(schoolContextService.currentSchoolId()).thenReturn(5L);
        when(academicYearRepository.save(any(AcademicYear.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AcademicYearService service = new AcademicYearService(
                academicYearRepository,
                schoolInfoRepository,
                paymentRepository,
                expenseRepository,
                studentRepository,
                teacherRepository,
                absenceRepository,
                sanctionRepository,
                examRepository,
                lessonRepository,
                gradeRepository,
                eventRepository,
                scheduleItemRepository,
                schoolContextService,
                backupService
        );

        // Inject the mocked EntityManager through reflection or package-private field
        try {
            var field = AcademicYearService.class.getDeclaredField("entityManager");
            field.setAccessible(true);
            field.set(service, entityManager);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        service.closeCurrentYear();

        // 1. Automatic backup was triggered before closing
        verify(backupService, times(1)).triggerAutoBackupForSchool(5L);

        // Closed-year records are tagged but are not deleted before archive upload.
        verify(entityManager).createQuery(contains("UPDATE Payment"));
        verify(entityManager).createQuery(contains("UPDATE Expense"));
        verify(entityManager).createQuery(contains("UPDATE Grade"));
        verify(entityManager).createQuery(contains("UPDATE Exam"));
        verify(entityManager).createQuery(contains("UPDATE Absence"));
        verify(entityManager).createQuery(contains("UPDATE Sanction"));
        verify(entityManager).createQuery(contains("UPDATE Lesson"));
        verify(entityManager).createQuery(contains("UPDATE ScheduleItem"));
        verify(entityManager, never()).createQuery(contains("DELETE FROM"));

        assertThat(activeYear.isActive()).isFalse();
        assertThat(activeYear.getClosedAt()).isNotNull();
    }

    @Test
    void finalizationDeletesOnlyYearScopedRecordsAndAppropriateCleanupData() {
        AcademicYearRepository years = mock(AcademicYearRepository.class);
        SchoolInfoRepository schoolInfo = mock(SchoolInfoRepository.class);
        PaymentRepository payments = mock(PaymentRepository.class);
        ExpenseRepository expenses = mock(ExpenseRepository.class);
        StudentRepository students = mock(StudentRepository.class);
        TeacherRepository teachers = mock(TeacherRepository.class);
        AbsenceRepository absences = mock(AbsenceRepository.class);
        SanctionRepository sanctions = mock(SanctionRepository.class);
        ExamRepository exams = mock(ExamRepository.class);
        LessonRepository lessons = mock(LessonRepository.class);
        GradeRepository grades = mock(GradeRepository.class);
        EventRepository events = mock(EventRepository.class);
        ScheduleItemRepository schedules = mock(ScheduleItemRepository.class);
        SchoolContextService context = mock(SchoolContextService.class);
        BackupService backup = mock(BackupService.class);
        EntityManager entityManager = mock(EntityManager.class);
        Query query = mock(Query.class);

        School school = new School();
        school.setId(5L);
        AcademicYear closedYear = new AcademicYear();
        closedYear.setId(100L);
        closedYear.setSchool(school);
        closedYear.setStartDate(LocalDate.of(2025, 9, 1));
        closedYear.setEndDate(LocalDate.of(2026, 6, 30));
        when(years.findById(100L)).thenReturn(Optional.of(closedYear));
        when(context.currentSchoolId()).thenReturn(5L);
        when(entityManager.createQuery(anyString())).thenReturn(query);
        when(query.setParameter(anyString(), any())).thenReturn(query);
        when(query.executeUpdate()).thenReturn(1);

        AcademicYearService service = new AcademicYearService(years, schoolInfo, payments, expenses, students,
                teachers, absences, sanctions, exams, lessons, grades, events, schedules, context, backup);
        try {
            var field = AcademicYearService.class.getDeclaredField("entityManager");
            field.setAccessible(true);
            field.set(service, entityManager);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        service.finalizeClosedYearRecords(100L);

        ArgumentCaptor<String> queries = ArgumentCaptor.forClass(String.class);
        verify(entityManager, times(12)).createQuery(queries.capture());
        List<String> deleteQueries = queries.getAllValues();
        for (String entity : List.of("Payment", "Expense", "BulletinPublication", "Grade", "Exam",
                "Absence", "Sanction", "Lesson", "Event", "AppNotification")) {
            assertThat(deleteQueries).anySatisfy(sql -> {
                assertThat(sql).contains("DELETE FROM " + entity)
                        .contains("e.school.id = :schoolId")
                        .contains("e.academicYearId = :yearId");
            });
        }
        assertThat(deleteQueries).anySatisfy(sql -> assertThat(sql).contains("DELETE FROM ScheduleItem")
                .contains("s.school.id = :schoolId").contains("s.academicYearId = :yearId"));
        assertThat(deleteQueries).anySatisfy(sql -> assertThat(sql).contains("DELETE FROM DailyAttendanceQr")
                .contains("q.school.id = :schoolId")
                .contains("q.attendanceDate BETWEEN :startDate AND :endDate"));
        assertThat(deleteQueries).noneMatch(sql -> sql.contains("DELETE FROM Student")
                || sql.contains("DELETE FROM Teacher") || sql.contains("DELETE FROM Classroom")
                || sql.contains("DELETE FROM Subject") || sql.contains("DELETE FROM User")
                || sql.contains("DELETE FROM SchoolMembership")
                || sql.contains("DELETE FROM StaffDailyAttendance"));
    }
}
