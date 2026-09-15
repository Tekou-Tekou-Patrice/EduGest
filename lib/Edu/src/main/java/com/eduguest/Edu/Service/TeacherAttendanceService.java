package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.TeacherAttendanceDto;
import com.eduguest.Edu.Entity.Teacher;
import com.eduguest.Edu.Entity.TeacherAttendance;
import com.eduguest.Edu.Entity.User;
import com.eduguest.Edu.Entity.UserRole;
import com.eduguest.Edu.Repository.TeacherAttendanceRepository;
import com.eduguest.Edu.Repository.TeacherRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class TeacherAttendanceService {
    private static final List<String> STATUSES = List.of("PRESENT", "ABSENT", "LATE", "PERMISSION");

    private final TeacherAttendanceRepository attendanceRepository;
    private final TeacherRepository teacherRepository;
    private final UserRepository userRepository;
    private final SchoolContextService schoolContextService;

    public TeacherAttendanceService(TeacherAttendanceRepository attendanceRepository,
                                    TeacherRepository teacherRepository,
                                    UserRepository userRepository,
                                    SchoolContextService schoolContextService) {
        this.attendanceRepository = attendanceRepository;
        this.teacherRepository = teacherRepository;
        this.userRepository = userRepository;
        this.schoolContextService = schoolContextService;
    }

    @Transactional(readOnly = true)
    public List<TeacherAttendanceDto> getForDate(LocalDate date) {
        var records = schoolContextService.scope(attendanceRepository.findAll()).stream()
                .filter(item -> date.equals(item.getAttendanceDate()))
                .toList();
        return schoolContextService.scope(teacherRepository.findAll()).stream()
                .map(teacher -> records.stream()
                        .filter(item -> item.getTeacher().getId().equals(teacher.getId()))
                        .findFirst()
                        .map(this::toDto)
                        .orElseGet(() -> emptyDto(teacher, date)))
                .toList();
    }

    @Transactional
    public TeacherAttendanceDto save(Long teacherId, LocalDate date, String status, Long recorderId) {
        if (!STATUSES.contains(status)) {
            throw new IllegalArgumentException("Statut invalide. Choisissez Présent, Absent, Retard ou Permission.");
        }
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new IllegalArgumentException("Enseignant introuvable"));
        schoolContextService.verifyAndAssign(teacher);
        User recorder = userRepository.findById(recorderId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable"));
        if (recorder.getRole() != UserRole.FONDATEUR
                && recorder.getRole() != UserRole.PROVISEUR
                && recorder.getRole() != UserRole.SECRETAIRE) {
            throw new IllegalArgumentException(
                    "Seul le directeur ou le secrétariat peut pointer les enseignants.");
        }

        TeacherAttendance attendance = attendanceRepository
                .findByTeacherIdAndAttendanceDate(teacherId, date)
                .orElseGet(TeacherAttendance::new);
        attendance.setTeacher(teacher);
        attendance.setAttendanceDate(date);
        attendance.setStatus(status);
        attendance.setRecordedBy(recorder);
        attendance.setRecordedAt(LocalDateTime.now());
        schoolContextService.verifyAndAssign(attendance);
        return toDto(attendanceRepository.save(attendance));
    }

    private TeacherAttendanceDto toDto(TeacherAttendance entity) {
        TeacherAttendanceDto dto = new TeacherAttendanceDto();
        dto.setId(entity.getId());
        dto.setTeacherId(entity.getTeacher().getId());
        dto.setTeacherName(entity.getTeacher().getFirstName() + " " + entity.getTeacher().getLastName());
        dto.setAttendanceDate(entity.getAttendanceDate());
        dto.setStatus(entity.getStatus());
        dto.setRecordedById(entity.getRecordedBy().getId());
        dto.setRecordedByName(entity.getRecordedBy().getFullName());
        dto.setRecordedAt(entity.getRecordedAt());
        return dto;
    }

    private TeacherAttendanceDto emptyDto(Teacher teacher, LocalDate date) {
        TeacherAttendanceDto dto = new TeacherAttendanceDto();
        dto.setTeacherId(teacher.getId());
        dto.setTeacherName(teacher.getFirstName() + " " + teacher.getLastName());
        dto.setAttendanceDate(date);
        dto.setStatus("UNMARKED");
        return dto;
    }
}
