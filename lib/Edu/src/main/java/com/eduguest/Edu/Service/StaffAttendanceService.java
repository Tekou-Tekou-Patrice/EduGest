package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.StaffAttendanceQrDto;
import com.eduguest.Edu.DTO.StaffAttendanceReportDto;
import com.eduguest.Edu.DTO.StaffAttendanceScanDto;
import com.eduguest.Edu.Entity.*;
import com.eduguest.Edu.Repository.DailyAttendanceQrRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.eduguest.Edu.Repository.StaffDailyAttendanceRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class StaffAttendanceService {
    private static final LocalTime QR_AVAILABLE_AT = LocalTime.of(6, 0);
    private static final Set<UserRole> SCAN_ROLES = Set.of(
            UserRole.ENSEIGNANT, UserRole.SURVEILLANT,
            UserRole.SURVEILLANT_GENERAL, UserRole.CENSEUR);
    private static final Set<UserRole> QR_ROLES = Set.of(
            UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE,
            UserRole.SURVEILLANT_GENERAL);
    private static final Set<UserRole> REPORT_ROLES = Set.of(
            UserRole.FONDATEUR, UserRole.PROVISEUR, UserRole.SECRETAIRE,
            UserRole.SURVEILLANT_GENERAL, UserRole.CENSEUR);

    private final DailyAttendanceQrRepository qrRepository;
    private final StaffDailyAttendanceRepository attendanceRepository;
    private final SchoolRepository schoolRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final SchoolContextService schoolContextService;
    private final UserSecurityContextService securityContextService;
    private final byte[] qrSecret;
    private final ZoneId zoneId;
    private final Clock clock;

    @Autowired
    public StaffAttendanceService(
            DailyAttendanceQrRepository qrRepository,
            StaffDailyAttendanceRepository attendanceRepository,
            SchoolRepository schoolRepository,
            SchoolMembershipRepository membershipRepository,
            SchoolContextService schoolContextService,
            UserSecurityContextService securityContextService,
            @Value("${edugest.attendance.qr-secret:${edugest.security.token-secret}}") String qrSecret,
            @Value("${edugest.attendance.time-zone:Africa/Douala}") String timeZone) {
        this(qrRepository, attendanceRepository, schoolRepository, membershipRepository,
                schoolContextService, securityContextService, qrSecret, timeZone, Clock.systemUTC());
    }

    StaffAttendanceService(
            DailyAttendanceQrRepository qrRepository,
            StaffDailyAttendanceRepository attendanceRepository,
            SchoolRepository schoolRepository,
            SchoolMembershipRepository membershipRepository,
            SchoolContextService schoolContextService,
            UserSecurityContextService securityContextService,
            String qrSecret,
            String timeZone,
            Clock clock) {
        this.qrRepository = qrRepository;
        this.attendanceRepository = attendanceRepository;
        this.schoolRepository = schoolRepository;
        this.membershipRepository = membershipRepository;
        this.schoolContextService = schoolContextService;
        this.securityContextService = securityContextService;
        if (qrSecret == null || qrSecret.length() < 32) {
            throw new IllegalStateException("edugest.attendance.qr-secret doit contenir au moins 32 caractères.");
        }
        this.qrSecret = qrSecret.getBytes(StandardCharsets.UTF_8);
        this.zoneId = ZoneId.of(timeZone);
        this.clock = clock;
    }

    @Scheduled(cron = "0 0 6 * * *", zone = "${edugest.attendance.time-zone:Africa/Douala}")
    @Transactional
    public void generateDailyQrCodes() {
        LocalDate today = LocalDate.now(clock.withZone(zoneId));
        LocalDateTime now = LocalDateTime.now(clock.withZone(zoneId));
        for (School school : schoolRepository.findAll().stream().filter(School::isActive).toList()) {
            ensureQrExists(school, today, now);
        }
    }

    @Transactional
    public StaffAttendanceQrDto getTodayQr() {
        requireRole(QR_ROLES);
        LocalDateTime now = LocalDateTime.now(clock.withZone(zoneId));
        if (now.toLocalTime().isBefore(QR_AVAILABLE_AT)) {
            throw new IllegalArgumentException("Le QR du jour sera disponible à partir de 6 h.");
        }
        School school = requireCurrentSchool();
        DailyAttendanceQr qr = ensureQrExists(school, now.toLocalDate(), now);
        return new StaffAttendanceQrDto(
                qr.getAttendanceDate(),
                school.getName(),
                createToken(school.getId(), qr.getAttendanceDate()));
    }

    @Transactional
    public StaffAttendanceScanDto scan(String token) {
        requireRole(SCAN_ROLES);
        if (token == null || token.isBlank() || token.length() > 200) {
            throw new IllegalArgumentException("QR code invalide.");
        }
        LocalDateTime now = LocalDateTime.now(clock.withZone(zoneId));
        if (now.toLocalTime().isBefore(QR_AVAILABLE_AT)) {
            throw new IllegalArgumentException("Le pointage est disponible à partir de 6 h.");
        }
        School school = requireCurrentSchool();
        String tokenHash = sha256(token.trim());
        DailyAttendanceQr qr = qrRepository.findForUpdate(
                        school.getId(), now.toLocalDate(), tokenHash)
                .orElseThrow(() -> new IllegalArgumentException("QR code invalide ou expiré."));

        User user = securityContextService.getCurrentUser()
                .orElseThrow(() -> new AccessDeniedException("Utilisateur inactif ou non connecté."));
        SchoolMembership membership = membershipRepository
                .findByUserIdAndSchoolId(user.getId(), school.getId())
                .filter(SchoolMembership::isActive)
                .orElseThrow(() -> new AccessDeniedException("Aucune adhésion active dans cette école."));
        if (!SCAN_ROLES.contains(membership.getRole())) {
            throw new AccessDeniedException("Votre rôle ne permet pas le pointage par QR.");
        }

        StaffDailyAttendance attendance = attendanceRepository
                .findBySchoolIdAndUserIdAndAttendanceDate(school.getId(), user.getId(), qr.getAttendanceDate())
                .orElse(null);
        if (attendance == null) {
            attendance = new StaffDailyAttendance();
            attendance.setSchool(school);
            attendance.setUser(user);
            attendance.setAttendanceDate(qr.getAttendanceDate());
            attendance.setCheckInAt(now);
            attendanceRepository.save(attendance);
            return new StaffAttendanceScanDto(
                    "ARRIVAL", now, null, null, monthlyTotalMinutes(school, user, now.toLocalDate()));
        }
        if (attendance.getCheckOutAt() != null) {
            throw new IllegalArgumentException("Les deux pointages de la journée ont déjà été enregistrés.");
        }
        if (now.isBefore(attendance.getCheckInAt())) {
            throw new IllegalArgumentException("L'heure de départ ne peut pas précéder l'heure d'arrivée.");
        }
        attendance.setCheckOutAt(now);
        attendanceRepository.save(attendance);
        long durationMinutes = java.time.Duration.between(attendance.getCheckInAt(), now).toMinutes();
        return new StaffAttendanceScanDto(
                "DEPARTURE",
                attendance.getCheckInAt(),
                now,
                durationMinutes,
                monthlyTotalMinutes(school, user, now.toLocalDate()));
    }

    private long monthlyTotalMinutes(School school, User user, LocalDate date) {
        LocalDate monthStart = date.withDayOfMonth(1);
        LocalDate nextMonth = monthStart.plusMonths(1);
        return attendanceRepository
                .findBySchoolIdAndUserIdAndAttendanceDateGreaterThanEqualAndAttendanceDateLessThan(
                        school.getId(), user.getId(), monthStart, nextMonth)
                .stream()
                .filter(record -> record.getCheckOutAt() != null)
                .mapToLong(record -> java.time.Duration.between(
                        record.getCheckInAt(), record.getCheckOutAt()).toMinutes())
                .sum();
    }

    @Transactional
    public List<StaffAttendanceReportDto> getMonthlyReport(YearMonth month) {
        requireRole(REPORT_ROLES);
        School school = requireCurrentSchool();
        LocalDate start = month.atDay(1);
        LocalDate end = month.plusMonths(1).atDay(1);
        List<StaffDailyAttendance> records = attendanceRepository
                .findBySchoolIdAndAttendanceDateGreaterThanEqualAndAttendanceDateLessThanOrderByAttendanceDateDescCheckInAtDesc(
                        school.getId(), start, end);
        Map<Long, UserRole> rolesByUserId = membershipRepository
                .findBySchoolIdAndActiveTrueOrderByUser_FullName(school.getId()).stream()
                .collect(Collectors.toMap(membership -> membership.getUser().getId(),
                        SchoolMembership::getRole, (first, ignored) -> first));

        return records.stream()
                .filter(record -> rolesByUserId.containsKey(record.getUser().getId())
                        && SCAN_ROLES.contains(rolesByUserId.get(record.getUser().getId())))
                .map(record -> {
                    LocalDateTime checkOut = record.getCheckOutAt();
                    Long duration = checkOut == null ? null
                            : java.time.Duration.between(record.getCheckInAt(), checkOut).toMinutes();
                    return new StaffAttendanceReportDto(
                            record.getUser().getId(),
                            displayName(record.getUser()),
                            rolesByUserId.get(record.getUser().getId()).toValue(),
                            record.getAttendanceDate(),
                            record.getCheckInAt(),
                            checkOut,
                            duration);
                }).toList();
    }

    private DailyAttendanceQr ensureQrExists(School school, LocalDate date, LocalDateTime generatedAt) {
        return qrRepository.findBySchoolIdAndAttendanceDate(school.getId(), date)
                .orElseGet(() -> {
                    DailyAttendanceQr qr = new DailyAttendanceQr();
                    qr.setSchool(school);
                    qr.setAttendanceDate(date);
                    qr.setTokenHash(sha256(createToken(school.getId(), date)));
                    qr.setGeneratedAt(generatedAt);
                    return qrRepository.save(qr);
                });
    }

    private String createToken(Long schoolId, LocalDate date) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(qrSecret, "HmacSHA256"));
            byte[] signed = mac.doFinal(("edugest-staff-attendance|" + schoolId + "|" + date)
                    .getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(signed);
        } catch (Exception ex) {
            throw new IllegalStateException("Impossible de générer le QR de pointage.", ex);
        }
    }

    private String sha256(String value) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("Impossible de vérifier le QR de pointage.", ex);
        }
    }

    private School requireCurrentSchool() {
        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId == null) {
            throw new AccessDeniedException("Aucune école active n'est sélectionnée.");
        }
        return schoolRepository.findById(schoolId)
                .filter(School::isActive)
                .orElseThrow(() -> new AccessDeniedException("École inactive ou introuvable."));
    }

    private void requireRole(Set<UserRole> allowedRoles) {
        UserRole role = securityContextService.getCurrentRole();
        if (role == null || !allowedRoles.contains(role)) {
            throw new AccessDeniedException("Votre rôle ne permet pas cette opération.");
        }
    }

    private String displayName(User user) {
        return user.getFullName() != null && !user.getFullName().isBlank()
                ? user.getFullName() : user.getUsername();
    }
}