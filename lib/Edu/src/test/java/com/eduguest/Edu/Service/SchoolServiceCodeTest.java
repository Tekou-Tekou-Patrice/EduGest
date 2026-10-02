package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.SchoolCreateRequest;
import com.eduguest.Edu.DTO.SchoolDto;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.ClassroomRepository;
import com.eduguest.Edu.Repository.PaymentRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.SubscriptionPaymentRepository;
import com.eduguest.Edu.Repository.TeacherRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SchoolServiceCodeTest {
    private final SchoolRepository schoolRepository = mock(SchoolRepository.class);
    private final SchoolMembershipRepository membershipRepository =
            mock(SchoolMembershipRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);

    private SchoolService service() {
        return new SchoolService(
                schoolRepository,
                membershipRepository,
                userRepository,
                mock(StudentRepository.class),
                mock(TeacherRepository.class),
                mock(ClassroomRepository.class),
                mock(PaymentRepository.class),
                mock(SubscriptionPaymentRepository.class));
    }

    @Test
    void createGeneratesUniquePrivateCodeAndReturnsItToFounder() {
        User founder = new User();
        founder.setId(12L);
        founder.setFullName("Founder");
        founder.setPhone("+237600000000");
        founder.setEmail("founder@example.com");
        when(userRepository.findById(12L)).thenReturn(Optional.of(founder));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(membershipRepository.findByUserIdAndSchoolId(12L, 41L))
                .thenReturn(Optional.empty());
        when(membershipRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(41L))
                .thenReturn(List.of());
        when(schoolRepository.existsByCode(anyString())).thenReturn(false);
        when(schoolRepository.save(any(School.class))).thenAnswer(invocation -> {
            School school = invocation.getArgument(0);
            school.setId(41L);
            return school;
        });

        SchoolCreateRequest request = new SchoolCreateRequest();
        request.setName("École Exemple");
        request.setCode("USER-CHOSEN-CODE");
        request.setUserId(12L);
        request.setSchoolLevel("PRIMARY");

        SchoolDto created = service().create(request);

        assertThat(created.getId()).isEqualTo(41L);
        assertThat(created.getCode()).matches("EDU-[A-HJ-NP-Z2-9]{12}");
        assertThat(created.getCode()).isNotEqualTo("USER-CHOSEN-CODE");
        verify(schoolRepository).existsByCode(created.getCode());
        verify(schoolRepository).save(argThat(school ->
                created.getCode().equals(school.getCode())));
        assertThat(founder.getRole()).isEqualTo(UserRole.FONDATEUR);
    }

    @Test
    void generateAnotherCodeWhenCandidateAlreadyExists() {
        User founder = new User();
        founder.setId(12L);
        founder.setFullName("Founder");
        founder.setPhone("+237600000000");
        founder.setEmail("founder@example.com");
        when(userRepository.findById(12L)).thenReturn(Optional.of(founder));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(membershipRepository.findByUserIdAndSchoolId(12L, 41L))
                .thenReturn(Optional.empty());
        when(membershipRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(41L))
                .thenReturn(List.of());
        when(schoolRepository.existsByCode(anyString())).thenReturn(true, false);
        when(schoolRepository.save(any(School.class))).thenAnswer(invocation -> {
            School school = invocation.getArgument(0);
            school.setId(41L);
            return school;
        });

        SchoolCreateRequest request = new SchoolCreateRequest();
        request.setName("Another School");
        request.setUserId(12L);

        SchoolDto created = service().create(request);

        assertThat(created.getCode()).matches("EDU-[A-HJ-NP-Z2-9]{12}");
        verify(schoolRepository, times(2)).existsByCode(anyString());
    }
}
