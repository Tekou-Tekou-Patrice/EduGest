package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.StaffAttendanceScanDto;
import com.eduguest.Edu.Entity.DailyAttendanceQr;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.StaffDailyAttendance;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.DailyAttendanceQrRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.eduguest.Edu.Repository.StaffDailyAttendanceRepository;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class StaffAttendanceServiceTest {
    private static final ZoneId SCHOOL_ZONE = ZoneId.of("Africa/Douala");
    private static final LocalDate TODAY = LocalDate.of(2026, 3, 2);

    @Test
    void firstScanRecordsArrivalSecondRecordsDepartureAndThirdIsRejected() {
        Fixture fixture = fixture(Instant.parse("2026-03-02T06:30:00Z"));

        StaffAttendanceScanDto arrival = fixture.service.scan("today-qr");
        fixture.currentTime.set(Instant.parse("2026-03-02T08:00:00Z"));
        StaffAttendanceScanDto departure = fixture.service.scan("today-qr");

        assertThat(arrival.action()).isEqualTo("ARRIVAL");
        assertThat(arrival.checkInAt()).isEqualTo(TODAY.atTime(7, 30));
        assertThat(arrival.checkOutAt()).isNull();
        assertThat(arrival.durationMinutes()).isNull();
        assertThat(arrival.monthlyTotalMinutes()).isZero();
        assertThat(departure.action()).isEqualTo("DEPARTURE");
        assertThat(departure.checkInAt()).isEqualTo(TODAY.atTime(7, 30));
        assertThat(departure.checkOutAt()).isEqualTo(TODAY.atTime(9, 0));
        assertThat(departure.durationMinutes()).isEqualTo(90);
        assertThat(departure.monthlyTotalMinutes()).isEqualTo(90);
        assertThatThrownBy(() -> fixture.service.scan("today-qr"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("déjà été enregistrés");
    }

    @Test
    void scansBeforeSixAreRejectedWithoutReadingTheQrSession() {
        Fixture fixture = fixture(Instant.parse("2026-03-02T04:59:00Z"));

        assertThatThrownBy(() -> fixture.service.scan("today-qr"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("à partir de 6 h");
        verify(fixture.qrRepository, never()).findForUpdate(anyLong(), any(), anyString());
    }

    private Fixture fixture(Instant now) {
        DailyAttendanceQrRepository qrRepository = mock(DailyAttendanceQrRepository.class);
        StaffDailyAttendanceRepository attendanceRepository =
                mock(StaffDailyAttendanceRepository.class);
        SchoolRepository schoolRepository = mock(SchoolRepository.class);
        SchoolMembershipRepository membershipRepository = mock(SchoolMembershipRepository.class);
        SchoolContextService schoolContextService = mock(SchoolContextService.class);
        UserSecurityContextService securityContextService = mock(UserSecurityContextService.class);

        School school = new School();
        school.setId(1L);
        school.setName("Test School");
        school.setActive(true);
        User user = new User();
        user.setId(10L);
        user.setUsername("teacher");
        user.setRole(UserRole.ENSEIGNANT);
        user.setActive(true);
        SchoolMembership membership = new SchoolMembership();
        membership.setUser(user);
        membership.setSchool(school);
        membership.setRole(UserRole.ENSEIGNANT);
        membership.setActive(true);
        DailyAttendanceQr qr = new DailyAttendanceQr();
        qr.setSchool(school);
        qr.setAttendanceDate(TODAY);

        when(schoolContextService.currentSchoolId()).thenReturn(1L);
        when(schoolRepository.findById(1L)).thenReturn(Optional.of(school));
        when(securityContextService.getCurrentRole()).thenReturn(UserRole.ENSEIGNANT);
        when(securityContextService.getCurrentUser()).thenReturn(Optional.of(user));
        when(membershipRepository.findByUserIdAndSchoolId(10L, 1L))
                .thenReturn(Optional.of(membership));
        when(qrRepository.findForUpdate(eq(1L), eq(TODAY), anyString()))
                .thenReturn(Optional.of(qr));

        AtomicReference<StaffDailyAttendance> storedAttendance = new AtomicReference<>();
        AtomicReference<Instant> currentTime = new AtomicReference<>(now);
        when(attendanceRepository.findBySchoolIdAndUserIdAndAttendanceDate(1L, 10L, TODAY))
                .thenAnswer(ignored -> Optional.ofNullable(storedAttendance.get()));
        when(attendanceRepository
                .findBySchoolIdAndUserIdAndAttendanceDateGreaterThanEqualAndAttendanceDateLessThan(
                        eq(1L), eq(10L), any(LocalDate.class), any(LocalDate.class)))
                .thenAnswer(ignored -> {
                    StaffDailyAttendance attendance = storedAttendance.get();
                    return attendance == null ? List.of() : List.of(attendance);
                });
        when(attendanceRepository.save(any(StaffDailyAttendance.class))).thenAnswer(invocation -> {
            StaffDailyAttendance attendance = invocation.getArgument(0);
            storedAttendance.set(attendance);
            return attendance;
        });

        StaffAttendanceService service = new StaffAttendanceService(
                qrRepository,
                attendanceRepository,
                schoolRepository,
                membershipRepository,
                schoolContextService,
                securityContextService,
                "test-qr-secret-that-is-long-enough-to-be-secure",
                SCHOOL_ZONE.getId(),
                new MutableClock(currentTime, ZoneId.of("UTC")));
        return new Fixture(service, qrRepository, currentTime);
    }

    private record Fixture(
            StaffAttendanceService service,
            DailyAttendanceQrRepository qrRepository,
            AtomicReference<Instant> currentTime) {
    }

    private static final class MutableClock extends Clock {
        private final AtomicReference<Instant> currentTime;
        private final ZoneId zone;

        private MutableClock(AtomicReference<Instant> currentTime, ZoneId zone) {
            this.currentTime = currentTime;
            this.zone = zone;
        }

        @Override
        public ZoneId getZone() {
            return zone;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return new MutableClock(currentTime, zone);
        }

        @Override
        public Instant instant() {
            return currentTime.get();
        }
    }
}
