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

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       SchoolService schoolService,
                       SchoolMembershipRepository membershipRepository,
                       SchoolContextService schoolContextService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.schoolService = schoolService;
        this.membershipRepository = membershipRepository;
        this.schoolContextService = schoolContextService;
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
                "session-" + user.getId(),
                schools.isEmpty() ? null : schools.get(0).getSchoolId(),
                schools
        );
    }

    @Transactional
    public UserDto register(RegisterRequest request) {
        String username = request.getUsername() != null && !request.getUsername().isBlank()
                ? request.getUsername().trim()
                : request.getEmail().trim();
        String email = request.getEmail().trim();

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
        user.setFullName(request.getFullName());
        user.setPhone(request.getPhone());
        boolean schoolStaffRegistration = request.getSchoolId() != null;
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
