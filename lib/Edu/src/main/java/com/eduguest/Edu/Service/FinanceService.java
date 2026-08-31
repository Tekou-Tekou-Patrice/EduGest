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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
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
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;


    public FinanceService(PaymentRepository paymentRepository, 
                          ExpenseRepository expenseRepository,
                          UserRepository userRepository,
                          AcademicYearService academicYearService,
                          StudentRepository studentRepository,
                          SchoolContextService schoolContextService,
                          AppNotificationService notificationService) {
        this.schoolContextService = schoolContextService;
        this.paymentRepository = paymentRepository;
        this.expenseRepository = expenseRepository;
        this.userRepository = userRepository;
        this.academicYearService = academicYearService;
        this.studentRepository = studentRepository;
        this.notificationService = notificationService;
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
        notificationService.notifyPayment(saved);
        return mapToPaymentDto(saved);
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
        
        return mapToExpenseDto(expenseRepository.save(expense));
    }

    @Transactional
    public void deleteExpense(Long id) {
        if (!expenseRepository.existsById(id)) {
            throw new RuntimeException("Dépense non trouvée");
        }
        expenseRepository.findById(id).ifPresent(expense -> {
            schoolContextService.verifyAndAssign(expense);
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
        stats.put("balance", revenue - expenses);
        stats.put("currency", "FCFA");
        return stats;
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
                double tuition = student.getClassroom() != null && student.getClassroom().getTuitionFee() != null
                        ? student.getClassroom().getTuitionFee() : 0;
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
