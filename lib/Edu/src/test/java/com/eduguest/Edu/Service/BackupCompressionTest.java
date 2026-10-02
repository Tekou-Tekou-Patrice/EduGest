package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.*;
import java.util.zip.GZIPInputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class BackupCompressionTest {

    @Test
    void compressedSchoolDataProducesValidGzipBytes() throws Exception {
        SchoolRepository schoolRepository = mock(SchoolRepository.class);
        SchoolInfoRepository schoolInfoRepository = mock(SchoolInfoRepository.class);
        ClassroomRepository classroomRepository = mock(ClassroomRepository.class);
        SubjectRepository subjectRepository = mock(SubjectRepository.class);
        TeacherRepository teacherRepository = mock(TeacherRepository.class);
        StudentRepository studentRepository = mock(StudentRepository.class);
        ExamRepository examRepository = mock(ExamRepository.class);
        GradeRepository gradeRepository = mock(GradeRepository.class);
        AbsenceRepository absenceRepository = mock(AbsenceRepository.class);
        SanctionRepository sanctionRepository = mock(SanctionRepository.class);
        LessonRepository lessonRepository = mock(LessonRepository.class);
        ScheduleItemRepository scheduleItemRepository = mock(ScheduleItemRepository.class);
        PaymentRepository paymentRepository = mock(PaymentRepository.class);
        ExpenseRepository expenseRepository = mock(ExpenseRepository.class);
        BulletinPublicationRepository publicationRepository = mock(BulletinPublicationRepository.class);
        AuditLogRepository auditLogRepository = mock(AuditLogRepository.class);
        AcademicYearRepository academicYearRepository = mock(AcademicYearRepository.class);
        EventRepository eventRepository = mock(EventRepository.class);
        AppNotificationRepository appNotificationRepository = mock(AppNotificationRepository.class);
        DailyAttendanceQrRepository dailyAttendanceQrRepository = mock(DailyAttendanceQrRepository.class);
        SchoolContextService schoolContextService = mock(SchoolContextService.class);
        AuditLogService auditLogService = mock(AuditLogService.class);
        ObjectMapper objectMapper = new ObjectMapper();

        School school = new School();
        school.setId(10L);
        school.setName("Institut Test");

        when(schoolRepository.findById(10L)).thenReturn(Optional.of(school));
        when(schoolContextService.scope(anyList())).thenAnswer(invocation -> invocation.getArgument(0));
        AcademicYear year = new AcademicYear();
        year.setId(22L);
        year.setSchool(school);
        year.setActive(false);
        year.setStartDate(LocalDate.of(2025, 9, 1));
        year.setEndDate(LocalDate.of(2026, 6, 30));
        when(academicYearRepository.findById(22L)).thenReturn(Optional.of(year));

        BackupService service = new BackupService(
                schoolRepository,
                schoolInfoRepository,
                classroomRepository,
                subjectRepository,
                teacherRepository,
                studentRepository,
                examRepository,
                gradeRepository,
                absenceRepository,
                sanctionRepository,
                lessonRepository,
                scheduleItemRepository,
                paymentRepository,
                expenseRepository,
                publicationRepository,
                auditLogRepository,
                academicYearRepository,
                eventRepository,
                appNotificationRepository,
                dailyAttendanceQrRepository,
                schoolContextService,
                auditLogService,
                objectMapper
        );

        byte[] compressed = service.getCompressedSchoolData(10L);

        // GZIP magic header: 0x1f, 0x8b
        assertThat(compressed.length).isGreaterThan(2);
        assertThat(compressed[0]).isEqualTo((byte) 0x1f);
        assertThat(compressed[1]).isEqualTo((byte) 0x8b);

        // Decompress and verify content
        ByteArrayOutputStream decompressed = new ByteArrayOutputStream();
        try (GZIPInputStream gzis = new GZIPInputStream(new ByteArrayInputStream(compressed))) {
            gzis.transferTo(decompressed);
        }
        String json = decompressed.toString(StandardCharsets.UTF_8);
        assertThat(json).contains("\"schoolName\":\"Institut Test\"");
        assertThat(json).contains("\"version\":\"2.0\"");

        byte[] yearArchive = service.getCompressedAcademicYearData(10L, 22L);
        try (GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(yearArchive))) {
            var yearJson = objectMapper.readTree(gzip);
            assertThat(yearJson.path("archiveType").asText()).isEqualTo("academic-year");
            assertThat(yearJson.path("academicYearId").asLong()).isEqualTo(22L);
            assertThat(yearJson.path("academicYears")).hasSize(1);
            assertThat(yearJson.has("dailyAttendanceQrs")).isTrue();
            assertThat(yearJson.has("auditLogs")).isFalse();
        }
    }
}
