package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.SchoolCreateRequest;
import com.eduguest.Edu.DTO.SchoolDto;
import com.eduguest.Edu.DTO.SchoolMembershipDto;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolMembership;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Entity.SubscriptionPayment;
import com.eduguest.Edu.Repository.ClassroomRepository;
import com.eduguest.Edu.Repository.PaymentRepository;
import com.eduguest.Edu.Repository.SchoolMembershipRepository;
import com.eduguest.Edu.Repository.SchoolRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.SubscriptionPaymentRepository;
import com.eduguest.Edu.Repository.TeacherRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SchoolService {
    private final SchoolRepository schoolRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final ClassroomRepository classroomRepository;
    private final PaymentRepository paymentRepository;
    private final SubscriptionPaymentRepository subscriptionPaymentRepository;

    public SchoolService(SchoolRepository schoolRepository,
                         SchoolMembershipRepository membershipRepository,
                         UserRepository userRepository,
                         StudentRepository studentRepository,
                         TeacherRepository teacherRepository,
                         ClassroomRepository classroomRepository,
                         PaymentRepository paymentRepository,
                         SubscriptionPaymentRepository subscriptionPaymentRepository) {
        this.schoolRepository = schoolRepository;
        this.membershipRepository = membershipRepository;
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.teacherRepository = teacherRepository;
        this.classroomRepository = classroomRepository;
        this.paymentRepository = paymentRepository;
        this.subscriptionPaymentRepository = subscriptionPaymentRepository;
    }

    @Transactional
    public SchoolDto create(SchoolCreateRequest request) {
        School school = new School();
        school.setName(request.getName().trim());
        school.setCode(normalizeCode(request.getCode(), request.getName()));
        school.setSchoolLevel(normalizeSchoolLevel(request.getSchoolLevel()));
        school.setActive(true);
        school.setSubscriptionStatus("ACTIVE");
        school.setSubscriptionExpiresAt(LocalDate.now().plusMonths(1));
        school.setMonthlyFee(25000.0);
        school.setPlanName("Mensuel Standard");

        if (request.getUserId() != null) {
            userRepository.findById(request.getUserId()).ifPresent(user -> {
                user.setRole(UserRole.FONDATEUR);
                userRepository.save(user);
                school.setFounderName(user.getFullName());
                school.setFounderPhone(user.getPhone());
                school.setFounderEmail(user.getEmail());
            });
        }

        School saved = schoolRepository.save(school);
        if (request.getUserId() != null) {
            userRepository.findById(request.getUserId()).ifPresent(user -> {
                addMembership(user, saved, UserRole.FONDATEUR);
            });
        }
        return toDto(saved, null);
    }

    @Transactional(readOnly = true)
    public List<SchoolMembershipDto> accessibleSchools(Long userId) {
        if (userId == null) {
            return schoolRepository.findAll().stream()
                    .map(this::toMembershipDto)
                    .collect(Collectors.toList());
        }
        return membershipRepository.findByUserIdAndActiveTrueOrderBySchool_Name(userId).stream()
                .map(this::toMembershipDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SchoolMembershipDto select(Long userId, Long schoolId) {
        SchoolMembership membership = membershipRepository.findByUserIdAndSchoolId(userId, schoolId)
                .filter(SchoolMembership::isActive)
                .orElseThrow(() -> new RuntimeException("Utilisateur non membre de cette école"));
        if (!membership.getSchool().isActive()) {
            throw new IllegalStateException("Cette école est désactivée. Contactez l'administration.");
        }
        return toMembershipDto(membership);
    }

    @Transactional
    public SchoolMembershipDto joinByCode(Long userId, String code) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException("Le code de l'école est obligatoire");
        }

        School school = schoolRepository.findByCode(code.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new RuntimeException("Code d'école invalide"));
        if (!school.isActive()) {
            throw new IllegalStateException("Cette école est désactivée. Contactez l'administration.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        SchoolMembership existingMembership = membershipRepository.findByUserIdAndSchoolId(userId, school.getId())
                .orElse(null);
        if (existingMembership == null) {
            throw new IllegalStateException(
                    "Vous devez deja etre enregistre par l'administration de cette ecole avant de la rejoindre.");
        }
        if (!existingMembership.isActive()) {
            existingMembership.setActive(true);
            existingMembership = membershipRepository.save(existingMembership);
        }

        // Le rôle est attribué par l'administration lors de l'inscription.
        // Le code d'école ne doit jamais permettre à l'utilisateur de le modifier.
        return toMembershipDto(existingMembership);
    }

    /**
     * Compatibility overload for existing callers.
     * The requested role is intentionally ignored: the stored membership role
     * assigned by the school administration remains authoritative.
     */
    @Deprecated
    public SchoolMembershipDto joinByCode(Long userId, String code, UserRole ignoredRole) {
        return joinByCode(userId, code);
    }

    @Transactional
    public void updateCode(Long userId, Long schoolId, String code) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        SchoolMembership membership = membershipRepository.findByUserIdAndSchoolId(userId, schoolId)
                .filter(SchoolMembership::isActive)
                .orElseThrow(() -> new RuntimeException("Accès refusé"));
        if (user.getRole() != UserRole.FONDATEUR || membership.getRole() != UserRole.FONDATEUR) {
            throw new RuntimeException("Seul le fondateur peut modifier le code");
        }
        School school = membership.getSchool();
        school.setCode(normalizeCode(code, school.getName()));
        schoolRepository.save(school);
    }

    @Transactional
    public SchoolMembership addMembership(User user, School school, UserRole role) {
        SchoolMembership membership = membershipRepository.findByUserIdAndSchoolId(user.getId(), school.getId())
                .orElseGet(SchoolMembership::new);
        membership.setUser(user);
        membership.setSchool(school);
        membership.setRole(role != null ? role : user.getRole());
        membership.setActive(true);
        return membershipRepository.save(membership);
    }

    @Transactional(readOnly = true)
    public List<SchoolMembershipDto> membershipsForUser(Long userId) {
        return membershipRepository.findByUserIdAndActiveTrueOrderBySchool_Name(userId).stream()
                .filter(membership -> membership.getSchool().isActive())
                .map(this::toMembershipDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SchoolDto> getAllSchools() {
        return schoolRepository.findAll().stream()
                .map(s -> toDto(s, null))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SchoolDto> getSchoolsExpiringWithinSevenDays() {
        LocalDate today = LocalDate.now();
        LocalDate deadline = today.plusDays(7);
        return schoolRepository.findAll().stream()
                .filter(School::isActive)
                .filter(school -> school.getSubscriptionExpiresAt() != null)
                .filter(school -> !school.getSubscriptionExpiresAt().isBefore(today))
                .filter(school -> !school.getSubscriptionExpiresAt().isAfter(deadline))
                .map(school -> toDto(school, null))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getGlobalStats() {
        Map<String, Object> stats = new HashMap<>();
        long totalSchools = schoolRepository.count();
        long activeSchools = schoolRepository.findAll().stream().filter(School::isActive).count();
        long totalStudents = studentRepository.count();
        long totalTeachers = teacherRepository.count();
        long totalClassrooms = classroomRepository.count();
        long totalUsers = userRepository.count();
        long totalPayments = paymentRepository.count();

        stats.put("totalSchools", totalSchools);
        stats.put("activeSchools", activeSchools);
        stats.put("totalStudents", totalStudents);
        stats.put("totalTeachers", totalTeachers);
        stats.put("totalClassrooms", totalClassrooms);
        stats.put("totalUsers", totalUsers);
        stats.put("totalPayments", totalPayments);
        return stats;
    }

    @Transactional
    public SchoolDto renewSubscription(Long schoolId, Long actorId, Integer months, Double amount, String paymentMethod, String ref, String notes) {
        School school = getRequired(schoolId);
        User actor = userRepository.findById(actorId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur de paiement introuvable"));
        SchoolMembership actorMembership = membershipRepository.findByUserIdAndSchoolId(actorId, schoolId)
                .filter(SchoolMembership::isActive)
                .orElseThrow(() -> new IllegalArgumentException("L'utilisateur n'appartient pas à cette école"));
        if (actorMembership.getRole() != UserRole.FONDATEUR
                && actorMembership.getRole() != UserRole.COMPTABLE) {
            throw new IllegalArgumentException("Seul le fondateur ou le comptable peut enregistrer le paiement");
        }
        int addMonths = (months != null && months > 0) ? months : 1;
        LocalDate currentExpiry = school.getSubscriptionExpiresAt();
        LocalDate now = LocalDate.now();

        LocalDate baseDate = (currentExpiry != null && currentExpiry.isAfter(now)) ? currentExpiry : now;
        LocalDate newExpiry = baseDate.plusMonths(addMonths);

        school.setSubscriptionExpiresAt(newExpiry);
        school.setSubscriptionStatus("ACTIVE");
        school.setActive(true);
        School saved = schoolRepository.save(school);

        // Record SaaS revenue
        SubscriptionPayment payment = new SubscriptionPayment();
        payment.setSchoolId(school.getId());
        payment.setSchoolName(school.getName());
        payment.setAmount(amount != null ? amount : (school.getMonthlyFee() != null ? school.getMonthlyFee() * addMonths : 25000.0 * addMonths));
        payment.setPaymentMethod(paymentMethod != null ? paymentMethod : "MTN Mobile Money");
        payment.setTransactionRef(ref);
        payment.setMonthsAdded(addMonths);
        payment.setPlanName(school.getPlanName() != null ? school.getPlanName() : "Abonnement " + addMonths + " mois");
        payment.setExpiresAtAfter(newExpiry);
        payment.setPayerName(school.getFounderName());
        payment.setPayerPhone(school.getFounderPhone());
        payment.setNotes(notes);
        subscriptionPaymentRepository.save(payment);

        return toDto(saved, null);
    }

    @Transactional
    public void saveStaffRenewal(Long schoolId, Long founderId, Map<String, Object> body) {
        SchoolMembership founder = membershipRepository.findByUserIdAndSchoolId(founderId, schoolId)
                .filter(SchoolMembership::isActive)
                .orElseThrow(() -> new IllegalArgumentException("Fondateur introuvable dans cette école"));
        if (founder.getRole() != UserRole.FONDATEUR) {
            throw new IllegalArgumentException("Seul le fondateur peut valider le renouvellement du staff");
        }
        Object decisions = body.get("decisions");
        if (!(decisions instanceof List<?> decisionList)) {
            throw new IllegalArgumentException("La liste des décisions du staff est obligatoire");
        }
        for (Object value : decisionList) {
            if (!(value instanceof Map<?, ?> decision)) continue;
            Long userId = Long.valueOf(decision.get("userId").toString());
            boolean retained = Boolean.parseBoolean(decision.get("retained").toString());
            SchoolMembership membership = membershipRepository.findByUserIdAndSchoolId(userId, schoolId)
                    .orElseThrow(() -> new IllegalArgumentException("Membre du staff introuvable"));
            if (membership.getRole() == UserRole.FONDATEUR) continue;
            membership.setActive(retained);
            membershipRepository.save(membership);
            userRepository.findById(userId).ifPresent(user -> {
                user.setActive(retained);
                userRepository.save(user);
            });
        }
    }

    @Transactional
    public SchoolDto updateSubscription(Long schoolId, Map<String, Object> body) {
        School school = getRequired(schoolId);
        if (body.containsKey("status") && body.get("status") != null) {
            String status = body.get("status").toString().toUpperCase(Locale.ROOT);
            school.setSubscriptionStatus(status);
            school.setActive("ACTIVE".equals(status));
        }
        if (body.containsKey("expiresAt") && body.get("expiresAt") != null) {
            school.setSubscriptionExpiresAt(LocalDate.parse(body.get("expiresAt").toString().substring(0, 10)));
        }
        if (body.containsKey("monthlyFee") && body.get("monthlyFee") != null) {
            school.setMonthlyFee(Double.parseDouble(body.get("monthlyFee").toString()));
        }
        if (body.containsKey("planName") && body.get("planName") != null) {
            school.setPlanName(body.get("planName").toString());
        }
        return toDto(schoolRepository.save(school), null);
    }

    @Transactional
    public SchoolDto updateFounderInfo(Long schoolId, String founderName, String founderPhone, String founderEmail) {
        School school = getRequired(schoolId);
        if (founderName != null) school.setFounderName(founderName.trim());
        if (founderPhone != null) school.setFounderPhone(founderPhone.trim());
        if (founderEmail != null) school.setFounderEmail(founderEmail.trim());

        return toDto(schoolRepository.save(school), null);
    }

    @Transactional
    public SchoolDto toggleStatus(Long schoolId) {
        School school = getRequired(schoolId);
        boolean newActive = !school.isActive();
        school.setActive(newActive);
        school.setSubscriptionStatus(newActive ? "ACTIVE" : "SUSPENDED");
        return toDto(schoolRepository.save(school), null);
    }

    @Transactional
    public void deleteSchool(Long schoolId) {
        membershipRepository.deleteBySchoolId(schoolId);
        schoolRepository.deleteById(schoolId);
    }

    public School getRequired(Long id) {
        return schoolRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("École introuvable"));
    }

    @Transactional(readOnly = true)
    public SchoolDto getSchoolDto(Long id) {
        return toDto(getRequired(id), null);
    }

    private String normalizeCode(String code, String name) {
        String value = code == null || code.isBlank() ? name : code;
        return value.trim().toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]+", "-");
    }

    private SchoolDto toDto(School school, UserRole role) {
        SchoolDto dto = new SchoolDto();
        dto.setId(school.getId());
        dto.setName(school.getName());
        dto.setCode(school.getCode());
        dto.setSchoolLevel(normalizeSchoolLevel(school.getSchoolLevel()));
        dto.setActive(school.isActive());
        dto.setCreatedAt(school.getCreatedAt());
        dto.setMembershipRole(role);

        dto.setSubscriptionStatus(school.getSubscriptionStatus() != null ? school.getSubscriptionStatus() : (school.isActive() ? "ACTIVE" : "SUSPENDED"));
        dto.setSubscriptionExpiresAt(school.getSubscriptionExpiresAt() != null ? school.getSubscriptionExpiresAt() : LocalDate.now().plusMonths(1));
        dto.setMonthlyFee(school.getMonthlyFee() != null ? school.getMonthlyFee() : 25000.0);
        dto.setPlanName(school.getPlanName() != null ? school.getPlanName() : "Mensuel Standard");

        // Founder details fallback from memberships if null on school
        String founderName = school.getFounderName();
        String founderPhone = school.getFounderPhone();
        String founderEmail = school.getFounderEmail();

        if (founderName == null || founderPhone == null) {
            List<SchoolMembership> members = membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(school.getId());
            for (SchoolMembership m : members) {
                User u = m.getUser();
                if (u != null) {
                    if (founderName == null && u.getFullName() != null) founderName = u.getFullName();
                    if (founderPhone == null && u.getPhone() != null) founderPhone = u.getPhone();
                    if (founderEmail == null && u.getEmail() != null) founderEmail = u.getEmail();
                    if (m.getRole() == UserRole.FONDATEUR) {
                        founderName = u.getFullName();
                        founderPhone = u.getPhone();
                        founderEmail = u.getEmail();
                        break;
                    }
                }
            }
        }

        dto.setFounderName(founderName != null ? founderName : "Non renseigné");
        dto.setFounderPhone(founderPhone != null ? founderPhone : "");
        dto.setFounderEmail(founderEmail != null ? founderEmail : "");

        membershipRepository.findBySchoolIdAndActiveTrueOrderByUser_FullName(school.getId()).stream()
                .filter(membership -> membership.getRole() == UserRole.SECRETAIRE)
                .map(SchoolMembership::getUser)
                .findFirst()
                .ifPresent(secretary -> {
                    dto.setSecretaryName(secretary.getFullName());
                    dto.setSecretaryPhone(secretary.getPhone());
                    dto.setSecretaryEmail(secretary.getEmail());
                });

        return dto;
    }

    private SchoolMembershipDto toMembershipDto(SchoolMembership membership) {
        SchoolMembershipDto dto = new SchoolMembershipDto();
        dto.setId(membership.getId());
        dto.setUserId(membership.getUser().getId());
        dto.setSchoolId(membership.getSchool().getId());
        dto.setSchoolName(membership.getSchool().getName());
        dto.setSchoolCode(membership.getSchool().getCode());
        dto.setSchoolLevel(normalizeSchoolLevel(membership.getSchool().getSchoolLevel()));
        dto.setRole(membership.getRole());
        dto.setActive(membership.isActive());
        return dto;
    }

    private SchoolMembershipDto toMembershipDto(School school) {
        SchoolMembershipDto dto = new SchoolMembershipDto();
        dto.setSchoolId(school.getId());
        dto.setSchoolName(school.getName());
        dto.setSchoolCode(school.getCode());
        dto.setSchoolLevel(normalizeSchoolLevel(school.getSchoolLevel()));
        dto.setActive(school.isActive());
        return dto;
    }

    private String normalizeSchoolLevel(String value) {
        if ("PRIMARY".equalsIgnoreCase(value)) return "PRIMARY";
        if ("COLLEGE".equalsIgnoreCase(value)) return "COLLEGE";
        if ("LYCEE".equalsIgnoreCase(value)) return "LYCEE";
        return "COLLEGE";
    }

    private SchoolMembershipDto toMembershipDto(SchoolDto school) {
        SchoolMembershipDto dto = new SchoolMembershipDto();
        dto.setSchoolId(school.getId());
        dto.setSchoolName(school.getName());
        dto.setSchoolCode(school.getCode());
        dto.setSchoolLevel(normalizeSchoolLevel(school.getSchoolLevel()));
        dto.setActive(school.isActive());
        return dto;
    }
}
