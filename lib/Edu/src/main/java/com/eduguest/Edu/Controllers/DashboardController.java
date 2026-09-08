package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Service.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/insights")
    public ResponseEntity<Map<String, Object>> getInsights(
            @RequestParam(required = false) String period) {
        return ResponseEntity.ok(dashboardService.getDashboardInsights(period));
    }
}
