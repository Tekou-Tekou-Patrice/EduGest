package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Arrays;
import java.util.Optional;

@Service
public class UserSecurityContextService {
    private final UserRepository userRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final SchoolContextService schoolContextService;
    private final AuthTokenService authTokenService;

    public UserSecurityContextService(UserRepository userRepository,
                                      SchoolMembershipRepository membershipRepository,
                                      SchoolContextService schoolContextService,
                                      AuthTokenService authTokenService) {
        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
        this.schoolContextService = schoolContextService;
        this.authTokenService = authTokenService;
    }

    public HttpServletRequest getCurrentRequest() {
        ServletRequestAttributes attributes =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        return attributes != null ? attributes.getRequest() : null;
    }

    public Long getCurrentUserId() {
        HttpServletRequest request = getCurrentRequest();
        return request == null
                ? null
                : authTokenService.verifyAndGetUserId(request.getHeader("Authorization"));
    }

    public Optional<User> getCurrentUser() {
        Long userId = getCurrentUserId();
        if (userId == null) return Optional.empty();
        return userRepository.findById(userId).filter(User::isActive);
    }

    public UserRole getCurrentRole() {
        Optional<User> userOpt = getCurrentUser();
        if (userOpt.isEmpty()) return null;
        User user = userOpt.get();

        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId != null) {
            Optional<SchoolMembership> membership = membershipRepository
                    .findByUserIdAndSchoolId(user.getId(), schoolId)
                    .filter(SchoolMembership::isActive);
            if (membership.isPresent()) return membership.get().getRole();
        }
        return user.getRole();
    }

    public String getCurrentRoleName() {
        UserRole role = getCurrentRole();
        return role != null ? role.toValue() : null;
    }

    public String getCurrentUserDisplayName() {
        return getCurrentUser()
                .map(u -> u.getFullName() != null && !u.getFullName().isBlank()
                        ? u.getFullName() : u.getUsername())
                .orElse("Système");
    }

    public void requireUserOrStaff(Long targetUserId) {
        Long currentUserId = getCurrentUserId();
        if (currentUserId == null) {
            throw new org.springframework.security.access.AccessDeniedException("Authentification requise.");
        }
        UserRole role = getCurrentRole();
        if (!currentUserId.equals(targetUserId)
                && role != UserRole.FONDATEUR
                && role != UserRole.PROVISEUR
                && role != UserRole.CENSEUR
                && role != UserRole.SECRETAIRE
                && role != UserRole.COMPTABLE) {
            throw new org.springframework.security.access.AccessDeniedException("Accès refusé.");
        }
    }

    public boolean hasAnyRole(UserRole... allowedRoles) {
        UserRole currentRole = getCurrentRole();
        if (currentRole == null) return false;
        if (currentRole == UserRole.FONDATEUR) return true;
        return Arrays.asList(allowedRoles).contains(currentRole);
    }

    public void requireAnyRole(UserRole... allowedRoles) {
        if (!hasAnyRole(allowedRoles)) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Accès refusé : rôle insuffisant pour exécuter cette action.");
        }
    }
}
