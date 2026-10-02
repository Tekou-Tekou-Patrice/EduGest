package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Service.YearArchiveService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/platform-admin")
public class PlatformAdminAccessController {
    private final YearArchiveService yearArchiveService;

    public PlatformAdminAccessController(YearArchiveService yearArchiveService) {
        this.yearArchiveService = yearArchiveService;
    }

    @GetMapping("/access")
    public ResponseEntity<Void> verifyAccess() {
        yearArchiveService.verifyPlatformAdminAccess();
        return ResponseEntity.noContent().build();
    }
}
