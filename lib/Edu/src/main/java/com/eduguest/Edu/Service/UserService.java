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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
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

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       SchoolService schoolService,
                       SchoolMembershipRepository membershipRepository,
                       SchoolContextService schoolContextService,
                       AuthTokenService authTokenService,
                       UserSecurityContextService securityContextService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.schoolService = schoolService;
        this.membershipRepository = membershipRepository;
        this.schoolContextService = schoolContextService;
        this.authTokenService = authTokenService;
        this.securityContextService = securityContextService;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        String login = request.getUsername() != null ? request.getUsername().trim() : "";

        User user = userRepository.findByUsername(login)
                .or(() -> userRepository.findByEmail(login))
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Mot de passe incorrect");
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
        if (email.isBlank()) {
            throw new IllegalArgumentException("L'email est obligatoire");
        }

        String username = request.getUsername() != null && !request.getUsername().isBlank()
                ? request.getUsername().trim()
                : email;

        if (userRepository.existsByUsername(username)) {
            throw new RuntimeException("Le nom d'utilisateur existe déjà");
        }
        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("L'email existe déjà");
        }

        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName() != null && !request.getFullName().isBlank()
                ? request.getFullName().trim()
                : username);
        user.setPhone(request.getPhone());
        boolean schoolStaffRegistration = request.getSchoolId() != null;
        if (schoolStaffRegistration) {
            if (request.getPhone() == null || request.getPhone().isBlank()) {
                throw new IllegalArgumentException(
                        "Le numéro de téléphone est obligatoire pour recruter un membre du staff.");
            }
            authorizeStaffRecruitment(request);
        }
        user.setRole(schoolStaffRegistration && request.getRole() != null
                ? request.getRole() : UserRole.MEMBRE);
        user.setActive(true);

        User saved = userRepository.save(user);
        if (schoolStaffRegistration) {
            com.eduguest.Edu.Entity.School school = schoolService.getRequired(request.getSchoolId());
            schoolService.addMembership(saved, school, saved.getRole());
        }
        return toDto(saved);
    }

    private void authorizeStaffRecruitment(RegisterRequest request) {
        if (request.getRegisteredByUserId() == null || request.getRole() == null) {
            throw new IllegalArgumentException("Le recruteur et le rôle sont obligatoires");
        }
        Long schoolId = request.getSchoolId();
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
