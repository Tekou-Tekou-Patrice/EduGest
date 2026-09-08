package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.TeacherRoomCheckDto;
import com.eduguest.Edu.Entity.TeacherRoomCheck;
import com.eduguest.Edu.Entity.ScheduleItem;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import com.eduguest.Edu.Repository.TeacherRoomCheckRepository;
import com.eduguest.Edu.Repository.UserRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.UserRole;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class TeacherRoomCheckService {
    private final TeacherRoomCheckRepository repository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final ScheduleItemRepository scheduleRepository;
    private final AppNotificationService notificationService;
    private final UserRepository userRepository;
    private final SchoolMembershipRepository membershipRepository;

    public TeacherRoomCheckService(
            TeacherRoomCheckRepository repository,
            AcademicYearService academicYearService,
            SchoolContextService schoolContextService,
            ScheduleItemRepository scheduleRepository,
            AppNotificationService notificationService,
            UserRepository userRepository,
            SchoolMembershipRepository membershipRepository) {
        this.repository = repository;
        this.academicYearService = academicYearService;
        this.schoolContextService = schoolContextService;
        this.scheduleRepository = scheduleRepository;
        this.notificationService = notificationService;
        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
    }

    @Transactional
    public List<TeacherRoomCheckDto> getChecks(LocalDate date) {
        academicYearService.autoCloseIfDue();
        finalizeExpired(date);
        return schoolContextService.scope(repository.findByCheckDateOrderByCheckedAtDesc(date))
                .stream()
                .filter(check -> academicYearService.filterCurrentYear(
                        List.of(check), TeacherRoomCheck::getAcademicYearId).size() == 1)
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public List<TeacherRoomCheckDto> getTeacherAbsences(String teacherId) {
        return schoolContextService.scope(repository.findByTeacherIdAndPresentFalseOrderByCheckedAtDesc(teacherId))
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public TeacherRoomCheckDto saveCheck(TeacherRoomCheckDto dto) {
        if (dto.getScheduleItemId() == null) {
            throw new IllegalArgumentException("Le créneau est obligatoire");
        }
        if (dto.getCheckDate() == null) {
            throw new IllegalArgumentException("La date est obligatoire");
        }
        if (dto.getVerifierId() == null || dto.getVerifierId().isBlank()) {
            throw new IllegalArgumentException("Le vérificateur est obligatoire");
        }
        Long verifierId = parseId(dto.getVerifierId());
        if (verifierId == null || userRepository.findById(verifierId)
                .map(user -> user.getRole() != UserRole.SURVEILLANT_GENERAL)
                .orElse(true)) {
            throw new IllegalArgumentException(
                    "Seul le surveillant général peut enregistrer un contrôle");
        }

        TeacherRoomCheck check = repository
                .findByScheduleItemIdAndCheckDate(dto.getScheduleItemId(), dto.getCheckDate())
                .orElseGet(TeacherRoomCheck::new);
        check.setScheduleItemId(dto.getScheduleItemId());
        check.setCheckDate(dto.getCheckDate());
        check.setPresent(dto.isPresent());
        check.setTeacherName(dto.getTeacherName());
        check.setTeacherId(dto.getTeacherId() == null || dto.getTeacherId().isBlank()
                ? findTeacherId(dto.getTeacherName()) : dto.getTeacherId());
        check.setClassName(dto.getClassName());
        check.setSubject(dto.getSubject());
        check.setRoom(dto.getRoom());
        check.setVerifierId(dto.getVerifierId());
        check.setVerifierName(dto.getVerifierName());
        check.setCheckedAt(LocalDateTime.now());
        if (!check.isPresent() && check.getJustificationDeadline() == null) {
            check.setJustificationDeadline(LocalDateTime.now().plusHours(24));
        }
        if (check.getAcademicYearId() == null) {
            check.setAcademicYearId(academicYearService.stampCurrentYear());
        }
        schoolContextService.verifyAndAssign(check);
        return mapToDto(repository.save(check));
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
        if (parsedTeacherId == null || userRepository.findById(parsedTeacherId)
                .map(user -> user.getRole() != UserRole.ENSEIGNANT)
                .orElse(true)) {
            throw new IllegalArgumentException("Seul un professeur peut se justifier");
        }
        if (check.isPresent()) {
            throw new IllegalArgumentException("Une justification n'est nécessaire que pour une absence");
        }
        if (check.getJustificationDeadline() == null
                || LocalDateTime.now().isAfter(check.getJustificationDeadline())) {
            throw new IllegalArgumentException("Le délai de justification est dépassé");
        }
        if (justification == null || justification.isBlank()) {
            throw new IllegalArgumentException("L'explication est obligatoire");
        }
        check.setJustification(justification.trim());
        check.setJustificationSubmittedAt(LocalDateTime.now());
        return mapToDto(repository.save(check));
    }

    private void finalizeExpired(LocalDate date) {
        if (!date.equals(LocalDate.now())) return;
        String day = switch (date.getDayOfWeek()) {
            case MONDAY -> "Lundi";
            case TUESDAY -> "Mardi";
            case WEDNESDAY -> "Mercredi";
            case THURSDAY -> "Jeudi";
            case FRIDAY -> "Vendredi";
            case SATURDAY -> "Samedi";
            case SUNDAY -> "Dimanche";
        };
        LocalTime now = LocalTime.now();
        List<ScheduleItem> expired = schoolContextService.scope(scheduleRepository.findByDay(day)).stream()
                .filter(item -> !item.isBreak())
                .filter(item -> parseTime(item.getEndTime()).isBefore(now))
                .toList();
        for (ScheduleItem item : expired) {
            var existing = repository.findByScheduleItemIdAndCheckDate(item.getId(), date);
            if (existing.isPresent()) {
                TeacherRoomCheck current = existing.get();
                if (!current.isPresent() && current.getJustificationDeadline() == null) {
                    current.setJustificationDeadline(LocalDateTime.now().plusHours(24));
                    notificationService.notifyTeacherRoomAbsence(repository.save(current));
                }
                continue;
            }
            TeacherRoomCheck check = new TeacherRoomCheck();
            check.setScheduleItemId(item.getId());
            check.setCheckDate(date);
            check.setPresent(false);
            check.setTeacherName(item.getTeacherName());
            check.setTeacherId(findTeacherId(item.getTeacherName()));
            check.setClassName(item.getClassName());
            check.setSubject(item.getSubject());
            check.setRoom(item.getRoom());
            check.setVerifierId("SYSTEM");
            check.setVerifierName("Système");
            check.setCheckedAt(LocalDateTime.now());
            check.setJustificationDeadline(LocalDateTime.now().plusHours(24));
            check.setAcademicYearId(item.getAcademicYearId());
            check.setSchool(item.getSchool());
            TeacherRoomCheck saved = repository.save(check);
            notificationService.notifyTeacherRoomAbsence(saved);
        }
    }

    private LocalTime parseTime(String value) {
        try {
            return LocalTime.parse(value);
        } catch (RuntimeException e) {
            return LocalTime.MAX;
        }
    }

    private Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private String findTeacherId(String teacherName) {
        if (teacherName == null || teacherName.isBlank()) return null;
        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId == null) return null;
        return membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(schoolId)
                .stream()
                .map(SchoolMembership::getUser)
                .filter(user -> user.getRole() == UserRole.ENSEIGNANT)
                .filter(user -> user.getFullName() != null
                        && user.getFullName().equalsIgnoreCase(teacherName))
                .map(user -> user.getId().toString())
                .findFirst()
                .orElse(null);
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
