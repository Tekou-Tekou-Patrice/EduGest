package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.SchoolInfoDto;
import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.School;
import com.eduguest.Edu.Entity.SchoolInfo;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.SchoolInfoRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Optional;

@Service
public class SchoolInfoService {
    private final SchoolInfoRepository schoolInfoRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final UserSecurityContextService userSecurityContextService;
    private final com.eduguest.Edu.Repository.SchoolRepository schoolRepository;
    private final SchoolService schoolService;

    public SchoolInfoService(SchoolInfoRepository schoolInfoRepository,
                             AcademicYearService academicYearService,
                             SchoolContextService schoolContextService,
                             UserSecurityContextService userSecurityContextService,
                             com.eduguest.Edu.Repository.SchoolRepository schoolRepository,
                             SchoolService schoolService) {
        this.schoolContextService = schoolContextService;
        this.schoolInfoRepository = schoolInfoRepository;
        this.academicYearService = academicYearService;
        this.userSecurityContextService = userSecurityContextService;
        this.schoolRepository = schoolRepository;
        this.schoolService = schoolService;
    }

    @Transactional
    public SchoolInfoDto getSchoolInfo() {
        academicYearService.autoCloseIfDue();
        School currentSchool = schoolContextService.currentSchool();
        if (currentSchool == null) {
            throw new IllegalStateException("Aucune école active");
        }
        SchoolInfo info = schoolInfoRepository.findById(infoId())
                .orElseGet(() -> {
                    SchoolInfo defaultInfo = new SchoolInfo();
                    defaultInfo.setId(infoId());
                    defaultInfo.setName(currentSchool.getName());
                    defaultInfo.setAddress("");
                    defaultInfo.setPhone("");
                    defaultInfo.setEmail(null);
                    defaultInfo.setCurrentYearId("");
                    schoolContextService.verifyAndAssign(defaultInfo);
                    return schoolInfoRepository.save(defaultInfo);
                });
        return mapToDto(info);
    }

    @Transactional
    public SchoolInfoDto updateSchoolInfo(SchoolInfoDto dto) {
        academicYearService.autoCloseIfDue();
        SchoolInfo entity = schoolInfoRepository.findById(infoId()).orElseGet(SchoolInfo::new);
        entity.setId(infoId());
        schoolContextService.verifyAndAssign(entity);
        if (dto.getName() != null) entity.setName(dto.getName());
        if (dto.getAddress() != null) entity.setAddress(dto.getAddress());
        if (dto.getPhone() != null) entity.setPhone(dto.getPhone());
        entity.setEmail(dto.getEmail());
        entity.setLogoUrl(dto.getLogoUrl());
        School school = schoolContextService.currentSchool();
        if (school != null && (school.getCode() == null || school.getCode().isBlank())) {
            school.setCode(schoolService.generateUniqueSchoolCode());
            schoolRepository.save(school);
        }

        String yearLabel = dto.getCurrentYearId() != null ? dto.getCurrentYearId().trim() : entity.getCurrentYearId();
        LocalDate archiveDate = dto.getArchiveDate();
        LocalDate startDate = dto.getStartDate();

        Optional<AcademicYear> active = academicYearService.findActive();
        if (yearLabel != null && !yearLabel.isBlank()) {
            if (active.isPresent()) {
                academicYearService.upsertActiveYear(yearLabel, startDate, archiveDate);
            } else {
                LocalDate effectiveArchiveDate = archiveDate != null ? archiveDate : (startDate != null ? startDate.plusMonths(10) : LocalDate.now().plusMonths(10));
                academicYearService.startNewYear(yearLabel, startDate, effectiveArchiveDate);
            }
            entity.setCurrentYearId(yearLabel);
        } else if (active.isPresent() && archiveDate != null) {
            academicYearService.upsertActiveYear(active.get().getLabel(), startDate, archiveDate);
        }

        SchoolInfo saved = schoolInfoRepository.save(entity);
        return mapToDto(saved);
    }

    private String infoId() {
        Long schoolId = schoolContextService.currentSchoolId();
        if (schoolId == null) {
            throw new IllegalStateException("Aucune école active");
        }
        return "SCHOOL_" + schoolId;
    }

    private SchoolInfoDto mapToDto(SchoolInfo entity) {
        SchoolInfoDto dto = new SchoolInfoDto();
        dto.setId(entity.getId());
        dto.setName(entity.getName());
        School currentSchool = schoolContextService.currentSchool();
        if (currentSchool != null) {
            if (currentSchool.getCode() == null || currentSchool.getCode().isBlank()) {
                currentSchool.setCode(schoolService.generateUniqueSchoolCode());
                currentSchool = schoolRepository.save(currentSchool);
            }
            UserRole currentRole = userSecurityContextService.getCurrentRole();
            if (currentRole == UserRole.FONDATEUR
                    || currentRole == UserRole.PROVISEUR
                    || currentRole == UserRole.SECRETAIRE) {
                dto.setCode(currentSchool.getCode());
            }
            dto.setSchoolLevel(normalizeSchoolLevel(currentSchool.getSchoolLevel()));
            dto.setSubscriptionStatus(currentSchool.getSubscriptionStatus());
            dto.setSubscriptionExpiresAt(currentSchool.getSubscriptionExpiresAt());
            dto.setMonthlyFee(currentSchool.getMonthlyFee());
            dto.setPlanName(currentSchool.getPlanName());
        }
        dto.setAddress(entity.getAddress());
        dto.setPhone(entity.getPhone());
        dto.setEmail(entity.getEmail());
        dto.setLogoUrl(entity.getLogoUrl());

        Optional<AcademicYear> active = academicYearService.findActive();
        boolean waiting = academicYearService.isWaitingForNewYear();
        if (active.isPresent()) {
            AcademicYear year = active.get();
            dto.setCurrentYearId(year.getLabel());
            dto.setCurrentYearNumericId(year.getId());
            dto.setStartDate(year.getStartDate());
            dto.setArchiveDate(year.getEndDate());
            dto.setYearStatus("ACTIVE");
            dto.setWaitingForNewYear(false);
        } else {
            dto.setCurrentYearId(entity.getCurrentYearId());
            dto.setYearStatus(waiting ? "WAITING" : "NONE");
            dto.setWaitingForNewYear(waiting);
        }
        return dto;
    }

    private String normalizeSchoolLevel(String value) {
        if ("PRIMARY".equalsIgnoreCase(value)) return "PRIMARY";
        if ("COLLEGE".equalsIgnoreCase(value)) return "COLLEGE";
        if ("LYCEE".equalsIgnoreCase(value)) return "LYCEE";
        return "COLLEGE";
    }
}
