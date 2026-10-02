package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.TeacherRoomCheckDto;
import com.eduguest.Edu.Entity.ScheduleItem;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.TeacherRoomCheckRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class TeacherRoomCheckServiceTest {
    private static final LocalDate TODAY = LocalDate.of(2026, 4, 13);
    private static final Clock CLOCK = Clock.fixed(
            Instant.parse("2026-04-13T08:30:00Z"), ZoneId.of("UTC"));

    @Test
    void proviseurCanRecordDuringCourseUsingServerIdentityAndScheduleDetails() {
        Fixture fixture = fixture(UserRole.PROVISEUR, 1L);
        TeacherRoomCheckDto request = new TeacherRoomCheckDto();
        request.setScheduleItemId(20L);
        request.setCheckDate(TODAY);
        request.setPresent(true);
        request.setTeacherName("Client supplied name");
        request.setVerifierId("999");
        request.setVerifierName("Impersonated verifier");

        TeacherRoomCheckDto response = fixture.service.saveCheck(request);

        assertThat(response.getVerifierId()).isEqualTo("10");
        assertThat(response.getVerifierName()).isEqualTo("Directrice");
        assertThat(response.getTeacherName()).isEqualTo("Teacher from schedule");
        assertThat(response.getSubject()).isEqualTo("Maths");
        verify(fixture.repository).findByScheduleItemDateAndSchool(20L, TODAY, 1L);
    }

    @Test
    void nonVerifierCannotRecordEvenIfClientSuppliesVerifierIdentity() {
        Fixture fixture = fixture(UserRole.ENSEIGNANT, 1L);
        TeacherRoomCheckDto request = new TeacherRoomCheckDto();
        request.setScheduleItemId(20L);
        request.setCheckDate(TODAY);
        request.setPresent(true);
        request.setVerifierId("10");

        assertThatThrownBy(() -> fixture.service.saveCheck(request))
                .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                .hasMessageContaining("personnel de surveillance");
        verify(fixture.scheduleRepository, never()).findById(any());
    }

    @Test
    void cannotRecordCourseFromAnotherSchool() {
        Fixture fixture = fixture(UserRole.PROVISEUR, 2L);
        TeacherRoomCheckDto request = new TeacherRoomCheckDto();
        request.setScheduleItemId(20L);
        request.setCheckDate(TODAY);
        request.setPresent(true);

        assertThatThrownBy(() -> fixture.service.saveCheck(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("école sélectionnée");
        verify(fixture.repository, never()).save(any());
    }

    @Test
    void cannotMarkCourseBeforeItsScheduledTime() {
        Fixture fixture = fixture(UserRole.PROVISEUR, 1L);
        ScheduleItem futureSchedule = new ScheduleItem();
        School school = new School();
        school.setId(1L);
        futureSchedule.setId(20L);
        futureSchedule.setSchool(school);
        futureSchedule.setDay("Lundi");
        futureSchedule.setStartTime("10:00");
        futureSchedule.setEndTime("11:00");
        when(fixture.scheduleRepository.findById(20L))
                .thenReturn(Optional.of(futureSchedule));

        TeacherRoomCheckDto request = new TeacherRoomCheckDto();
        request.setScheduleItemId(20L);
        request.setCheckDate(TODAY);
        request.setPresent(true);

        assertThatThrownBy(() -> fixture.service.saveCheck(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("pendant l’heure de cours");
        verify(fixture.repository, never()).save(any());
    }

    private Fixture fixture(UserRole verifierRole, Long scheduleSchoolId) {
        TeacherRoomCheckRepository repository = mock(TeacherRoomCheckRepository.class);
        AcademicYearService academicYearService = mock(AcademicYearService.class);
        SchoolContextService schoolContextService = mock(SchoolContextService.class);
        ScheduleItemRepository scheduleRepository = mock(ScheduleItemRepository.class);
        AppNotificationService notificationService = mock(AppNotificationService.class);
        UserRepository userRepository = mock(UserRepository.class);
        SchoolMembershipRepository membershipRepository = mock(SchoolMembershipRepository.class);
        UserSecurityContextService securityContextService = mock(UserSecurityContextService.class);

        School school = new School();
        school.setId(scheduleSchoolId);
        ScheduleItem schedule = new ScheduleItem();
        schedule.setId(20L);
        schedule.setSchool(school);
        schedule.setDay("Lundi");
        schedule.setStartTime("09:00");
        schedule.setEndTime("10:00");
        schedule.setTeacherName("Teacher from schedule");
        schedule.setClassName("6e A");
        schedule.setSubject("Maths");
        schedule.setRoom("A1");

        User verifier = new User();
        verifier.setId(10L);
        verifier.setFullName("Directrice");
        verifier.setUsername("director");
        SchoolMembership membership = new SchoolMembership();
        membership.setUser(verifier);
        membership.setRole(verifierRole);
        membership.setActive(true);

        when(securityContextService.getCurrentUserId()).thenReturn(10L);
        when(schoolContextService.currentSchoolId()).thenReturn(1L);
        when(membershipRepository.findByUserIdAndSchoolId(10L, 1L))
                .thenReturn(Optional.of(membership));
        when(scheduleRepository.findById(20L)).thenReturn(Optional.of(schedule));
        when(repository.findByScheduleItemDateAndSchool(20L, TODAY, 1L))
                .thenReturn(Optional.empty());
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(academicYearService.stampCurrentYear()).thenReturn(3L);
        when(membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(1L))
                .thenReturn(List.of());

        TeacherRoomCheckService service = new TeacherRoomCheckService(
                repository,
                academicYearService,
                schoolContextService,
                scheduleRepository,
                notificationService,
                userRepository,
                membershipRepository,
                securityContextService,
                CLOCK);
        return new Fixture(service, repository, scheduleRepository);
    }

    private record Fixture(
            TeacherRoomCheckService service,
            TeacherRoomCheckRepository repository,
            ScheduleItemRepository scheduleRepository) {
    }
}
