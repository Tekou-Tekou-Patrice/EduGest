package com.eduguest.Edu.Controllers;

import com.eduguest.Edu.DTO.ParentDto;
import com.eduguest.Edu.Service.ParentService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/scolarite/parents")
public class ParentController {

    private final ParentService parentService;

    public ParentController(ParentService parentService) {
        this.parentService = parentService;
    }

    @GetMapping
    public ResponseEntity<List<ParentDto>> getAllParents() {
        return ResponseEntity.ok(parentService.getAllParents());
    }

    @PostMapping
    public ResponseEntity<ParentDto> createParent(@Valid @RequestBody ParentDto dto) {
        return ResponseEntity.ok(parentService.createParent(dto));
    }
}
