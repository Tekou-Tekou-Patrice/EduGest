package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.LoginRequest;
import com.eduguest.Edu.DTO.LoginResponse;
import com.eduguest.Edu.DTO.PasswordChangeRequest;
import com.eduguest.Edu.DTO.RegisterRequest;
import com.eduguest.Edu.DTO.UserDto;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.UserRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.PaymentRepository;
import com.eduguest.Edu.Repository.ExpenseRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.VerificationCodeRepository;
import com.eduguest.Edu.Repository.AppNotificationRepository;
import com.eduguest.Edu.Repository.DeviceTokenRepository;
import com.eduguest.Edu.Repository.SchoolInfoRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.LinkedHashMap;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final SchoolService schoolService;
    private final SchoolMembershipRepository membershipRepository;
    private final SchoolContextService schoolContextService;
    private final AuthTokenService authTokenService;
    private final UserSecurityContextService securityContextService;
    private final VerificationService verificationService;
    private final PaymentRepository paymentRepository;
    private final ExpenseRepository expenseRepository;
    private final StudentRepository studentRepository;
    private final VerificationCodeRepository verificationCodeRepository;
    private final PhoneNumberService phoneNumberService;
    private final AppNotificationRepository appNotificationRepository;
    private final DeviceTokenRepository deviceTokenRepository;
    private final SchoolInfoRepository schoolInfoRepository;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       SchoolService schoolService,
                       SchoolMembershipRepository membershipRepository,
                       SchoolContextService schoolContextService,
                       AuthTokenService authTokenService,
                       UserSecurityContextService securityContextService,
                       VerificationService verificationService,
                       PaymentRepository paymentRepository,
                       ExpenseRepository expenseRepository,
                       StudentRepository studentRepository,
                       VerificationCodeRepository verificationCodeRepository,
                       PhoneNumberService phoneNumberService,
                       AppNotificationRepository appNotificationRepository,
                       DeviceTokenRepository deviceTokenRepository,
                       SchoolInfoRepository schoolInfoRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.schoolService = schoolService;
        this.membershipRepository = membershipRepository;
        this.schoolContextService = schoolContextService;
        this.authTokenService = authTokenService;
        this.securityContextService = securityContextService;
        this.verificationService = verificationService;
        this.paymentRepository = paymentRepository;
        this.expenseRepository = expenseRepository;
        this.studentRepository = studentRepository;
        this.verificationCodeRepository = verificationCodeRepository;
        this.phoneNumberService = phoneNumberService;
        this.appNotificationRepository = appNotificationRepository;
        this.deviceTokenRepository = deviceTokenRepository;
        this.schoolInfoRepository = schoolInfoRepository;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        String login = request.getUsername() != null ? request.getUsername().trim() : "";

        User directMatch = userRepository.findByUsername(login)
                .or(() -> userRepository.findByEmailIgnoreCase(login))
                .orElse(null);
        User user = null;
        if (login.contains("@")) {
            if (directMatch != null
                    && passwordEncoder.matches(request.getPassword(), directMatch.getPassword())) {
                user = directMatch;
            }
        } else {
            LinkedHashMap<Long, User> phoneMatches = new LinkedHashMap<>();
            for (String candidate : phoneNumberService.lookupCandidates(login)) {
                for (User candidateUser : userRepository.findByPhone(candidate)) {
                    phoneMatches.putIfAbsent(candidateUser.getId(), candidateUser);
                }
            }

            LinkedHashMap<Long, User> matchingPassword = phoneMatches.values().stream()
                    .filter(candidate -> passwordEncoder.matches(
                            request.getPassword(), candidate.getPassword()))
                    .collect(Collectors.toMap(
                            User::getId,
                            candidate -> candidate,
                            (first, ignored) -> first,
                            LinkedHashMap::new));
            if (directMatch != null
                    && passwordEncoder.matches(request.getPassword(), directMatch.getPassword())) {
                matchingPassword.putIfAbsent(directMatch.getId(), directMatch);
            }
            if (matchingPassword.size() == 1) {
                user = matchingPassword.values().iterator().next();
            } else if (matchingPassword.size() > 1) {
                throw new IllegalArgumentException(
                        "Plusieurs comptes utilisent ce numéro. Connectez-vous avec l'adresse e-mail de votre compte.");
            } else if (!phoneMatches.isEmpty() || directMatch != null) {
                throw new RuntimeException("Mot de passe incorrect");
            }
        }

        if (user == null) {
            if (directMatch != null) {
                throw new RuntimeException("Mot de passe incorrect");
            }
            throw new RuntimeException("Utilisateur non trouvé");
        }

        if (!user.isActive()) {
            throw new RuntimeException("Compte désactivé");
        }

        if (request.getRole() != null && user.getRole() != request.getRole()) {
            throw new RuntimeException("Rôle incorrect pour ce compte");
        }

        String displayName = user.getFullName() != null && !user.getFullName().isBlank()
                ? user.getFullName()
                : user.getUsername();

        List<com.eduguest.Edu.DTO.SchoolMembershipDto> schools = schoolService.membershipsForUser(user.getId());
        return new LoginResponse(
                user.getId(),
                displayName,
                user.getEmail(),
                user.getRole(),
                authTokenService.issue(user),
                schools.isEmpty() ? null : schools.get(0).getSchoolId(),
                schools
        );
    }

    @Transactional
    public UserDto register(RegisterRequest request) {
        String email = request.getEmail() == null ? "" : request.getEmail().trim();
        String phone = phoneNumberService.normalize(request.getPhone());
        if (email.isBlank() && phone.isBlank()) {
            throw new IllegalArgumentException("Un email ou un numéro de téléphone est obligatoire");
        }
        Long schoolId = request.getSchoolId() != null
                ? request.getSchoolId()
                : schoolContextService.currentSchoolId();
        boolean schoolStaffRegistration = schoolId != null;

        if (!email.isBlank()) {
            User existing = userRepository.findByEmailIgnoreCase(email).orElse(null);
            if (existing != null) {
                if (existing.isActive()) {
                    throw new RuntimeException("Cette adresse e-mail existe déjà");
                }
                existing.setPassword(passwordEncoder.encode(request.getPassword()));
                existing.setFullName(request.getFullName() != null && !request.getFullName().isBlank()
                        ? request.getFullName().trim() : existing.getUsername());
                existing.setPhone(phone.isBlank() ? null : phone);
                if (schoolStaffRegistration) {
                    authorizeStaffRecruitment(request, schoolId);
                }
                User saved = userRepository.save(existing);
                verificationCodeRepository.deleteAll(verificationCodeRepository.findByUserId(saved.getId()));
                String verificationCode = verificationService.issue(saved, "REGISTRATION");
                UserDto response = toDto(saved);
                if (verificationService.isLocalCodeEnabled()) {
                    response.setVerificationCode(verificationCode);
                }
                if (schoolStaffRegistration) {
                    com.eduguest.Edu.Entity.School school = schoolService.getRequired(schoolId);
                    var info = schoolInfoRepository.findById("SCHOOL_" + schoolId).orElse(null);
                    verificationService.sendWelcome(
                            saved,
                            school.getName(),
                            info != null ? info.getEmail() : school.getFounderEmail(),
                            info != null ? info.getPhone() : school.getFounderPhone(),
                            request.getLanguage());
                }
                return response;
            }
        }

        // Le nom complet n'est pas un identifiant : seul l'e-mail doit être unique.
        String username = email.isBlank() ? phone : email;
        if (userRepository.existsByUsername(username)) {
            String baseUsername = username;
            int suffix = 2;
            while (userRepository.existsByUsername(username)) {
                String suffixText = "-" + suffix++;
                int maxBaseLength = 100 - suffixText.length();
                username = baseUsername.substring(0, Math.min(baseUsername.length(), maxBaseLength))
                        + suffixText;
            }
        }

        User user = new User();
        user.setUsername(username);
        user.setEmail(email.isBlank() ? null : email);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName() != null && !request.getFullName().isBlank()
                ? request.getFullName().trim()
                : username);
        user.setPhone(phone.isBlank() ? null : phone);
        if (schoolStaffRegistration) {
            if (request.getPhone() == null || request.getPhone().isBlank()) {
                throw new IllegalArgumentException(
                        "Le numéro de téléphone est obligatoire pour recruter un membre du staff.");
            }
            authorizeStaffRecruitment(request, schoolId);
        }
        user.setRole(schoolStaffRegistration && request.getRole() != null
                ? request.getRole() : UserRole.MEMBRE);
        user.setActive(false);

        User saved = userRepository.save(user);
        if (schoolStaffRegistration) {
            com.eduguest.Edu.Entity.School school = schoolService.getRequired(schoolId);
            schoolService.addMembership(saved, school, saved.getRole());
        }
        String verificationCode = verificationService.issue(saved, "REGISTRATION");
        UserDto response = toDto(saved);
        if (verificationService.isLocalCodeEnabled()) {
            response.setVerificationCode(verificationCode);
        }
        if (schoolStaffRegistration) {
            com.eduguest.Edu.Entity.School school = schoolService.getRequired(schoolId);
            var info = schoolInfoRepository.findById("SCHOOL_" + schoolId).orElse(null);
            verificationService.sendWelcome(
                    saved,
                    school.getName(),
                    info != null ? info.getEmail() : school.getFounderEmail(),
                    info != null ? info.getPhone() : school.getFounderPhone(),
                    request.getLanguage());
        }
        return response;
    }

    @Transactional
    public void verifyRegistration(Long userId, String code) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        verificationService.verify(user, "REGISTRATION", code);
        user.setActive(true);
        userRepository.save(user);
    }

    @Transactional
    public void requestPasswordChangeCode(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        verificationService.issue(user, "PASSWORD_CHANGE");
    }

    @Transactional
    public void confirmPasswordChange(Long userId, String code, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        verificationService.verify(user, "PASSWORD_CHANGE", code);
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    @Transactional
    public void requestPasswordReset(String contact) {
        String value = contact == null ? "" : contact.trim();
        User user = userRepository.findByEmailIgnoreCase(value)
                .or(() -> findByPhoneCandidates(value))
                .orElseThrow(() -> new RuntimeException("Aucun compte trouvé avec ce contact"));
        verificationService.issue(user, "PASSWORD_RESET");
    }

    @Transactional
    public void resetPassword(String contact, String code, String newPassword) {
        String value = contact == null ? "" : contact.trim();
        User user = userRepository.findByEmailIgnoreCase(value)
                .or(() -> findByPhoneCandidates(value))
                .orElseThrow(() -> new RuntimeException("Aucun compte trouvé avec ce contact"));
        verificationService.verify(user, "PASSWORD_RESET", code);
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setActive(true);
        userRepository.save(user);
    }

    private java.util.Optional<User> findByPhoneCandidates(String phone) {
        return phoneNumberService.lookupCandidates(phone).stream()
                .map(userRepository::findFirstByPhone)
                .flatMap(java.util.Optional::stream)
                .findFirst();
    }

    private void authorizeStaffRecruitment(RegisterRequest request, Long schoolId) {
        if (request.getRegisteredByUserId() == null || request.getRole() == null) {
            throw new IllegalArgumentException("Le recruteur et le rôle sont obligatoires");
        }
        if (!request.getRegisteredByUserId().equals(securityContextService.getCurrentUserId())) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Le recrutement doit être effectué depuis une session authentifiée du recruteur.");
        }
        User recruiter = userRepository.findById(request.getRegisteredByUserId())
                .orElseThrow(() -> new IllegalArgumentException("Recruteur introuvable"));
        UserRole recruiterRole = membershipRepository
                .findByUserIdAndSchoolId(recruiter.getId(), schoolId)
                .filter(com.eduguest.Edu.Entity.SchoolMembership::isActive)
                .map(com.eduguest.Edu.Entity.SchoolMembership::getRole)
                .orElseThrow(() -> new IllegalArgumentException("Le recruteur n'appartient pas à cette école"));

        boolean allowed = recruiterRole == UserRole.FONDATEUR
                || (recruiterRole == UserRole.PROVISEUR && request.getRole() == UserRole.SECRETAIRE)
                || (recruiterRole == UserRole.SECRETAIRE && request.getRole() != UserRole.FONDATEUR
                        && request.getRole() != UserRole.PROVISEUR
                        && request.getRole() != UserRole.SECRETAIRE);
        if (!allowed) {
            throw new IllegalArgumentException("Vous n'êtes pas autorisé à recruter ce rôle");
        }
    }

    @Transactional
    public void changePassword(Long userId, PasswordChangeRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new RuntimeException("L'ancien mot de passe est incorrect");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public List<UserDto> findAll() {
        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId == null) return List.of();
        return membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(schoolId)
                .stream().map(membership -> toDto(membership.getUser()))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserDto> findStaff() {
        return findAll().stream()
                .filter(user -> user.getRole() != UserRole.PARENT)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteUser(Long id) {
        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId == null || membershipRepository.findByUserIdAndSchoolId(id, schoolId).isEmpty()) {
            throw new IllegalArgumentException("Cet utilisateur n'appartient pas à l'école active");
        }
        if (!userRepository.existsById(id)) {
            throw new RuntimeException("Utilisateur non trouvé");
        }
        User user = userRepository.findById(id).orElseThrow();
        paymentRepository.findAll().stream()
                .filter(payment -> payment.getRecordedBy() != null
                        && id.equals(payment.getRecordedBy().getId()))
                .forEach(payment -> payment.setRecordedBy(null));
        expenseRepository.findAll().stream()
                .filter(expense -> expense.getRecordedBy() != null
                        && id.equals(expense.getRecordedBy().getId()))
                .forEach(expense -> expense.setRecordedBy(null));
        studentRepository.findAll().stream()
                .filter(student -> student.getRegisteredBy() != null
                        && id.equals(student.getRegisteredBy().getId()))
                .forEach(student -> student.setRegisteredBy(null));
        verificationCodeRepository.deleteAll(verificationCodeRepository.findByUserId(id));
        appNotificationRepository.deleteByRecipientId(id);
        deviceTokenRepository.deleteByUserId(id);
        membershipRepository.deleteAll(membershipRepository.findByUserId(id));
        userRepository.deleteById(id);
    }

    private UserDto toDto(User user) {
        UserDto dto = new UserDto();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setFullName(user.getFullName());
        dto.setPhone(user.getPhone());
        dto.setRole(user.getRole());
        dto.setActive(user.isActive());
        dto.setSchools(schoolService.membershipsForUser(user.getId()));
        if (dto.getSchools() != null && !dto.getSchools().isEmpty()) {
            dto.setSelectedSchoolId(dto.getSchools().get(0).getSchoolId());
        }
        return dto;
    }
}
