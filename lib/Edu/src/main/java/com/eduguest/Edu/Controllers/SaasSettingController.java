package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.Entity.SaasSetting;
import com.eduguest.Edu.Service.SaasSettingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/saas-settings")
public class SaasSettingController {
    private final SaasSettingService service;

    public SaasSettingController(SaasSettingService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<SaasSetting> get() {
        return ResponseEntity.ok(service.get());
    }

    @PutMapping
    public ResponseEntity<SaasSetting> save(@RequestBody SaasSetting settings) {
        return ResponseEntity.ok(service.save(settings));
    }
}
