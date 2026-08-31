package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.AbsenceDto;
import com.eduguest.Edu.DTO.SanctionDto;
import com.eduguest.Edu.Entity.Absence;
import com.eduguest.Edu.Entity.Sanction;
import com.eduguest.Edu.Repository.AbsenceRepository;
import com.eduguest.Edu.Repository.SanctionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class DisciplineService {
    private final AbsenceRepository absenceRepository;
    private final SanctionRepository sanctionRepository;
    private final AcademicYearService academicYearService;
    private final SchoolContextService schoolContextService;
    private final AppNotificationService notificationService;


    public DisciplineService(AbsenceRepository absenceRepository,
                             SanctionRepository sanctionRepository,
                             AcademicYearService academicYearService,
                             SchoolContextService schoolContextService,
                             AppNotificationService notificationService) {
        this.schoolContextService = schoolContextService;
        this.absenceRepository = absenceRepository;
        this.sanctionRepository = sanctionRepository;
        this.academicYearService = academicYearService;
        this.notificationService = notificationService;
    }

    @Transactional
    public List<AbsenceDto> getAllAbsences() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(absenceRepository.findAll()), Absence::getAcademicYearId)
                .stream().map(this::mapToAbsenceDto).collect(Collectors.toList());
    }

    @Transactional
    public AbsenceDto createAbsence(AbsenceDto dto) {
        Absence absence = new Absence();
        absence.setStudentId(dto.getStudentId() != null ? dto.getStudentId() : "AUTO");
        absence.setStudentName(dto.getStudentName());
        absence.setClassName(dto.getClassName() != null ? dto.getClassName() : "N/A");
        absence.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        absence.setPeriod(dto.getPeriod() != null ? dto.getPeriod() : "Journée");
        absence.setReason(dto.getReason());
        absence.setJustified(dto.isJustified());
        try {
            absence.setAcademicYearId(academicYearService.stampCurrentYear());
        } catch (RuntimeException e) {
            absence.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
        }
        schoolContextService.verifyAndAssign(absence);
        Absence saved = absenceRepository.save(absence);
        notificationService.notifyAbsence(saved);
        return mapToAbsenceDto(saved);
    }

    @Transactional
    public List<AbsenceDto> getAbsences(String className) {
        academicYearService.autoCloseIfDue();
        List<Absence> source;
        if (className != null && !className.isEmpty() && !className.equals("Toutes")) {
            source = schoolContextService.scope(absenceRepository.findByClassName(className));
        } else {
            source = schoolContextService.scope(absenceRepository.findAll());
        }
        return academicYearService.filterCurrentYear(source, Absence::getAcademicYearId)
                .stream().map(this::mapToAbsenceDto).collect(Collectors.toList());
    }

    @Transactional
    public List<SanctionDto> getAllSanctions() {
        academicYearService.autoCloseIfDue();
        return academicYearService.filterCurrentYear(schoolContextService.scope(sanctionRepository.findAll()), Sanction::getAcademicYearId)
                .stream().map(this::mapToSanctionDto).collect(Collectors.toList());
    }

    @Transactional
    public SanctionDto createSanction(SanctionDto dto) {
        Sanction sanction = new Sanction();
        if (dto.getId() != null) {
            sanction = sanctionRepository.findById(dto.getId()).orElse(new Sanction());
        }
        sanction.setStudentId(dto.getStudentId() != null ? dto.getStudentId() : "AUTO");
        sanction.setStudentName(dto.getStudentName());
        sanction.setType(dto.getType());
        sanction.setReason(dto.getReason());
        sanction.setDate(dto.getDate() != null ? dto.getDate() : LocalDateTime.now());
        if (sanction.getAcademicYearId() == null) {
            try {
                sanction.setAcademicYearId(academicYearService.stampCurrentYear());
            } catch (RuntimeException e) {
                sanction.setAcademicYearId(academicYearService.getOrAutoCreateActiveYear().getId());
            }
        }
        schoolContextService.verifyAndAssign(sanction);
        Sanction saved = sanctionRepository.save(sanction);
        notificationService.notifySanction(saved);
        return mapToSanctionDto(saved);
    }

    @Transactional
    public void deleteSanction(Long id) {
        if (!sanctionRepository.existsById(id)) {
            throw new RuntimeException("Sanction non trouvée");
        }
        sanctionRepository.findById(id).ifPresent(sanction -> {
            schoolContextService.verifyAndAssign(sanction);
            sanctionRepository.delete(sanction);
        });
    }

    private AbsenceDto mapToAbsenceDto(Absence entity) {
        AbsenceDto dto = new AbsenceDto();
        dto.setId(entity.getId());
        dto.setStudentId(entity.getStudentId());
        dto.setStudentName(entity.getStudentName());
        dto.setClassName(entity.getClassName());
        dto.setDate(entity.getDate());
        dto.setPeriod(entity.getPeriod());
        dto.setReason(entity.getReason());
        dto.setJustified(entity.isJustified());
        return dto;
    }

    private SanctionDto mapToSanctionDto(Sanction entity) {
        SanctionDto dto = new SanctionDto();
        dto.setId(entity.getId());
        dto.setStudentId(entity.getStudentId());
        dto.setStudentName(entity.getStudentName());
        dto.setType(entity.getType());
        dto.setReason(entity.getReason());
        dto.setDate(entity.getDate());
        return dto;
    }
}
