package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ParentDto;
import com.eduguest.Edu.Entity.Parent;
import com.eduguest.Edu.Repository.ParentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ParentService {
    private final ParentRepository parentRepository;
    private final SchoolContextService schoolContextService;

    public ParentService(ParentRepository parentRepository, SchoolContextService schoolContextService) {
        this.parentRepository = parentRepository;
        this.schoolContextService = schoolContextService;
    }

    @Transactional(readOnly = true)
    public List<ParentDto> getAllParents() {
        return schoolContextService.scope(parentRepository.findAll()).stream()
                .map(this::mapToDto).collect(Collectors.toList());
    }

    @Transactional
    public ParentDto createParent(ParentDto dto) {
        Parent parent = new Parent();
        parent.setFirstName(dto.getFirstName());
        parent.setLastName(dto.getLastName());
        parent.setPhone(dto.getPhone());
        parent.setEmail(dto.getEmail());
        parent.setAddress(dto.getAddress());
        parent.setStudentIds(dto.getStudentIds());
        schoolContextService.verifyAndAssign(parent);
        return mapToDto(parentRepository.save(parent));
    }

    private ParentDto mapToDto(Parent entity) {
        ParentDto dto = new ParentDto();
        dto.setId(entity.getId());
        dto.setFirstName(entity.getFirstName());
        dto.setLastName(entity.getLastName());
        dto.setPhone(entity.getPhone());
        dto.setEmail(entity.getEmail());
        dto.setAddress(entity.getAddress());
        dto.setStudentIds(entity.getStudentIds());
        return dto;
    }
}
