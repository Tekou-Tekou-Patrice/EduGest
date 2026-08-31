package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ExpenseDto;
import com.eduguest.Edu.DTO.PaymentDto;
import com.eduguest.Edu.Service.FinanceService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/finance")
public class FinanceController {

    private final FinanceService financeService;

    public FinanceController(FinanceService financeService) {
        this.financeService = financeService;
    }

    @GetMapping("/payments")
    public ResponseEntity<List<PaymentDto>> getAllPayments() {
        try {
            return ResponseEntity.ok(financeService.getAllPayments());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/parents/{parentId}/payments")
    public ResponseEntity<List<PaymentDto>> getParentPayments(@PathVariable Long parentId) {
        try {
            return ResponseEntity.ok(financeService.getParentPayments(parentId));
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/recent")
    public ResponseEntity<List<PaymentDto>> getRecentPayments() {
        try {
            return ResponseEntity.ok(financeService.getRecentPayments());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getFinanceStats() {
        try {
            return ResponseEntity.ok(financeService.getFinanceStats());
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of());
        }
    }

    @PostMapping("/payments")
    public ResponseEntity<PaymentDto> createPayment(@Valid @RequestBody PaymentDto dto) {
        return ResponseEntity.ok(financeService.createPayment(dto));
    }

    @GetMapping("/expenses")
    public ResponseEntity<List<ExpenseDto>> getAllExpenses() {
        try {
            return ResponseEntity.ok(financeService.getAllExpenses());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @PostMapping("/expenses")
    public ResponseEntity<ExpenseDto> createExpense(@Valid @RequestBody ExpenseDto dto) {
        return ResponseEntity.ok(financeService.createExpense(dto));
    }

    @DeleteMapping("/expenses/{id}")
    public ResponseEntity<Void> deleteExpense(@PathVariable Long id) {
        financeService.deleteExpense(id);
        return ResponseEntity.noContent().build();
    }
}
