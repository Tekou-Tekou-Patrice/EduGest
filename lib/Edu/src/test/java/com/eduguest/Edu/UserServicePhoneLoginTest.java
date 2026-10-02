package com.eduguest.Edu;

import com.eduguest.Edu.DTO.LoginRequest;
import com.eduguest.Edu.DTO.LoginResponse;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.AppNotificationRepository;
import com.eduguest.Edu.Repository.DeviceTokenRepository;
import com.eduguest.Edu.Repository.ExpenseRepository;
import com.eduguest.Edu.Repository.PaymentRepository;
import com.eduguest.Edu.Repository.SchoolInfoRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.UserRepository;
import com.eduguest.Edu.Repository.VerificationCodeRepository;
import com.eduguest.Edu.Service.AuthTokenService;
import com.eduguest.Edu.Service.PhoneNumberService;
import com.eduguest.Edu.Service.SchoolContextService;
import com.eduguest.Edu.Service.SchoolService;
import com.eduguest.Edu.Service.UserService;
import com.eduguest.Edu.Service.UserSecurityContextService;
import com.eduguest.Edu.Service.VerificationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServicePhoneLoginTest {

    @Mock private UserRepository userRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private SchoolService schoolService;
    @Mock private SchoolMembershipRepository membershipRepository;
    @Mock private SchoolContextService schoolContextService;
    @Mock private AuthTokenService authTokenService;
    @Mock private UserSecurityContextService securityContextService;
    @Mock private VerificationService verificationService;
    @Mock private PaymentRepository paymentRepository;
    @Mock private ExpenseRepository expenseRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private VerificationCodeRepository verificationCodeRepository;
    @Mock private PhoneNumberService phoneNumberService;
    @Mock private AppNotificationRepository appNotificationRepository;
    @Mock private DeviceTokenRepository deviceTokenRepository;
    @Mock private SchoolInfoRepository schoolInfoRepository;

    @InjectMocks
    private UserService userService;

    @Test
    void phoneLoginSelectsTheMatchingPasswordAccountWhenPhoneIsDuplicated() {
        User schoolAccount = user(1L, "school-account");
        User otherAccount = user(2L, "other-account");
        String phone = "+237699000000";

        when(userRepository.findByUsername(phone)).thenReturn(Optional.empty());
        when(userRepository.findByEmailIgnoreCase(phone)).thenReturn(Optional.empty());
        when(phoneNumberService.lookupCandidates(phone)).thenReturn(Set.of(phone));
        when(userRepository.findByPhone(phone)).thenReturn(List.of(otherAccount, schoolAccount));
        when(passwordEncoder.matches("school-password", "school-account")).thenReturn(true);
        when(passwordEncoder.matches("school-password", "other-account")).thenReturn(false);
        when(schoolService.membershipsForUser(1L)).thenReturn(List.of());
        when(authTokenService.issue(schoolAccount)).thenReturn("token");

        LoginResponse response = userService.login(login(phone, "school-password"));

        assertThat(response.getId()).isEqualTo(1L);
    }

    @Test
    void phoneLoginRejectsAmbiguousMatchingAccountsInsteadOfChoosingArbitrarily() {
        String phone = "+237699000000";
        User firstAccount = user(1L, "same-password");
        User secondAccount = user(2L, "same-password");

        when(userRepository.findByUsername(phone)).thenReturn(Optional.empty());
        when(userRepository.findByEmailIgnoreCase(phone)).thenReturn(Optional.empty());
        when(phoneNumberService.lookupCandidates(phone)).thenReturn(Set.of(phone));
        when(userRepository.findByPhone(phone)).thenReturn(List.of(firstAccount, secondAccount));
        when(passwordEncoder.matches("password", "same-password")).thenReturn(true);

        assertThatThrownBy(() -> userService.login(login(phone, "password")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Connectez-vous avec l'adresse e-mail");
    }

    private static User user(Long id, String encodedPassword) {
        User user = new User();
        user.setId(id);
        user.setUsername("user-" + id);
        user.setPassword(encodedPassword);
        user.setRole(UserRole.MEMBRE);
        user.setActive(true);
        return user;
    }

    private static LoginRequest login(String phone, String password) {
        LoginRequest request = new LoginRequest();
        request.setUsername(phone);
        request.setPassword(password);
        return request;
    }
}
