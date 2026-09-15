package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ExpenseDto;
import com.eduguest.Edu.DTO.PaymentDto;
import com.eduguest.Edu.Entity.Expense;
import com.eduguest.Edu.Entity.Payment;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Repository.ExpenseRepository;
import com.eduguest.Edu.Repository.PaymentRepository;
import com.eduguest.Edu.Repository.UserRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.ClassroomRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class FinanceService {
    private final PaymentRepository paymentRepository;
    private final ExpenseRepository expenseRepository;
    private final UserRepository userRepository;
    private final AcademicYearService academicYearService;
    private final StudentRepository studentRepository;
    private final ClassroomRepository classroomRepository;
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;
    private final AuditLogService auditLogService;

    public FinanceService(PaymentRepository paymentRepository, 
                          ExpenseRepository expenseRepository,
                          UserRepository userRepository,
                          AcademicYearService academicYearService,
                          StudentRepository studentRepository,
                          ClassroomRepository classroomRepository,
                          SchoolContextService schoolContextService,
                          AppNotificationService notificationService,
                          AuditLogService auditLogService) {
        this.schoolContextService = schoolContextService;
        this.paymentRepository = paymentRepository;
        this.expenseRepository = expenseRepository;
        this.userRepository = userRepository;
        this.academicYearService = academicYearService;
        this.studentRepository = studentRepository;
        this.classroomRepository = classroomRepository;
        this.notificationService = notificationService;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public List<PaymentDto> getAllPayments() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(paymentRepository.findAll()), Payment::getAcademicYearId)
                .stream().map(this::mapToPaymentDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PaymentDto> getParentPayments(Long parentId) {
        User parent = userRepository.findById(parentId)
                .orElseThrow(() -> new IllegalArgumentException("Parent introuvable"));
        List<Long> childIds = schoolContextService
                .scope(studentRepository.findByParentContact("", parent.getEmail()))
                .stream().map(student -> student.getId()).toList();
        if (childIds.isEmpty()) return List.of();
        return academicYearService.filterCurrentYear(schoolContextService.scope(paymentRepository.findAll()),
                        Payment::getAcademicYearId)
                .stream()
                .filter(payment -> childIds.contains(parseId(payment.getStudentId())))
                .map(this::mapToPaymentDto)
                .collect(Collectors.toList());
    }

    private Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value);
        } catch (NumberFormatException ignored) {
            return null;
        }
    }

    @Transactional
    public List<PaymentDto> getRecentPayments() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(paymentRepository.findRecentPayments(), Payment::getAcademicYearId)
                .stream().map(this::mapToPaymentDto).collect(Collectors.toList());
    }

    @Transactional
    public Double getTotalRevenue() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(paymentRepository.findAll()), Payment::getAcademicYearId)
                .stream().mapToDouble(p -> p.getAmount() != null ? p.getAmount() : 0).sum();
    }

    @Transactional
    public PaymentDto createPayment(PaymentDto dto) {
        Payment payment = new Payment();
        payment.setStudentId(dto.getStudentId());
        payment.setStudentName(dto.getStudentName());
        payment.setAmount(dto.getAmount());
        payment.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        payment.setDescription(dto.getDescription());
        try {
            payment.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            payment.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        
        if (dto.getRecordedById() != null) {
            userRepository.findById(dto.getRecordedById()).ifPresent(payment::setRecordedBy);
        }
        
        schoolContextService.verifyAndAssign(payment);
        
        Payment saved = paymentRepository.save(payment);

        try {
            auditLogService.logAction(
                    "CREATE",
                    "PAIEMENT",
                    saved.getId().toString(),
                    "Enregistrement paiement de " + Math.round(saved.getAmount()) + " FCFA pour l'élève " + saved.getStudentName(),
                    null,
                    Math.round(saved.getAmount()) + " FCFA - " + (saved.getDescription() != null ? saved.getDescription() : "Scolarité")
            );
        } catch (Exception ignored) {}

        notificationService.notifyPayment(saved);
        return mapToPaymentDto(saved);
    }

    @Transactional
    public void deletePayment(Long id) {
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Paiement introuvable"));
        schoolContextService.verifyAndAssign(payment);

        try {
            auditLogService.logAction(
                    "DELETE",
                    "PAIEMENT",
                    id.toString(),
                    "Suppression paiement élève " + payment.getStudentName() + " (" + Math.round(payment.getAmount()) + " FCFA)",
                    Math.round(payment.getAmount()) + " FCFA (" + payment.getDescription() + ")",
                    "Supprimé"
            );
        } catch (Exception ignored) {}

        paymentRepository.delete(payment);
    }

    @Transactional
    public List<ExpenseDto> getAllExpenses() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(expenseRepository.findAllOrdered()), Expense::getAcademicYearId)
                .stream().map(this::mapToExpenseDto).collect(Collectors.toList());
    }

    @Transactional
    public ExpenseDto createExpense(ExpenseDto dto) {
        Expense expense = new Expense();
        expense.setTitle(dto.getTitle());
        expense.setCategory(dto.getCategory());
        expense.setAmount(dto.getAmount());
        expense.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        expense.setDescription(dto.getDescription());
        try {
            expense.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            expense.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        
        if (dto.getRecordedById() != null) {
            userRepository.findById(dto.getRecordedById()).ifPresent(expense::setRecordedBy);
        }
        
        schoolContextService.verifyAndAssign(expense);
        Expense saved = expenseRepository.save(expense);

        try {
            auditLogService.logAction(
                    "CREATE",
                    "DEPENSE",
                    saved.getId().toString(),
                    "Enregistrement dépense : " + saved.getTitle() + " (" + Math.round(saved.getAmount()) + " FCFA)",
                    null,
                    saved.getCategory() + " - " + Math.round(saved.getAmount()) + " FCFA"
            );
        } catch (Exception ignored) {}

        return mapToExpenseDto(saved);
    }

    @Transactional
    public void deleteExpense(Long id) {
        if (!expenseRepository.existsById(id)) {
            throw new RuntimeException("Dépense non trouvée");
        }
        expenseRepository.findById(id).ifPresent(expense -> {
            schoolContextService.verifyAndAssign(expense);

            try {
                auditLogService.logAction(
                        "DELETE",
                        "DEPENSE",
                        id.toString(),
                        "Suppression dépense : " + expense.getTitle() + " (" + Math.round(expense.getAmount()) + " FCFA)",
                        expense.getTitle() + " - " + Math.round(expense.getAmount()) + " FCFA",
                        "Supprimé"
                );
            } catch (Exception ignored) {}

            expenseRepository.delete(expense);
        });
    }

    @Transactional
    public Map<String, Object> getFinanceStats() {
        academicYearService.autoCloseIfDue();
        Double revenue = getTotalRevenue();
        Double expenses = academicYearService.filterCurrentYear(schoolContextService.scope(expenseRepository.findAll()), Expense::getAcademicYearId)
                .stream().mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0).sum();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalRevenue", revenue);
        stats.put("totalExpenses", expenses);
        stats.put("balance", Math.max(0, revenue - expenses));
        stats.put("currency", "FCFA");
        return stats;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getTuitionStatus() {
        academicYearService.autoCloseIfDue();
        List<Payment> payments = academicYearService.filterCurrentYear(
                schoolContextService.scope(paymentRepository.findAll()),
                Payment::getAcademicYearId
        );
        Map<String, Double> paidByStudent = new HashMap<>();
        for (Payment payment : payments) {
            if (payment.getStudentId() != null && !"SIMPLE".equals(payment.getStudentId())) {
                paidByStudent.merge(
                        payment.getStudentId(),
                        payment.getAmount() == null ? 0 : payment.getAmount(),
                        Double::sum
                );
            }
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (var student : schoolContextService.scope(studentRepository.findAll())) {
            double tuition = tuitionFor(student);
            double paid = paidByStudent.getOrDefault(String.valueOf(student.getId()), 0.0);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("studentId", student.getId());
            item.put("studentName", (student.getFirstName() + " " + student.getLastName()).trim());
            item.put("className", student.getClassName());
            item.put("totalTuition", tuition);
            item.put("totalPaid", paid);
            item.put("remaining", Math.max(0, tuition - paid));
            item.put("tuitionCompleted", tuition > 0 && paid >= tuition);
            result.add(item);
        }
        return result;
    }

    private PaymentDto mapToPaymentDto(Payment entity) {
        PaymentDto dto = new PaymentDto();
        dto.setId(entity.getId());
        dto.setStudentId(entity.getStudentId());
        dto.setStudentName(entity.getStudentName());
        dto.setAmount(entity.getAmount());
        dto.setDate(entity.getDate());
        dto.setDescription(entity.getDescription());
        if (entity.getRecordedBy() != null) {
            dto.setRecordedById(entity.getRecordedBy().getId());
            dto.setRecordedByName(entity.getRecordedBy().getFullName());
        }
        if (entity.getStudentId() != null && !"SIMPLE".equals(entity.getStudentId())) {
            studentRepository.findById(Long.valueOf(entity.getStudentId())).ifPresent(student -> {
                double tuition = tuitionFor(student);
                double paid = schoolContextService.scope(paymentRepository.findByStudentId(entity.getStudentId())).stream()
                        .filter(p -> p.getAcademicYearId() == null || p.getAcademicYearId().equals(entity.getAcademicYearId()))
                        .mapToDouble(p -> p.getAmount() == null ? 0 : p.getAmount()).sum();
                dto.setTotalTuition(tuition);
                dto.setTotalPaid(paid);
                dto.setRemaining(Math.max(0, tuition - paid));
                dto.setTuitionCompleted(tuition > 0 && paid >= tuition);
            });
        }
        return dto;
    }

    private double tuitionFor(com.eduguest.Edu.Entity.Student student) {
        if (student.getClassroom() != null && student.getClassroom().getTuitionFee() != null) {
            return Math.max(0, student.getClassroom().getTuitionFee());
        }
        if (student.getClassName() == null || student.getClassName().isBlank()) return 0;
        return schoolContextService.scope(classroomRepository.findAll()).stream()
                .filter(classroom -> classroom.getName() != null
                        && classroom.getName().equalsIgnoreCase(student.getClassName().trim()))
                .map(classroom -> classroom.getTuitionFee() == null ? 0 : classroom.getTuitionFee())
                .findFirst()
                .orElse(0d);
    }

    private ExpenseDto mapToExpenseDto(Expense entity) {
        ExpenseDto dto = new ExpenseDto();
        dto.setId(entity.getId());
        dto.setTitle(entity.getTitle());
        dto.setCategory(entity.getCategory());
        dto.setAmount(entity.getAmount());
        dto.setDate(entity.getDate());
        dto.setDescription(entity.getDescription());
        if (entity.getRecordedBy() != null) {
            dto.setRecordedById(entity.getRecordedBy().getId());
            dto.setRecordedByName(entity.getRecordedBy().getFullName());
        }
        return dto;
    }
}
