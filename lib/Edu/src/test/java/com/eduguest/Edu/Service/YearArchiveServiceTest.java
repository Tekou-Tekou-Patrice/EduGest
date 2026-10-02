package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.AcademicYearRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.zip.GZIPOutputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class YearArchiveServiceTest {
    private AcademicYearRepository yearRepository;
    private AcademicYearService academicYearService;
    private SchoolContextService schoolContextService;
    private UserSecurityContextService userSecurityContextService;
    private SchoolRepository schoolRepository;
    private YearArchiveService archiveService;
    private AcademicYear year;
    private Path archiveRoot;

    @BeforeEach
    void setUp() throws IOException {
        archiveRoot = Path.of("target", "year-archive-tests", UUID.randomUUID().toString())
                .toAbsolutePath().normalize();
        Files.createDirectories(archiveRoot);

        yearRepository = mock(AcademicYearRepository.class);
        academicYearService = mock(AcademicYearService.class);
        schoolContextService = mock(SchoolContextService.class);
        userSecurityContextService = mock(UserSecurityContextService.class);
        schoolRepository = mock(SchoolRepository.class);
        when(schoolContextService.currentSchoolId()).thenReturn(12L);
        when(userSecurityContextService.getCurrentUserId()).thenReturn(7L);
        when(userSecurityContextService.hasAnyRole(any(UserRole[].class))).thenReturn(true);

        School school = new School();
        school.setId(12L);
        school.setCode("test-private-code");
        when(schoolRepository.findById(12L)).thenReturn(Optional.of(school));
        when(schoolContextService.currentSchool()).thenReturn(school);
        User owner = new User();
        owner.setUsername("TEKOU PATRICE");
        when(userSecurityContextService.getCurrentUser()).thenReturn(Optional.of(owner));
        year = new AcademicYear();
        year.setId(34L);
        year.setSchool(school);
        year.setActive(false);
        year.setTotalRevenue(0.0);
        year.setTotalExpenses(0.0);
        year.setExamCount(0);
        year.setLessonCount(0);
        year.setAbsenceCount(0);
        year.setSanctionCount(0);
        when(yearRepository.findById(34L)).thenReturn(Optional.of(year));

        archiveService = new YearArchiveService(yearRepository, academicYearService, schoolContextService,
                userSecurityContextService, schoolRepository, new ObjectMapper(),
                "TEKOU PATRICE", archiveRoot);
    }

    @AfterEach
    void cleanUp() throws IOException {
        if (Files.exists(archiveRoot)) {
            try (var paths = Files.walk(archiveRoot)) {
                for (Path path : paths.sorted(Comparator.reverseOrder()).toList()) {
                    Files.deleteIfExists(path);
                }
            }
        }
    }

    @Test
    void refusesFinalizationUntilAllThreePdfArchivesHaveBeenStored() throws Exception {
        assertThatThrownBy(() -> archiveService.finalizeYear(34L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("year_recap")
                .hasMessageContaining("bulletins")
                .hasMessageContaining("receipts")
                .hasMessageContaining("year_data");
        verify(academicYearService, never()).finalizeClosedYearRecords(any());

        archiveService.upload(34L, "year_data", compressedBackup(12L), "application/gzip");
        assertThatThrownBy(() -> archiveService.finalizeYear(34L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("year_recap");
        for (String type : List.of("year_recap", "bulletins", "receipts")) {
            archiveService.upload(34L, type, pdfBytes(), "application/pdf");
        }

        archiveService.finalizeYear(34L);
        verify(academicYearService).finalizeClosedYearRecords(34L);
        assertThat(archiveService.list(34L))
                .containsExactly("year_recap", "bulletins", "receipts", "year_data", "data_purged");
        assertThat(Files.readAllBytes(
                archiveService.download(34L, "year_recap")))
                .startsWith("%PDF-".getBytes(java.nio.charset.StandardCharsets.US_ASCII));
        assertThat(Files.readAllBytes(
                archiveService.download(34L, "year_data")))
                .startsWith(new byte[] {(byte) 0x1f, (byte) 0x8b});
        assertThat(archiveService.listForPlatformAdmin(12L, 34L, "test-private-code"))
                .containsExactly("year_recap", "bulletins", "receipts", "year_data", "data_purged");
        archiveService.finalizeYear(34L);
        verify(academicYearService, times(1)).finalizeClosedYearRecords(34L);
        assertThatThrownBy(() -> archiveService.upload(
                34L, "receipts", pdfBytes(), "application/pdf"))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void rejectsUnapprovedTypesAndNonPdfUploads() {
        assertThatThrownBy(() -> archiveService.upload(34L, "../other", pdfBytes(), "application/pdf"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> archiveService.upload(34L, "bulletins",
                "not a pdf".getBytes(), "application/pdf"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> archiveService.upload(34L, "bulletins",
                pdfBytes(), "text/plain"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> archiveService.upload(34L, "year_data",
                pdfBytes(), "application/gzip"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> archiveService.upload(34L, "year_data",
                compressedBackup(99L), "application/gzip"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("sauvegarde complète");
    }

    @Test
    void refusesToDeleteLegacyPdfOnlyYearsWithoutAFullSnapshot() throws Exception {
        for (String type : List.of("year_recap", "bulletins", "receipts")) {
            archiveService.upload(34L, type, pdfBytes(), "application/pdf");
        }
        assertThatThrownBy(() -> archiveService.upload(
                34L, "year_data", compressedBackup(12L), "application/gzip"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("sans sauvegarde complète");
        verify(academicYearService, never()).finalizeClosedYearRecords(any());
    }

    @Test
    void rejectsClosedYearFromAnotherSchool() {
        when(schoolContextService.currentSchoolId()).thenReturn(99L);
        assertThatThrownBy(() -> archiveService.list(34L))
                .isInstanceOf(org.springframework.security.access.AccessDeniedException.class);
    }

    @Test
    void rejectsArchiveOperationsForAnActiveYear() {
        year.setActive(true);
        assertThatThrownBy(() -> archiveService.list(34L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("clôturées");
    }

    @Test
    void platformArchivesRequireDedicatedOwnerAndSchoolCode() {
        assertThatThrownBy(() -> archiveService.listForPlatformAdmin(12L, 34L, "wrong-code"))
                .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                .hasMessageContaining("Code privé");
        verify(yearRepository, never()).findById(any());

        User schoolFounder = new User();
        schoolFounder.setUsername("school-founder");
        when(userSecurityContextService.getCurrentUser()).thenReturn(Optional.of(schoolFounder));
        assertThatThrownBy(() ->
                archiveService.listForPlatformAdmin(12L, 34L, "test-private-code"))
                .isInstanceOf(org.springframework.security.access.AccessDeniedException.class);
        verify(yearRepository, never()).findById(any());
    }

    private byte[] pdfBytes() {
        return "%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF\n".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    }

    private byte[] compressedBackup(long schoolId) throws IOException {
        Map<String, Object> backup = new LinkedHashMap<>();
        backup.put("version", "2.0");
        backup.put("archiveType", "academic-year");
        backup.put("schoolId", schoolId);
        backup.put("academicYearId", 34L);
        Map<String, Object> yearData = new LinkedHashMap<>();
        yearData.put("id", 34L);
        yearData.put("active", false);
        backup.put("academicYears", List.of(yearData));
        for (String key : List.of(
                "classes", "subjects", "teachers", "students", "exams",
                "grades", "absences", "sanctions", "lessons", "schedules", "payments",
                "expenses", "publications", "events", "notifications", "dailyAttendanceQrs",
                "auditLogs")) {
            backup.put(key, List.of());
        }
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (GZIPOutputStream gzip = new GZIPOutputStream(bytes)) {
            gzip.write(new ObjectMapper().writeValueAsBytes(backup));
        }
        return bytes.toByteArray();
    }
}
