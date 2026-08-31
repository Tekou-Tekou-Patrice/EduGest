package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.SubjectDto;
import com.eduguest.Edu.Entity.Subject;
import com.eduguest.Edu.Repository.SubjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SubjectService {
    private final SubjectRepository subjectRepository;
    private final SchoolContextService schoolContextService;


    public SubjectService(SubjectRepository subjectRepository,
                               SchoolContextService schoolContextService) {
        this.schoolContextService = schoolContextService;
        this.subjectRepository = subjectRepository;
    }

    @Transactional(readOnly = true)
    public List<SubjectDto> getAllSubjects() {
        return schoolContextService.scope(subjectRepository.findAll()).stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public SubjectDto createSubject(SubjectDto dto) {
        Subject entity;
        if (dto.getId() != null) {
            entity = subjectRepository.findById(dto.getId()).orElse(new Subject());
        } else {
            // Chercher par nom pour éviter les doublons si l'ID est nul
            entity = subjectRepository.findByName(dto.getName()).orElse(new Subject());
        }
        
        entity.setName(dto.getName());
        entity.setCoefficient(dto.getCoefficient() != null ? dto.getCoefficient() : 1.0);
        
        schoolContextService.verifyAndAssign(entity);
        
        return mapToDto(subjectRepository.save(entity));
    }

    @Transactional
    public void deleteSubject(Long id) {
        subjectRepository.findById(id).ifPresent(subject -> {
            schoolContextService.verifyAndAssign(subject);
            subjectRepository.delete(subject);
        });
    }

    private SubjectDto mapToDto(Subject entity) {
        SubjectDto dto = new SubjectDto();
        dto.setId(entity.getId());
        dto.setName(entity.getName());
        dto.setCoefficient(entity.getCoefficient());
        return dto;
    }
}
