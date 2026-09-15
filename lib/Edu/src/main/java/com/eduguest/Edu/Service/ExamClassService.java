package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.ExamClassConfigDto;
import com.eduguest.Edu.DTO.ExamDocumentRequirementDto;
import com.eduguest.Edu.DTO.StudentExamDocumentDto;
import com.eduguest.Edu.DTO.StudentExamStatusDto;
import com.eduguest.Edu.Entity.Classroom;
import com.eduguest.Edu.Entity.ExamClassConfig;
import com.eduguest.Edu.Entity.ExamDocumentRequirement;
import com.eduguest.Edu.Entity.Student;
import com.eduguest.Edu.Entity.StudentExamDocument;
import com.eduguest.Edu.Entity.StudentExamRecord;
import com.eduguest.Edu.Repository.ClassroomRepository;
import com.eduguest.Edu.Repository.ExamClassConfigRepository;
import com.eduguest.Edu.Repository.ExamDocumentRequirementRepository;
import com.eduguest.Edu.Repository.StudentExamDocumentRepository;
import com.eduguest.Edu.Repository.StudentExamRecordRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ExamClassService {

    private final ClassroomRepository classroomRepository;
    private final StudentRepository studentRepository;
    private final ExamClassConfigRepository configRepository;
    private final ExamDocumentRequirementRepository requirementRepository;
    private final StudentExamRecordRepository recordRepository;
    private final StudentExamDocumentRepository documentRepository;
    private final SchoolContextService schoolContextService;
    private final UserRepository userRepository;
    private final AppNotificationService notificationService;

    public ExamClassService(ClassroomRepository classroomRepository,
                            StudentRepository studentRepository,
                            ExamClassConfigRepository configRepository,
                            ExamDocumentRequirementRepository requirementRepository,
                            StudentExamRecordRepository recordRepository,
                            StudentExamDocumentRepository documentRepository,
                            SchoolContextService schoolContextService,
                            UserRepository userRepository,
                            AppNotificationService notificationService) {
        this.classroomRepository = classroomRepository;
        this.studentRepository = studentRepository;
        this.configRepository = configRepository;
        this.requirementRepository = requirementRepository;
        this.recordRepository = recordRepository;
        this.documentRepository = documentRepository;
        this.schoolContextService = schoolContextService;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public ExamClassConfigDto getConfig(Long classroomId) {
        ExamClassConfig config = scopedConfig(classroomId);
        return toConfigDto(config);
    }

    @Transactional
    public ExamClassConfigDto saveConfig(Long classroomId, ExamClassConfigDto dto) {
        Classroom classroom = scopedClassroom(classroomId);
        if (!classroom.isExamClass()) {
            throw new IllegalArgumentException("Cette classe n'est pas marquée comme classe d'examen");
        }
        if (dto.getExamName() == null || dto.getExamName().isBlank()) {
            throw new IllegalArgumentException("Le nom de l'examen est obligatoire");
        }

        ExamClassConfig config = configRepository.findByClassroomId(classroomId).orElseGet(ExamClassConfig::new);
        config.setClassroom(classroom);
        config.setExamName(dto.getExamName().trim());
        config.setOfficialFee(dto.getOfficialFee() == null ? BigDecimal.ZERO : dto.getOfficialFee().max(BigDecimal.ZERO));
        schoolContextService.verifyAndAssign(config);
        config = configRepository.save(config);

        List<ExamDocumentRequirement> existing = requirementRepository.findByConfigIdOrderByIdAsc(config.getId());
        Map<Long, ExamDocumentRequirement> byId = existing.stream()
                .collect(Collectors.toMap(ExamDocumentRequirement::getId, Function.identity()));
        Set<Long> keptIds = new HashSet<>();
        if (dto.getDocuments() != null) {
            for (ExamDocumentRequirementDto item : dto.getDocuments()) {
                if (item.getName() == null || item.getName().isBlank()) continue;
                ExamDocumentRequirement requirement = item.getId() == null
                        ? new ExamDocumentRequirement()
                        : byId.get(item.getId());
                if (requirement == null) continue;
                requirement.setConfig(config);
                requirement.setName(item.getName().trim());
                requirement.setRequired(!Boolean.FALSE.equals(item.getRequired()));
                keptIds.add(requirement.getId());
                requirementRepository.save(requirement);
            }
        }
        final ExamClassConfig savedConfig = config;
        existing.stream()
                .filter(item -> item.getId() != null && !keptIds.contains(item.getId()))
                .forEach(item -> {
                    recordRepository.findByConfigId(savedConfig.getId()).forEach(record ->
                            documentRepository.findByRecordId(record.getId()).stream()
                                    .filter(document -> document.getRequirement().getId().equals(item.getId()))
                                    .forEach(documentRepository::delete));
                    requirementRepository.delete(item);
                });
        syncStudents(savedConfig);
        return toConfigDto(savedConfig);
    }

    @Transactional
    public List<StudentExamStatusDto> getStudentStatuses(Long classroomId) {
        ExamClassConfig config = scopedConfig(classroomId);
        return scopedStudents(classroomId).stream()
                .map(student -> toStatus(config, ensureRecord(config, student)))
                .toList();
    }

    @Transactional
    public StudentExamStatusDto updateStudentStatus(Long classroomId, Long studentId, StudentExamStatusDto dto) {
        ExamClassConfig config = scopedConfig(classroomId);
        Student student = scopedStudents(classroomId).stream()
                .filter(item -> item.getId().equals(studentId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Élève introuvable dans cette classe"));
        StudentExamRecord record = ensureRecord(config, student);
        record.setPaidAmount(dto.getPaidAmount() == null ? BigDecimal.ZERO : dto.getPaidAmount().max(BigDecimal.ZERO));
        record = recordRepository.save(record);
        final StudentExamRecord savedRecord = record;

        Map<Long, Boolean> submittedByRequirement = dto.getDocuments() == null
                ? Map.of()
                : dto.getDocuments().stream().collect(Collectors.toMap(
                        StudentExamDocumentDto::getRequirementId,
                        StudentExamDocumentDto::isSubmitted,
                        (first, ignored) -> first));
        for (ExamDocumentRequirement requirement : requirementRepository.findByConfigIdOrderByIdAsc(config.getId())) {
            StudentExamDocument document = documentRepository.findByRecordIdAndRequirementId(record.getId(), requirement.getId())
                    .orElseGet(() -> {
                        StudentExamDocument created = new StudentExamDocument();
                        created.setRecord(savedRecord);
                        created.setRequirement(requirement);
                        return created;
                    });
            document.setSubmitted(Boolean.TRUE.equals(submittedByRequirement.get(requirement.getId())));
            documentRepository.save(document);
        }
        StudentExamStatusDto status = toStatus(config, savedRecord);
        notificationService.notifyExamStatus(
                String.valueOf(student.getId()),
                status.getStudentName(),
                status.isDossierComplete(),
                status.isFeesComplete());
        return status;
    }

    @Transactional
    public StudentExamStatusDto getParentStudentStatus(Long studentId, Long parentUserId) {
        var parent = userRepository.findById(parentUserId)
                .orElseThrow(() -> new IllegalArgumentException("Compte parent introuvable"));
        Student student = schoolContextService.scope(studentRepository.findAll()).stream()
                .filter(item -> item.getId().equals(studentId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Élève introuvable"));
        boolean matchesPhone = parent.getPhone() != null && parent.getPhone().equals(student.getParentPhone());
        boolean matchesEmail = parent.getEmail() != null && !parent.getEmail().endsWith("@edugest.local")
                && parent.getEmail().equalsIgnoreCase(student.getParentEmail());
        if (!matchesPhone && !matchesEmail) {
            throw new IllegalArgumentException("Cet élève n'est pas associé à ce compte parent");
        }
        Classroom classroom = student.getClassroom();
        if (classroom == null) {
            throw new IllegalArgumentException("Aucune classe associée à cet élève");
        }
        ExamClassConfig config = configRepository.findByClassroomId(classroom.getId())
                .filter(item -> item.getSchool() != null
                        && item.getSchool().getId().equals(schoolContextService.currentSchoolId()))
                .orElseThrow(() -> new IllegalArgumentException("Aucun examen configuré pour cette classe"));
        return toStatus(config, ensureRecord(config, student));
    }

    private ExamClassConfig scopedConfig(Long classroomId) {
        Classroom classroom = scopedClassroom(classroomId);
        return configRepository.findByClassroomId(classroom.getId())
                .filter(config -> config.getSchool() != null
                        && config.getSchool().getId().equals(schoolContextService.currentSchoolId()))
                .orElseThrow(() -> new IllegalArgumentException("Aucune configuration d'examen pour cette classe"));
    }

    private Classroom scopedClassroom(Long classroomId) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new IllegalArgumentException("Classe introuvable"));
        schoolContextService.verifyAndAssign(classroom);
        return classroom;
    }

    private List<Student> scopedStudents(Long classroomId) {
        Classroom classroom = scopedClassroom(classroomId);
        Map<Long, Student> students = schoolContextService.scope(studentRepository.findByClassName(classroom.getName()))
                .stream().collect(Collectors.toMap(Student::getId, Function.identity(), (first, ignored) -> first));
        schoolContextService.scope(studentRepository.findByClassroomName(classroom.getName()))
                .forEach(student -> students.put(student.getId(), student));
        return students.values().stream()
                .filter(student -> student.getClassroom() == null
                        || student.getClassroom().getId().equals(classroom.getId())
                        || classroom.getName().equals(student.getClassName()))
                .toList();
    }

    private StudentExamRecord ensureRecord(ExamClassConfig config, Student student) {
        return recordRepository.findByConfigIdAndStudentId(config.getId(), student.getId())
                .orElseGet(() -> recordRepository.save(new StudentExamRecord(null, config, student, BigDecimal.ZERO)));
    }

    private void syncStudents(ExamClassConfig config) {
        scopedStudents(config.getClassroom().getId()).forEach(student -> ensureRecord(config, student));
    }

    private ExamClassConfigDto toConfigDto(ExamClassConfig config) {
        ExamClassConfigDto dto = new ExamClassConfigDto();
        dto.setClassroomId(config.getClassroom().getId());
        dto.setClassroomName(config.getClassroom().getName());
        dto.setExamName(config.getExamName());
        dto.setOfficialFee(config.getOfficialFee());
        dto.setDocuments(requirementRepository.findByConfigIdOrderByIdAsc(config.getId()).stream().map(item -> {
            ExamDocumentRequirementDto document = new ExamDocumentRequirementDto();
            document.setId(item.getId());
            document.setName(item.getName());
            document.setRequired(item.isRequired());
            return document;
        }).toList());
        return dto;
    }

    private StudentExamStatusDto toStatus(ExamClassConfig config, StudentExamRecord record) {
        StudentExamStatusDto dto = new StudentExamStatusDto();
        dto.setStudentId(record.getStudent().getId());
        dto.setStudentName((record.getStudent().getFirstName() + " " + record.getStudent().getLastName()).trim());
        dto.setOfficialFee(config.getOfficialFee());
        dto.setPaidAmount(record.getPaidAmount());
        dto.setFeesComplete(record.getPaidAmount().compareTo(config.getOfficialFee()) >= 0);
        List<StudentExamDocument> documents = documentRepository.findByRecordId(record.getId());
        Map<Long, StudentExamDocument> byRequirement = documents.stream()
                .collect(Collectors.toMap(item -> item.getRequirement().getId(), Function.identity()));
        List<StudentExamDocumentDto> documentDtos = requirementRepository.findByConfigIdOrderByIdAsc(config.getId()).stream().map(requirement -> {
            StudentExamDocumentDto document = new StudentExamDocumentDto();
            document.setRequirementId(requirement.getId());
            document.setName(requirement.getName());
            document.setRequired(requirement.isRequired());
            document.setSubmitted(byRequirement.get(requirement.getId()) != null && byRequirement.get(requirement.getId()).isSubmitted());
            return document;
        }).toList();
        dto.setDocuments(documentDtos);
        dto.setDossierComplete(documentDtos.stream().filter(StudentExamDocumentDto::isRequired).allMatch(StudentExamDocumentDto::isSubmitted));
        return dto;
    }
}
