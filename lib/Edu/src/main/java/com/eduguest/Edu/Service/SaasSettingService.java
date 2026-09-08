package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.SaasSetting;
import com.eduguest.Edu.Repository.SaasSettingRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SaasSettingService {
    private final SaasSettingRepository repository;

    public SaasSettingService(SaasSettingRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public SaasSetting get() {
        SaasSetting settings = repository.findById(1L).orElseGet(SaasSetting::new);
        applyDefaults(settings);
        return repository.save(settings);
    }

    @Transactional
    public SaasSetting save(SaasSetting settings) {
        SaasSetting current = repository.findById(1L).orElseGet(SaasSetting::new);
        current.setId(1L);
        if (settings.getMtnNumber() != null) current.setMtnNumber(settings.getMtnNumber());
        if (settings.getMtnName() != null) current.setMtnName(settings.getMtnName());
        if (settings.getOrangeNumber() != null) current.setOrangeNumber(settings.getOrangeNumber());
        if (settings.getOrangeName() != null) current.setOrangeName(settings.getOrangeName());
        if (settings.getPaymentInstructions() != null) {
            current.setPaymentInstructions(settings.getPaymentInstructions());
        }
        applyDefaults(current);
        return repository.save(current);
    }

    private void applyDefaults(SaasSetting settings) {
        SaasSetting defaults = new SaasSetting();
        if (settings.getMtnNumber() == null || settings.getMtnNumber().isBlank()) {
            settings.setMtnNumber(defaults.getMtnNumber());
        }
        if (settings.getMtnName() == null || settings.getMtnName().isBlank()) {
            settings.setMtnName(defaults.getMtnName());
        }
        if (settings.getOrangeNumber() == null || settings.getOrangeNumber().isBlank()) {
            settings.setOrangeNumber(defaults.getOrangeNumber());
        }
        if (settings.getOrangeName() == null || settings.getOrangeName().isBlank()) {
            settings.setOrangeName(defaults.getOrangeName());
        }
        if (settings.getPaymentInstructions() == null || settings.getPaymentInstructions().isBlank()) {
            settings.setPaymentInstructions(defaults.getPaymentInstructions());
        }
    }
}
