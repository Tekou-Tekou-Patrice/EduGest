package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.DTO.AcademicYearDto;
import com.eduguest.Edu.Repository.AcademicYearRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.zip.GZIPInputStream;

@Service
public class YearArchiveService {
    private static final List<String> ARCHIVE_TYPES = List.of(
            "year_recap", "bulletins", "receipts", "year_data");
    private static final byte[] PDF_HEADER = "%PDF-".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    private static final byte[] PDF_EOF = "%%EOF".getBytes(java.nio.charset.StandardCharsets.US_ASCII);

    private final AcademicYearRepository academicYearRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final UserSecurityContextService userSecurityContextService;
    private final SchoolRepository schoolRepository;
    private final String platformAdminUsername;
    private final ObjectMapper objectMapper;
    private final Path archiveRoot;

    public YearArchiveService(AcademicYearRepository academicYearRepository,
                              AcademicYearService academicYearService,
                              SchoolContextService schoolContextService,
                              UserSecurityContextService userSecurityContextService,
                              SchoolRepository schoolRepository,
                              ObjectMapper objectMapper,
                              @Value("${edugest.platform.admin.username:}") String platformAdminUsername,
                              @Value("${edugest.archive-directory:./archives}") Path archiveDirectory) {
        this.academicYearRepository = academicYearRepository;
        this.academicYearService = academicYearService;
        this.schoolContextService = schoolContextService;
        this.userSecurityContextService = userSecurityContextService;
        this.schoolRepository = schoolRepository;
        this.objectMapper = objectMapper;
        this.platformAdminUsername = platformAdminUsername == null ? "" : platformAdminUsername.trim();
        this.archiveRoot = archiveDirectory.toAbsolutePath().normalize();
    }

    public List<String> list(Long yearId) {
        AcademicYear year = requireScopedClosedYear(yearId, false);
        return listFiles(year);
    }

    public List<String> listForPlatformAdmin(Long schoolId, Long yearId, String privateCode) {
        requirePlatformAdmin();
        School school = requireSchoolWithPrivateCode(schoolId, privateCode);
        return listFiles(requireClosedYearForSchool(school, yearId));
    }

    private List<String> listFiles(AcademicYear year) {
        Path directory = yearDirectory(year);
        List<String> files = new ArrayList<>();
        for (String type : ARCHIVE_TYPES) {
            Path file = archivePath(directory, type);
            if (Files.isRegularFile(file, LinkOption.NOFOLLOW_LINKS)) {
                files.add(type);
            }
        }
        if (Files.isRegularFile(finalizedPath(directory), LinkOption.NOFOLLOW_LINKS)) {
            files.add("data_purged");
        }
        return files;
    }

    public Path download(Long yearId, String type) {
        AcademicYear year = requireScopedClosedYear(yearId, false);
        return downloadFile(year, type);
    }

    public Path downloadForPlatformAdmin(Long schoolId, Long yearId, String type, String privateCode) {
        requirePlatformAdmin();
        School school = requireSchoolWithPrivateCode(schoolId, privateCode);
        return downloadFile(requireClosedYearForSchool(school, yearId), type);
    }

    private Path downloadFile(AcademicYear year, String type) {
        Path file = archivePath(yearDirectory(year), requireType(type));
        if (!Files.isRegularFile(file, LinkOption.NOFOLLOW_LINKS)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "PDF d'archive introuvable");
        }
        return file;
    }

    public void upload(Long yearId, String type, byte[] content, String contentType) throws IOException {
        AcademicYear year = requireScopedClosedYear(yearId, true);
        String safeType = requireType(type);
        if (Files.exists(finalizedPath(yearDirectory(year)), LinkOption.NOFOLLOW_LINKS)) {
            throw new IllegalStateException("Les archives d'une année déjà supprimée sont définitives.");
        }
        Path directory = yearDirectory(year);
        if ("year_data".equals(safeType)
                && !Files.exists(archivePath(directory, "year_data"), LinkOption.NOFOLLOW_LINKS)
                && List.of("year_recap", "bulletins", "receipts").stream()
                .allMatch(archiveType -> Files.isRegularFile(
                        archivePath(directory, archiveType), LinkOption.NOFOLLOW_LINKS))) {
            throw new IllegalStateException(
                    "Cette année possède déjà des PDF sans sauvegarde complète. "
                            + "Pour éviter de supprimer des données non sauvegardées, la suppression est bloquée.");
        }
        if (content == null || content.length == 0) {
            throw new IllegalArgumentException("Le fichier d'archive est requis");
        }
        if ("year_data".equals(safeType)) {
            if (contentType == null || !"application/gzip".equalsIgnoreCase(
                    contentType.split(";", 2)[0].trim())) {
                throw new IllegalArgumentException("L'archive complète doit être au format application/gzip");
            }
            validateCompressedBackup(content, year);
        } else {
            if (contentType == null || !"application/pdf".equalsIgnoreCase(
                    contentType.split(";", 2)[0].trim())) {
                throw new IllegalArgumentException("Le type du fichier doit être application/pdf");
            }
            validatePdf(content);
        }

        Files.createDirectories(directory);
        Path destination = archivePath(directory, safeType);
        Path stagingFile = directory.resolve("." + safeType + "-" + UUID.randomUUID() + ".upload");
        try {
            Files.write(stagingFile, content);
            try {
                Files.move(stagingFile, destination, StandardCopyOption.ATOMIC_MOVE,
                        StandardCopyOption.REPLACE_EXISTING);
            } catch (AtomicMoveNotSupportedException exception) {
                throw new IOException("Le stockage atomique des archives n'est pas pris en charge", exception);
            }
        } finally {
            Files.deleteIfExists(stagingFile);
        }
    }

    public synchronized void finalizeYear(Long yearId) {
        AcademicYear year = requireScopedClosedYear(yearId, true);
        Path directory = yearDirectory(year);
        if (Files.isRegularFile(finalizedPath(directory), LinkOption.NOFOLLOW_LINKS)) {
            return;
        }
        List<String> missing = ARCHIVE_TYPES.stream()
                .filter(type -> !Files.isRegularFile(archivePath(directory, type), LinkOption.NOFOLLOW_LINKS))
                .toList();
        if (!missing.isEmpty()) {
            throw new IllegalArgumentException("Ajoutez les trois PDF et l'archive complète avant la suppression. Fichiers manquants : "
                    + String.join(", ", missing));
        }
        academicYearService.finalizeClosedYearRecords(yearId);
        try {
            Files.createDirectories(directory);
            Files.createFile(finalizedPath(directory));
        } catch (IOException exception) {
            throw new IllegalStateException(
                    "Les données ont été supprimées, mais le statut de finalisation n'a pas pu être enregistré.",
                    exception);
        }
    }

    public List<AcademicYearDto> listRecapsForPlatformAdmin(Long schoolId, String privateCode) {
        requirePlatformAdmin();
        requireSchoolWithPrivateCode(schoolId, privateCode);
        return academicYearRepository.findBySchool_IdAndActiveFalseOrderByEndDateDesc(schoolId).stream()
                .map(academicYearService::toDto)
                .toList();
    }

    public void verifyPlatformAdminAccess() {
        requirePlatformAdmin();
    }

    private AcademicYear requireScopedClosedYear(Long yearId, boolean archiveManagement) {
        requireAuthorizedSchool(archiveManagement);
        if (yearId == null || yearId <= 0) {
            throw new IllegalArgumentException("Identifiant d'année scolaire invalide");
        }
        Long schoolId = schoolContextService.currentSchoolId();
        AcademicYear year = academicYearRepository.findById(yearId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Année scolaire introuvable"));
        if (schoolId == null || year.getSchool() == null || !schoolId.equals(year.getSchool().getId())) {
            throw new AccessDeniedException("Cette année scolaire appartient à une autre école");
        }
        if (year.isActive()) {
            throw new IllegalArgumentException("Les archives sont réservées aux années clôturées");
        }
        return year;
    }

    private AcademicYear requireClosedYearForSchool(School school, Long yearId) {
        if (yearId == null || yearId <= 0) {
            throw new IllegalArgumentException("Identifiant d'année scolaire invalide");
        }
        AcademicYear year = academicYearRepository.findById(yearId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Année scolaire introuvable"));
        if (year.getSchool() == null || !school.getId().equals(year.getSchool().getId())) {
            throw new AccessDeniedException("Cette année scolaire appartient à une autre école");
        }
        if (year.isActive()) {
            throw new IllegalArgumentException("Les archives sont réservées aux années clôturées");
        }
        return year;
    }

    private School requireSchoolWithPrivateCode(Long schoolId, String privateCode) {
        if (schoolId == null || schoolId <= 0 || privateCode == null || privateCode.isBlank()) {
            throw new IllegalArgumentException("Le code privé de l'école est requis");
        }
        School school = schoolRepository.findById(schoolId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "École introuvable"));
        String expectedCode = school.getCode();
        if (expectedCode == null || !constantTimeEquals(expectedCode.trim(), privateCode.trim())) {
            throw new AccessDeniedException("Code privé de l'école incorrect");
        }
        return school;
    }

    private void requirePlatformAdmin() {
        if (platformAdminUsername.isBlank()) {
            throw new AccessDeniedException("Le compte propriétaire de la plateforme n'est pas configuré.");
        }
        String username = userSecurityContextService.getCurrentUser()
                .map(user -> user.getUsername())
                .orElse(null);
        if (username == null || !platformAdminUsername.equalsIgnoreCase(username.trim())) {
            throw new AccessDeniedException("Accès réservé au compte propriétaire de la plateforme.");
        }
    }

    private boolean constantTimeEquals(String left, String right) {
        byte[] a = left.getBytes(StandardCharsets.UTF_8);
        byte[] b = right.getBytes(StandardCharsets.UTF_8);
        if (a.length != b.length) return false;
        int difference = 0;
        for (int i = 0; i < a.length; i++) difference |= a[i] ^ b[i];
        return difference == 0;
    }

    private void requireAuthorizedSchool(boolean archiveManagement) {
        if (userSecurityContextService.getCurrentUserId() == null) {
            throw new AccessDeniedException("Authentification requise.");
        }
        if (archiveManagement) {
            userSecurityContextService.requireAnyRole(UserRole.FONDATEUR, UserRole.PROVISEUR);
        } else {
            userSecurityContextService.requireAnyRole(
                    UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE);
        }
        if (schoolContextService.currentSchoolId() == null) {
            throw new AccessDeniedException("Une école active est requise.");
        }
    }

    private Path yearDirectory(AcademicYear year) {
        Long schoolId = year.getSchool().getId();
        Path directory = archiveRoot.resolve(Long.toString(schoolId))
                .resolve(Long.toString(year.getId())).normalize();
        if (!directory.startsWith(archiveRoot)) {
            throw new IllegalArgumentException("Chemin d'archive invalide");
        }
        return directory;
    }

    private Path archivePath(Path directory, String type) {
        String extension = "year_data".equals(type) ? ".json.gz" : ".pdf";
        Path file = directory.resolve(type + extension).normalize();
        if (!file.startsWith(archiveRoot)) {
            throw new IllegalArgumentException("Chemin d'archive invalide");
        }
        return file;
    }

    private Path finalizedPath(Path directory) {
        Path marker = directory.resolve(".data-purged").normalize();
        if (!marker.startsWith(archiveRoot)) {
            throw new IllegalArgumentException("Chemin d'archive invalide");
        }
        return marker;
    }

    private void validateCompressedBackup(byte[] content, AcademicYear year) {
        try (GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(content));
             ByteArrayOutputStream decompressed = new ByteArrayOutputStream()) {
            gzip.transferTo(decompressed);
            JsonNode json = objectMapper.readTree(decompressed.toByteArray());
            if (json == null || !json.path("schoolId").canConvertToLong()
                    || json.path("schoolId").asLong() != year.getSchool().getId()
                    || !"academic-year".equals(json.path("archiveType").asText())
                    || json.path("academicYearId").asLong(-1) != year.getId()
                    || !json.hasNonNull("version")
                    || !json.has("academicYears")
                    || !json.has("classes")
                    || !json.has("subjects")
                    || !json.has("teachers")
                    || !json.has("students")
                    || !json.has("exams")
                    || !json.has("grades")
                    || !json.has("absences")
                    || !json.has("sanctions")
                    || !json.has("lessons")
                    || !json.has("schedules")
                    || !json.has("payments")
                    || !json.has("expenses")
                    || !json.has("publications")
                    || !json.has("events")
                    || !json.has("notifications")
                    || !json.has("dailyAttendanceQrs")) {
                throw new IllegalArgumentException("L'archive compressée ne contient pas une sauvegarde complète de cette école.");
            }
            JsonNode archivedYear = null;
            for (JsonNode candidate : json.path("academicYears")) {
                if (candidate.path("id").asLong(-1) == year.getId()) {
                    archivedYear = candidate;
                    break;
                }
            }
            if (archivedYear == null || archivedYear.path("active").asBoolean(true)) {
                throw new IllegalArgumentException(
                        "La sauvegarde ne contient pas l'année scolaire clôturée ciblée.");
            }
            requireCount(json, "exams", "examCount", year);
            requireCount(json, "lessons", "lessonCount", year);
            requireCount(json, "absences", "absenceCount", year);
            requireCount(json, "sanctions", "sanctionCount", year);
            requireAmount(json, "payments", "totalRevenue", year);
            requireAmount(json, "expenses", "totalExpenses", year);
        } catch (IOException exception) {
            throw new IllegalArgumentException("L'archive compressée est invalide ou incomplète.", exception);
        }
    }

    private void requireCount(JsonNode backup, String collectionName, String countName, AcademicYear year) {
        long expected = yearCount(year, countName);
        long actual = 0;
        for (JsonNode record : backup.path(collectionName)) {
            if (record.path("academicYearId").asLong(-1) == year.getId()) actual++;
        }
        if (actual < expected) {
            throw new IllegalArgumentException(
                    "La sauvegarde ne contient pas toutes les données annuelles (" + collectionName + ").");
        }
    }

    private void requireAmount(JsonNode backup, String collectionName, String amountName, AcademicYear year) {
        double expected = yearAmount(year, amountName);
        double actual = 0;
        for (JsonNode record : backup.path(collectionName)) {
            if (record.path("academicYearId").asLong(-1) == year.getId()) {
                actual += record.path("amount").asDouble(0);
            }
        }
        if (Math.abs(actual - expected) > 0.01) {
            throw new IllegalArgumentException(
                    "La sauvegarde ne correspond pas aux totaux annuels (" + collectionName + ").");
        }
    }

    private long yearCount(AcademicYear year, String countName) {
        return switch (countName) {
            case "examCount" -> year.getExamCount() == null ? 0 : year.getExamCount();
            case "lessonCount" -> year.getLessonCount() == null ? 0 : year.getLessonCount();
            case "absenceCount" -> year.getAbsenceCount() == null ? 0 : year.getAbsenceCount();
            case "sanctionCount" -> year.getSanctionCount() == null ? 0 : year.getSanctionCount();
            default -> throw new IllegalArgumentException("Compteur annuel inconnu");
        };
    }

    private double yearAmount(AcademicYear year, String amountName) {
        return switch (amountName) {
            case "totalRevenue" -> year.getTotalRevenue() == null ? 0 : year.getTotalRevenue();
            case "totalExpenses" -> year.getTotalExpenses() == null ? 0 : year.getTotalExpenses();
            default -> throw new IllegalArgumentException("Total annuel inconnu");
        };
    }

    private String requireType(String type) {
        if (type == null || !ARCHIVE_TYPES.contains(type.toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("Type d'archive invalide");
        }
        return type.toLowerCase(Locale.ROOT);
    }

    private void validatePdf(byte[] content) {
        if (content.length < PDF_HEADER.length + PDF_EOF.length) {
            throw new IllegalArgumentException("Le fichier ne contient pas un PDF valide");
        }
        for (int i = 0; i < PDF_HEADER.length; i++) {
            if (content[i] != PDF_HEADER[i]) {
                throw new IllegalArgumentException("Le fichier ne contient pas un PDF valide");
            }
        }
        int eofStart = Math.max(0, content.length - 1024);
        if (!contains(content, PDF_EOF, eofStart)) {
            throw new IllegalArgumentException("Le fichier PDF est incomplet ou invalide");
        }
    }

    private boolean contains(byte[] content, byte[] sequence, int start) {
        for (int i = start; i <= content.length - sequence.length; i++) {
            boolean matches = true;
            for (int j = 0; j < sequence.length; j++) {
                if (content[i + j] != sequence[j]) {
                    matches = false;
                    break;
                }
            }
            if (matches) return true;
        }
        return false;
    }
}
