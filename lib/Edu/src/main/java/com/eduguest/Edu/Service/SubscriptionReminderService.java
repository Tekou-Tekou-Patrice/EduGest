package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.AppNotification;
import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.AppNotificationRepository;
import com.eduguest.Edu.Repository.AcademicYearRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** Creates one reminder exactly seven days before a subscription ends. */
@Service
public class SubscriptionReminderService {
    private static final String REMINDER_TYPE = "subscription";
    private static final String STAFF_RENEWAL_TYPE = "staff_renewal";

    private final SchoolRepository schoolRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final AppNotificationRepository notificationRepository;
    private final AcademicYearRepository academicYearRepository;

    public SubscriptionReminderService(SchoolRepository schoolRepository,
                                       SchoolMembershipRepository membershipRepository,
                                       AppNotificationRepository notificationRepository,
                                       AcademicYearRepository academicYearRepository) {
        this.schoolRepository = schoolRepository;
        this.membershipRepository = membershipRepository;
        this.notificationRepository = notificationRepository;
        this.academicYearRepository = academicYearRepository;
    }

    @Scheduled(cron = "0 0 8 * * *", zone = "Africa/Douala")
    @Transactional
    public void sendSevenDayReminders() {
        LocalDate expiryDate = LocalDate.now().plusDays(7);
        schoolRepository.findAll().stream()
                .filter(School::isActive)
                .filter(school -> expiryDate.equals(school.getSubscriptionExpiresAt()))
                .forEach(school -> notifyResponsibleStaff(school, expiryDate));
        sendStaffRenewalReminders();
    }

    private void sendStaffRenewalReminders() {
        LocalDate today = LocalDate.now();
        academicYearRepository.findAll().stream()
                .filter(AcademicYear::isActive)
                .filter(year -> today.equals(year.getStartDate()))
                .forEach(year -> {
                    School school = year.getSchool();
                    if (school == null || !school.isActive()) return;
                    membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(school.getId())
                            .stream()
                            .filter(membership -> membership.getRole() == UserRole.FONDATEUR)
                            .map(SchoolMembership::getUser)
                            .filter(User::isActive)
                            .forEach(founder -> saveStaffRenewalIfMissing(school, year, founder));
                });
    }

    private void saveStaffRenewalIfMissing(School school, AcademicYear year, User founder) {
        String marker = year.getLabel();
        if (notificationRepository.existsBySchool_IdAndRecipient_IdAndTypeAndMessageContaining(
                school.getId(), founder.getId(), STAFF_RENEWAL_TYPE, marker)) return;
        AppNotification notification = new AppNotification();
        notification.setSchool(school);
        notification.setRecipient(founder);
        notification.setTitle("Renouvellement du personnel");
        notification.setMessage("Début de l'année " + marker
                + ". Indiquez les membres du staff à conserver ou à supprimer.");
        notification.setTimestamp(LocalDateTime.now());
        notification.setRead(false);
        notification.setType(STAFF_RENEWAL_TYPE);
        notification.setAcademicYearId(year.getId());
        notificationRepository.save(notification);
    }

    private void notifyResponsibleStaff(School school, LocalDate expiryDate) {
        String dateText = expiryDate.toString();
        String message = "Votre abonnement EduGest expire le " + dateText
                + ". Renouvelez-le avant cette date pour éviter toute interruption.";

        membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(school.getId()).stream()
                .filter(membership -> membership.getRole() == UserRole.FONDATEUR
                        || membership.getRole() == UserRole.SECRETAIRE
                        || membership.getRole() == UserRole.COMPTABLE)
                .map(SchoolMembership::getUser)
                .filter(User::isActive)
                .forEach(founder -> saveIfMissing(school, founder, message, dateText));
    }

    private void saveIfMissing(School school, User founder, String message, String dateText) {
        if (notificationRepository.existsBySchool_IdAndRecipient_IdAndTypeAndMessageContaining(
                school.getId(), founder.getId(), REMINDER_TYPE, dateText)) {
            return;
        }
        AppNotification notification = new AppNotification();
        notification.setSchool(school);
        notification.setRecipient(founder);
        notification.setTitle("Abonnement bientôt expiré");
        notification.setMessage(message);
        notification.setTimestamp(LocalDateTime.now());
        notification.setRead(false);
        notification.setType(REMINDER_TYPE);
        notificationRepository.save(notification);
    }
}
