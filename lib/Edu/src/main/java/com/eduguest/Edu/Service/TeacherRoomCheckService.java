package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.TeacherRoomCheckDto;
import com.eduguest.Edu.Entity.TeacherRoomCheck;
import com.eduguest.Edu.Entity.ScheduleItem;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import com.eduguest.Edu.Repository.TeacherRoomCheckRepository;
import com.eduguest.Edu.Repository.UserRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Entity.UserRole;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class TeacherRoomCheckService {
    private static final ZoneId SCHOOL_TIME_ZONE = ZoneId.of("Africa/Douala");
    private static final Set<UserRole> ROOM_CHECK_ROLES = Set.of(
            UserRole.FONDATEUR,
            UserRole.PROVISEUR,
            UserRole.SURVEILLANT_GENERAL,
            UserRole.SURVEILLANT);

    private final TeacherRoomCheckRepository repository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final ScheduleItemRepository scheduleRepository;
    private final AppNotificationService notificationService;
    private final UserRepository userRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final UserSecurityContextService securityContextService;
    private final Clock clock;

    @org.springframework.beans.factory.annotation.Autowired
    public TeacherRoomCheckService(
            TeacherRoomCheckRepository repository,
            AcademicYearService academicYearService,
            SchoolContextService schoolContextService,
            ScheduleItemRepository scheduleRepository,
            AppNotificationService notificationService,
            UserRepository userRepository,
            SchoolMembershipRepository membershipRepository,
            UserSecurityContextService securityContextService) {
        this(repository, academicYearService, schoolContextService, scheduleRepository,
                notificationService, userRepository, membershipRepository,
                securityContextService, Clock.systemUTC());
    }

    TeacherRoomCheckService(
            TeacherRoomCheckRepository repository,
            AcademicYearService academicYearService,
            SchoolContextService schoolContextService,
            ScheduleItemRepository scheduleRepository,
            AppNotificationService notificationService,
            UserRepository userRepository,
            SchoolMembershipRepository membershipRepository,
            UserSecurityContextService securityContextService,
            Clock clock) {
        this.repository = repository;
        this.academicYearService = academicYearService;
        this.schoolContextService = schoolContextService;
        this.scheduleRepository = scheduleRepository;
        this.notificationService = notificationService;
        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
        this.securityContextService = securityContextService;
        this.clock = clock;
    }

    @Transactional
    public List<TeacherRoomCheckDto> getChecks(LocalDate date) {
        academicYearService.autoCloseIfDue();
        return schoolContextService.scope(repository.findByCheckDateOrderByCheckedAtDesc(date))
                .stream()
                .filter(check -> academicYearService.filterCurrentYear(
                        List.of(check), TeacherRoomCheck::getAcademicYearId).size() == 1)
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public List<TeacherRoomCheckDto> getTeacherAbsences(String teacherId) {
        Long userId = securityContextService.getCurrentUserId();
        Long schoolId = schoolContextService.currentSchoolId();
        if (userId == null || schoolId == null || !userId.toString().equals(teacherId)
                || membershipRepository.findByUserIdAndSchoolId(userId, schoolId)
                .filter(SchoolMembership::isActive)
                .map(SchoolMembership::getRole)
                .filter(role -> role == UserRole.ENSEIGNANT)
                .isEmpty()) {
            throw new AccessDeniedException("Vous ne pouvez consulter que vos propres absences.");
        }
        return schoolContextService.scope(repository.findByTeacherIdAndPresentFalseOrderByCheckedAtDesc(teacherId))
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public TeacherRoomCheckDto saveCheck(TeacherRoomCheckDto dto) {
        Long userId = securityContextService.getCurrentUserId();
        Long schoolId = schoolContextService.currentSchoolId();
        if (userId == null || schoolId == null) {
            throw new AccessDeniedException("Authentification et école active requises.");
        }
        SchoolMembership verifierMembership = membershipRepository
                .findByUserIdAndSchoolId(userId, schoolId)
                .filter(SchoolMembership::isActive)
                .orElseThrow(() -> new AccessDeniedException("Aucune adhésion active dans cette école."));
        UserRole verifierRole = verifierMembership.getRole();
        if (!ROOM_CHECK_ROLES.contains(verifierRole)) {
            throw new AccessDeniedException(
                    "Seuls le proviseur et le personnel de surveillance peuvent contrôler les présences en salle.");
        }
        if (dto.getScheduleItemId() == null) {
            throw new IllegalArgumentException("Le créneau est obligatoire");
        }
        if (dto.getCheckDate() == null) {
            throw new IllegalArgumentException("La date est obligatoire");
        }
        ScheduleItem schedule = scheduleRepository.findById(dto.getScheduleItemId())
                .filter(item -> item.getSchool() != null
                        && Objects.equals(item.getSchool().getId(), schoolId))
                .filter(item -> !item.isBreak())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Le créneau est introuvable dans l’école sélectionnée."));
        if (!schedule.getDay().equals(dayName(dto.getCheckDate()))) {
            throw new IllegalArgumentException("Le créneau ne correspond pas à la date choisie.");
        }
        if (dto.getCheckDate().isAfter(LocalDate.now(clock.withZone(SCHOOL_TIME_ZONE)))) {
            throw new IllegalArgumentException("Un contrôle ne peut pas être enregistré dans le futur.");
        }
        if (dto.getCheckDate().equals(LocalDate.now(clock.withZone(SCHOOL_TIME_ZONE)))) {
            LocalTime now = LocalTime.now(clock.withZone(SCHOOL_TIME_ZONE));
            LocalTime startsAt = parseTime(schedule.getStartTime());
            LocalTime endsAt = parseTime(schedule.getEndTime());
            if (now.isBefore(startsAt) || now.isAfter(endsAt)) {
                throw new IllegalArgumentException(
                        "Le contrôle doit être effectué pendant l’heure de cours prévue.");
            }
        }

        TeacherRoomCheck check = repository
                .findByScheduleItemDateAndSchool(dto.getScheduleItemId(), dto.getCheckDate(), schoolId)
                .orElseGet(TeacherRoomCheck::new);
        boolean wasAbsent = check.getId() != null && !check.isPresent();
        check.setScheduleItemId(dto.getScheduleItemId());
        check.setCheckDate(dto.getCheckDate());
        check.setPresent(dto.isPresent());
        check.setTeacherName(schedule.getTeacherName());
        check.setTeacherId(findTeacherId(schedule.getTeacherName(), schoolId));
        check.setClassName(schedule.getClassName());
        check.setSubject(schedule.getSubject());
        check.setRoom(schedule.getRoom());
        check.setVerifierId(userId.toString());
        check.setVerifierName(displayName(verifierMembership));
        check.setCheckedAt(LocalDateTime.now(clock.withZone(SCHOOL_TIME_ZONE)));
        if (!check.isPresent() && check.getJustificationDeadline() == null) {
            check.setJustificationDeadline(
                    LocalDateTime.now(clock.withZone(SCHOOL_TIME_ZONE)).plusHours(24));
        }
        if (check.getAcademicYearId() == null) {
            check.setAcademicYearId(academicYearService.stampCurrentYear());
        }
        schoolContextService.verifyAndAssign(check);
        TeacherRoomCheck saved = repository.save(check);
        if (!saved.isPresent() && !wasAbsent) {
            notificationService.notifyTeacherRoomAbsence(saved);
        }
        return mapToDto(saved);
    }

    @Transactional
    public TeacherRoomCheckDto justify(Long id, String teacherId, String justification) {
        TeacherRoomCheck check = schoolContextService.scope(repository.findAll()).stream()
                .filter(item -> item.getId().equals(id))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Contrôle introuvable"));
        if (check.getTeacherId() == null || !check.getTeacherId().equals(teacherId)) {
            throw new IllegalArgumentException("Ce contrôle ne vous est pas destiné");
        }
        Long parsedTeacherId = parseId(teacherId);
        Long currentUserId = securityContextService.getCurrentUserId();
        Long schoolId = schoolContextService.currentSchoolId();
        if (parsedTeacherId == null || !parsedTeacherId.equals(currentUserId)
                || schoolId == null
                || membershipRepository.findByUserIdAndSchoolId(parsedTeacherId, schoolId)
                .filter(SchoolMembership::isActive)
                .map(SchoolMembership::getRole)
                .filter(role -> role == UserRole.ENSEIGNANT)
                .isEmpty()) {
            throw new IllegalArgumentException("Seul un professeur peut se justifier");
        }
        if (check.isPresent()) {
            throw new IllegalArgumentException("Une justification n'est nécessaire que pour une absence");
        }
        LocalDateTime now = LocalDateTime.now(clock.withZone(SCHOOL_TIME_ZONE));
        if (check.getJustificationDeadline() == null
                || now.isAfter(check.getJustificationDeadline())) {
            throw new IllegalArgumentException("Le délai de justification est dépassé");
        }
        if (justification == null || justification.isBlank()) {
            throw new IllegalArgumentException("L'explication est obligatoire");
        }
        check.setJustification(justification.trim());
        check.setJustificationSubmittedAt(now);
        return mapToDto(repository.save(check));
    }

    private String dayName(LocalDate date) {
        return switch (date.getDayOfWeek()) {
            case MONDAY -> "Lundi";
            case TUESDAY -> "Mardi";
            case WEDNESDAY -> "Mercredi";
            case THURSDAY -> "Jeudi";
            case FRIDAY -> "Vendredi";
            case SATURDAY -> "Samedi";
            case SUNDAY -> "Dimanche";
        };
    }

    private LocalTime parseTime(String value) {
        try {
            return LocalTime.parse(value.trim());
        } catch (RuntimeException e) {
            throw new IllegalArgumentException("L’heure du créneau est invalide.");
        }
    }

    private Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private String findTeacherId(String teacherName, Long schoolId) {
        if (teacherName == null || teacherName.isBlank()) return null;
        return membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(schoolId)
                .stream()
                .filter(membership -> membership.getRole() == UserRole.ENSEIGNANT)
                .map(SchoolMembership::getUser)
                .filter(user -> user.getFullName() != null
                        && user.getFullName().equalsIgnoreCase(teacherName))
                .map(user -> user.getId().toString())
                .findFirst()
                .orElse(null);
    }

    private String displayName(SchoolMembership membership) {
        var user = membership.getUser();
        return user.getFullName() != null && !user.getFullName().isBlank()
                ? user.getFullName() : user.getUsername();
    }

    private TeacherRoomCheckDto mapToDto(TeacherRoomCheck entity) {
        TeacherRoomCheckDto dto = new TeacherRoomCheckDto();
        dto.setId(entity.getId());
        dto.setScheduleItemId(entity.getScheduleItemId());
        dto.setCheckDate(entity.getCheckDate());
        dto.setPresent(entity.isPresent());
        dto.setTeacherName(entity.getTeacherName());
        dto.setTeacherId(entity.getTeacherId());
        dto.setClassName(entity.getClassName());
        dto.setSubject(entity.getSubject());
        dto.setRoom(entity.getRoom());
        dto.setVerifierId(entity.getVerifierId());
        dto.setVerifierName(entity.getVerifierName());
        dto.setJustification(entity.getJustification());
        dto.setJustificationSubmittedAt(entity.getJustificationSubmittedAt());
        dto.setJustificationDeadline(entity.getJustificationDeadline());
        dto.setCheckedAt(entity.getCheckedAt());
        return dto;
    }
}
