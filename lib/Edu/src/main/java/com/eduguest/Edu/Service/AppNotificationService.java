package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.AppNotificationDto;
import com.eduguest.Edu.Entity.Absence;
import com.eduguest.Edu.Entity.AppNotification;
import com.eduguest.Edu.Entity.Event;
import com.eduguest.Edu.Entity.Grade;
import com.eduguest.Edu.Entity.Payment;
import com.eduguest.Edu.Entity.Sanction;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.Student;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.AppNotificationRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AppNotificationService {
    private final AppNotificationRepository notificationRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final SchoolMembershipRepository membershipRepository;


    public AppNotificationService(AppNotificationRepository notificationRepository,
                                  AcademicYearService academicYearService,
                                  SchoolContextService schoolContextService,
                                  UserRepository userRepository,
                                  StudentRepository studentRepository,
                                  SchoolMembershipRepository membershipRepository) {
        this.schoolContextService = schoolContextService;
        this.notificationRepository = notificationRepository;
        this.academicYearService = academicYearService;
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.membershipRepository = membershipRepository;
    }

    public List<AppNotificationDto> getUnreadNotifications() {
        return getUnreadNotifications(null);
    }

    @Transactional
    public List<AppNotificationDto> getUnreadNotifications(Long userId) {
        academicYearService.autoCloseIfDue();
        List<AppNotification> unread = userId == null
                ? notificationRepository.findByReadFalse()
                : notificationRepository.findUnreadForUser(userId);
        return academicYearService.filterCurrentYear(schoolContextService.scope(unread), AppNotification::getAcademicYearId)
                .stream().map(this::mapToDto).collect(Collectors.toList());
    }

    public void markAsRead(Long id) {
        markAsRead(id, null);
    }

    @Transactional
    public void markAsRead(Long id, Long userId) {
        notificationRepository.findById(id).ifPresent(notif -> {
            schoolContextService.verifyAndAssign(notif);
            if (userId != null && notif.getRecipient() != null
                    && !userId.equals(notif.getRecipient().getId())) {
                throw new IllegalArgumentException("Cette notification est destinée à un autre utilisateur");
            }
            notif.setRead(true);
            notificationRepository.save(notif);
        });
    }

    @Transactional
    public AppNotificationDto createNotification(AppNotificationDto dto) {
        AppNotification notif = new AppNotification();
        notif.setTitle(dto.getTitle());
        notif.setMessage(dto.getMessage());
        notif.setTimestamp(dto.getTimestamp() != null ? dto.getTimestamp() : LocalDateTime.now());
        notif.setRead(false);
        notif.setType(dto.getType());
        try {
            notif.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            notif.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        if (dto.getRecipientUserId() != null) {
            notif.setRecipient(findRecipient(dto.getRecipientUserId()));
        }
        schoolContextService.verifyAndAssign(notif);
        return mapToDto(notificationRepository.save(notif));
    }

    @Transactional
    public void notifyGrade(Grade grade) {
        notifyParents(grade.getStudentId(),
                "Nouvelle note",
                "Une nouvelle note a été enregistrée pour l'élève " + grade.getStudentId()
                        + " : " + grade.getScore(),
                "grade");
    }

    @Transactional
    public void notifyAbsence(Absence absence) {
        notifyParents(absence.getStudentId(),
                "Absence enregistrée",
                "Une absence a été enregistrée pour " + displayStudent(absence.getStudentName(), absence.getStudentId())
                        + " (" + absence.getPeriod() + ").",
                "absence");
    }

    @Transactional
    public void notifyPayment(Payment payment) {
        notifyParents(payment.getStudentId(),
                "Paiement enregistré",
                "Un paiement de " + payment.getAmount() + " a été enregistré pour "
                        + displayStudent(payment.getStudentName(), payment.getStudentId()) + ".",
                "payment");
    }

    @Transactional
    public void notifySanction(Sanction sanction) {
        notifyParents(sanction.getStudentId(),
                "Mesure disciplinaire",
                "Une mesure disciplinaire (" + sanction.getType() + ") concerne "
                        + displayStudent(sanction.getStudentName(), sanction.getStudentId()) + ".",
                "discipline");
    }

    @Transactional
    public void notifyEvent(Event event) {
        notifyUsers(schoolUsers(),
                "Nouvel événement",
                event.getTitle() + " est prévu le " + event.getDate() + ".",
                "event");
    }

    private void notifyParents(String studentId, String title, String message, String type) {
        notifyUsers(parentUsersForStudent(studentId), title, message, type);
    }

    private void notifyUsers(Collection<User> recipients, String title, String message, String type) {
        for (User recipient : recipients) {
            AppNotification notification = new AppNotification();
            notification.setRecipient(recipient);
            notification.setTitle(title);
            notification.setMessage(message);
            notification.setTimestamp(LocalDateTime.now());
            notification.setRead(false);
            notification.setType(type);
            try {
                notification.setAcademicYearId(academicYearService.stampCurrentYear());
            } catch (RuntimeException e) {
                notification.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            }
            schoolContextService.verifyAndAssign(notification);
            notificationRepository.save(notification);
        }
    }

    private List<User> parentUsersForStudent(String studentId) {
        Long id = parseId(studentId);
        if (id == null) return List.of();

        Student student = studentRepository.findById(id).orElse(null);
        Long schoolId = schoolContextService.currentSchoolId();
        if (student == null || schoolId == null || student.getSchool() == null
                || !schoolId.equals(student.getSchool().getId())) {
            return List.of();
        }

        Map<Long, User> candidates = new LinkedHashMap<>();
        addCandidate(candidates, student.getParentEmail(), true);
        addCandidate(candidates, student.getParentPhone(), false);
        return candidates.values().stream()
                .filter(user -> user.isActive() && user.getRole() == UserRole.PARENT)
                .filter(this::isMemberOfCurrentSchool)
                .collect(Collectors.toList());
    }

    private void addCandidate(Map<Long, User> candidates, String value, boolean email) {
        if (value == null || value.isBlank()) return;
        List<User> users = new ArrayList<>();
        if (email) {
            userRepository.findByEmailIgnoreCase(value.trim()).ifPresent(users::add);
        } else {
            users.addAll(userRepository.findByPhone(value.trim()));
            userRepository.findByUsername(value.trim()).ifPresent(users::add);
        }
        users.forEach(user -> {
            if (user.getId() != null) candidates.put(user.getId(), user);
        });
    }

    private List<User> schoolUsers() {
        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId == null) return List.of();
        return membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(schoolId).stream()
                .map(SchoolMembership::getUser)
                .filter(User::isActive)
                .collect(Collectors.toMap(User::getId, user -> user, (first, ignored) -> first,
                        LinkedHashMap::new))
                .values().stream().collect(Collectors.toList());
    }

    private boolean isMemberOfCurrentSchool(User user) {
        Long schoolId = schoolContextService.currentSchoolId();
        return schoolId != null && membershipRepository.findByUserIdAndSchoolId(user.getId(), schoolId)
                .filter(SchoolMembership::isActive)
                .isPresent();
    }

    private User findRecipient(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur destinataire introuvable"));
        if (!isMemberOfCurrentSchool(user)) {
            throw new IllegalArgumentException("Le destinataire n'appartient pas à l'école active");
        }
        return user;
    }

    private String displayStudent(String name, String id) {
        return name == null || name.isBlank() ? "l'élève " + id : name;
    }

    private Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    private AppNotificationDto mapToDto(AppNotification entity) {
        AppNotificationDto dto = new AppNotificationDto();
        dto.setId(entity.getId());
        dto.setTitle(entity.getTitle());
        dto.setMessage(entity.getMessage());
        dto.setTimestamp(entity.getTimestamp());
        dto.setRead(entity.isRead());
        dto.setType(entity.getType());
        if (entity.getRecipient() != null) {
            dto.setRecipientUserId(entity.getRecipient().getId());
        }
        return dto;
    }
}
