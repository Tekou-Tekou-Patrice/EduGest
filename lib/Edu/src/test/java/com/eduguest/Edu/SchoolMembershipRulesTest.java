package com.eduguest.Edu;

import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.eduguest.Edu.Repository.UserRepository;
import com.eduguest.Edu.Service.SchoolService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SchoolMembershipRulesTest {

    @Mock
    private SchoolRepository schoolRepository;

    @Mock
    private SchoolMembershipRepository membershipRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private SchoolService schoolService;

    @Test
    void shouldAllowSameStaffMemberToBelongToMultipleSchools() {
        User user = new User();
        user.setId(10L);
        user.setRole(UserRole.PROVISEUR);

        School schoolA = new School();
        schoolA.setId(1L);
        schoolA.setName("École A");
        schoolA.setCode("ECOLE-A");
        schoolA.setActive(true);

        School schoolB = new School();
        schoolB.setId(2L);
        schoolB.setName("École B");
        schoolB.setCode("ECOLE-B");
        schoolB.setActive(true);

        when(membershipRepository.findByUserIdAndSchoolId(10L, 1L)).thenReturn(Optional.empty());
        when(membershipRepository.findByUserIdAndSchoolId(10L, 2L)).thenReturn(Optional.empty());
        when(membershipRepository.save(any(SchoolMembership.class))).thenAnswer(invocation -> invocation.getArgument(0));

        SchoolMembership first = schoolService.addMembership(user, schoolA, UserRole.PROVISEUR);
        SchoolMembership second = schoolService.addMembership(user, schoolB, UserRole.SECRETAIRE);

        assertThat(first.getSchool().getId()).isEqualTo(1L);
        assertThat(second.getSchool().getId()).isEqualTo(2L);
        assertThat(first.getUser().getId()).isEqualTo(10L);
        assertThat(second.getUser().getId()).isEqualTo(10L);
    }

    @Test
    void shouldAcceptMixedCasePrivateCodeAndRejectJoiningWithoutMembership() {
        User user = new User();
        user.setId(10L);
        user.setRole(UserRole.ENSEIGNANT);

        School school = new School();
        school.setId(7L);
        school.setName("École C");
        school.setCode("Ab3!Cd7?");
        school.setActive(true);

        when(schoolRepository.findByCodeIgnoreCase("aB3!cD7?"))
                .thenReturn(Optional.of(school));
        when(userRepository.findById(10L)).thenReturn(Optional.of(user));
        when(membershipRepository.findByUserIdAndSchoolId(10L, 7L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> schoolService.joinByCode(10L, "aB3!cD7?", null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("deja")
                .hasMessageContaining("enregistre");
    }
}
