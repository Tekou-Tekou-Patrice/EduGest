package com.eduguest.Edu.Service;

import com.eduguest.Edu.DTO.AcademicYearDto;
import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.Absence;
import com.eduguest.Edu.Entity.AppNotification;
import com.eduguest.Edu.Entity.Event;
import com.eduguest.Edu.Entity.Exam;
import com.eduguest.Edu.Entity.Expense;
import com.eduguest.Edu.Entity.Grade;
import com.eduguest.Edu.Entity.Lesson;
import com.eduguest.Edu.Entity.Payment;
import com.eduguest.Edu.Entity.Sanction;
import com.eduguest.Edu.Entity.ScheduleItem;
import com.eduguest.Edu.Entity.SchoolInfo;
import com.eduguest.Edu.Repository.AbsenceRepository;
import com.eduguest.Edu.Repository.AcademicYearRepository;
import com.eduguest.Edu.Repository.EventRepository;
import com.eduguest.Edu.Repository.ExamRepository;
import com.eduguest.Edu.Repository.ExpenseRepository;
import com.eduguest.Edu.Repository.GradeRepository;
import com.eduguest.Edu.Repository.LessonRepository;
import com.eduguest.Edu.Repository.PaymentRepository;
import com.eduguest.Edu.Repository.SanctionRepository;
import com.eduguest.Edu.Repository.ScheduleItemRepository;
import com.eduguest.Edu.Repository.SchoolInfoRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.TeacherRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class AcademicYearService {
    public static final String YEAR_CLOSED_MESSAGE =
            "Année scolaire clôturée. Saisissez la nouvelle année dans les Paramètres pour continuer.";

    private final AcademicYearRepository academicYearRepository;
    private final SchoolInfoRepository schoolInfoRepository;
    private final PaymentRepository paymentRepository;
    private final ExpenseRepository expenseRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final AbsenceRepository absenceRepository;
    private final SanctionRepository sanctionRepository;
    private final ExamRepository examRepository;
    private final LessonRepository lessonRepository;
    private final GradeRepository gradeRepository;
    private final EventRepository eventRepository;
    private final ScheduleItemRepository scheduleItemRepository;

    @PersistenceContext
    private EntityManager entityManager;
    private final SchoolContextService schoolContextService;


    public AcademicYearService(AcademicYearRepository academicYearRepository,
                               SchoolInfoRepository schoolInfoRepository,
                               PaymentRepository paymentRepository,
                               ExpenseRepository expenseRepository,
                               StudentRepository studentRepository,
                               TeacherRepository teacherRepository,
                               AbsenceRepository absenceRepository,
                               SanctionRepository sanctionRepository,
                               ExamRepository examRepository,
                               LessonRepository lessonRepository,
                               GradeRepository gradeRepository,
                               EventRepository eventRepository,
                               ScheduleItemRepository scheduleItemRepository,
                               SchoolContextService schoolContextService) {
        this.schoolContextService = schoolContextService;
        this.academicYearRepository = academicYearRepository;
        this.schoolInfoRepository = schoolInfoRepository;
        this.paymentRepository = paymentRepository;
        this.expenseRepository = expenseRepository;
        this.studentRepository = studentRepository;
        this.teacherRepository = teacherRepository;
        this.absenceRepository = absenceRepository;
        this.sanctionRepository = sanctionRepository;
        this.examRepository = examRepository;
        this.lessonRepository = lessonRepository;
        this.gradeRepository = gradeRepository;
        this.eventRepository = eventRepository;
        this.scheduleItemRepository = scheduleItemRepository;
    }

    @Transactional
    public Optional<AcademicYear> syncAndFindActive() {
        autoCloseIfDue();
        return findActive();
    }

    public Optional<AcademicYear> findActive() {
        return schoolContextService.scope(academicYearRepository.findAll()).stream()
                .filter(AcademicYear::isActive)
                .findFirst();
    }

    @Transactional
    public AcademicYear requireActiveYear() {
        return syncAndFindActive()
                .orElseThrow(() -> new RuntimeException(YEAR_CLOSED_MESSAGE));
    }

    @Transactional
    public AcademicYear getOrAutoCreateActiveYear() {
        Optional<AcademicYear> active = syncAndFindActive();
        if (active.isPresent()) {
            return active.get();
        }
        
        List<AcademicYear> allYears = schoolContextService.scope(academicYearRepository.findAll());
        LocalDate now = LocalDate.now();
        
        int currentYear = now.getYear();
        String label = (currentYear) + "-" + (currentYear + 1);
        
        try {
            AcademicYearDto result = startNewYear(label, LocalDate.of(currentYear, 9, 1), 
                                                   LocalDate.of(currentYear + 1, 6, 30));
            return findActive().orElseThrow();
        } catch (Exception e) {
            throw new RuntimeException("Failed to auto-create academic year: " + e.getMessage(), e);
        }
    }

    public Long stampCurrentYear() {
        return requireActiveYear().getId();
    }

    public Long stampCurrentYearOrAuto() {
        return getOrAutoCreateActiveYear().getId();
    }

    public boolean isWaitingForNewYear() {
        autoCloseIfDue();
        return findActive().isEmpty()
                && !schoolContextService.scope(academicYearRepository.findByActiveFalseOrderByEndDateDesc()).isEmpty();
    }

    public <T> List<T> filterCurrentYear(List<T> items, Function<T, Long> yearIdGetter) {
        Optional<AcademicYear> current = findActive();
        if (current.isEmpty()) {
            return List.of();
        }
        Long yearId = current.get().getId();
        return items.stream()
                .filter(item -> {
                    Long recordYear = yearIdGetter.apply(item);
                    return recordYear == null || recordYear.equals(yearId);
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public void autoCloseIfDue() {
        findActive().ifPresent(year -> {
            if (year.getEndDate() != null && !year.getEndDate().isAfter(LocalDate.now())) {
                closeYear(year);
            }
        });
    }

    @Transactional
    public AcademicYearDto closeCurrentYear() {
        AcademicYear year = findActive()
                .orElseThrow(() -> new RuntimeException("Aucune année scolaire active à clôturer"));
        closeYear(year);
        return toDto(year);
    }

    @Transactional
    public AcademicYearDto startNewYear(String label, LocalDate startDate, LocalDate archiveDate) {
        autoCloseIfDue();
        if (findActive().isPresent()) {
            throw new RuntimeException("Clôturez d'abord l'année en cours avant d'en ouvrir une nouvelle");
        }
        if (label == null || label.isBlank()) {
            throw new RuntimeException("Le libellé de l'année scolaire est requis (ex: 2025-2026)");
        }
        String normalized = label.trim();
        if (schoolContextService.scope(academicYearRepository.findAll()).stream()
                .anyMatch(year -> normalized.equals(year.getLabel()))) {
            throw new RuntimeException("Cette année scolaire existe déjà");
        }
        LocalDate start = startDate != null ? startDate : LocalDate.now();
        LocalDate effectiveArchiveDate = archiveDate != null ? archiveDate : start.plusMonths(10);
        if (effectiveArchiveDate.isBefore(start)) {
            throw new RuntimeException("La date de sauvegarde doit être postérieure au début d'année");
        }

        findActive().ifPresent(y -> y.setActive(false));

        AcademicYear year = new AcademicYear();
        year.setLabel(normalized);
        year.setStartDate(start);
        year.setEndDate(effectiveArchiveDate);
        year.setActive(true);
        schoolContextService.verifyAndAssign(year);
        AcademicYear saved = academicYearRepository.save(year);

        schoolContextService.scope(schoolInfoRepository.findAll()).stream().findFirst().ifPresent(info -> {
            info.setCurrentYearId(saved.getLabel());
            schoolInfoRepository.save(info);
        });
        return toDto(saved);
    }

    @Transactional
    public AcademicYear upsertActiveYear(String label, LocalDate startDate, LocalDate archiveDate) {
        Optional<AcademicYear> active = findActive();
        if (active.isEmpty()) {
            startNewYear(label, startDate, archiveDate);
            return findActive().orElse(null);
        }
        AcademicYear year = active.get();
        if (label != null && !label.isBlank() && !label.trim().equals(year.getLabel())) {
            schoolContextService.scope(academicYearRepository.findAll()).stream()
                    .filter(existing -> label.trim().equals(existing.getLabel())).findFirst().ifPresent(existing -> {
                if (!existing.getId().equals(year.getId())) {
                    throw new RuntimeException("Cette année scolaire existe déjà");
                }
            });
            year.setLabel(label.trim());
        }
        if (startDate != null) {
            year.setStartDate(startDate);
        }
        if (archiveDate != null) {
            year.setEndDate(archiveDate);
        }
        if (year.getStartDate() != null && year.getEndDate() != null
                && year.getEndDate().isBefore(year.getStartDate())) {
            throw new RuntimeException("La date de sauvegarde doit être postérieure au début d'année");
        }
        AcademicYear saved = academicYearRepository.save(year);
        schoolContextService.scope(schoolInfoRepository.findAll()).stream().findFirst().ifPresent(info -> {
            info.setCurrentYearId(saved.getLabel());
            schoolInfoRepository.save(info);
        });
        if (saved.getEndDate() != null && !saved.getEndDate().isAfter(LocalDate.now())) {
            closeYear(saved);
        }
        return saved;
    }

    public List<AcademicYearDto> listAll() {
        autoCloseIfDue();
        return schoolContextService.scope(academicYearRepository.findAllByOrderByStartDateDesc()).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public List<AcademicYearDto> listRecaps() {
        autoCloseIfDue();
        return schoolContextService.scope(academicYearRepository.findByActiveFalseOrderByEndDateDesc()).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    private void closeYear(AcademicYear year) {
        Long yearId = year.getId();
        SchoolInfo school = schoolContextService.scope(schoolInfoRepository.findAll()).stream().findFirst().orElse(null);

        year.setTotalRevenue(sumPayments(yearId));
        year.setTotalExpenses(sumExpenses(yearId));
        year.setStudentCount((int) studentRepository.count());
        year.setTeacherCount((int) teacherRepository.count());
        year.setAbsenceCount(countForYear(schoolContextService.scope(absenceRepository.findAll()), Absence::getAcademicYearId, yearId));
        year.setSanctionCount(countForYear(schoolContextService.scope(sanctionRepository.findAll()), Sanction::getAcademicYearId, yearId));
        year.setExamCount(countForYear(schoolContextService.scope(examRepository.findAll()), Exam::getAcademicYearId, yearId));
        year.setLessonCount(countForYear(schoolContextService.scope(lessonRepository.findAll()), Lesson::getAcademicYearId, yearId));
        year.setSchoolName(school != null ? school.getName() : null);
        year.setClosedAt(LocalDateTime.now());
        year.setActive(false);
        if (year.getEndDate() == null) {
            year.setEndDate(LocalDate.now());
        }
        schoolContextService.verifyAndAssign(year);
        academicYearRepository.save(year);

        assignUntagged(Payment.class, yearId);
        assignUntagged(Expense.class, yearId);
        assignUntagged(Absence.class, yearId);
        assignUntagged(Sanction.class, yearId);
        assignUntagged(Grade.class, yearId);
        assignUntagged(Lesson.class, yearId);
        assignUntagged(Event.class, yearId);
        assignUntagged(Exam.class, yearId);
        assignUntagged(ScheduleItem.class, yearId);
        assignUntagged(AppNotification.class, yearId);
        entityManager.flush();
    }

    private Double sumPayments(Long yearId) {
        return schoolContextService.scope(paymentRepository.findAll()).stream()
                .filter(p -> p.getAcademicYearId() == null || yearId.equals(p.getAcademicYearId()))
                .mapToDouble(p -> p.getAmount() != null ? p.getAmount() : 0)
                .sum();
    }

    private Double sumExpenses(Long yearId) {
        return schoolContextService.scope(expenseRepository.findAll()).stream()
                .filter(e -> e.getAcademicYearId() == null || yearId.equals(e.getAcademicYearId()))
                .mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0)
                .sum();
    }

    private <T> int countForYear(List<T> items, Function<T, Long> yearIdGetter, Long yearId) {
        return (int) items.stream()
                .filter(item -> {
                    Long recordYear = yearIdGetter.apply(item);
                    return recordYear == null || yearId.equals(recordYear);
                })
                .count();
    }

    private void assignUntagged(Class<?> entityClass, Long yearId) {
        var query = entityManager.createQuery(
                "UPDATE " + entityClass.getSimpleName()
                        + " e SET e.academicYearId = :id WHERE e.academicYearId IS NULL");
        query.setParameter("id", yearId).executeUpdate();
    }

    public AcademicYearDto toDto(AcademicYear year) {
        AcademicYearDto dto = new AcademicYearDto();
        dto.setId(year.getId());
        dto.setLabel(year.getLabel());
        dto.setStartDate(year.getStartDate());
        dto.setEndDate(year.getEndDate());
        dto.setActive(year.isActive());
        dto.setStatus(year.isActive() ? "ACTIVE" : "CLOSED");
        dto.setTotalRevenue(year.getTotalRevenue() != null ? year.getTotalRevenue() : 0);
        dto.setTotalExpenses(year.getTotalExpenses() != null ? year.getTotalExpenses() : 0);
        dto.setBalance(dto.getTotalRevenue() - dto.getTotalExpenses());
        dto.setStudentCount(year.getStudentCount() != null ? year.getStudentCount() : 0);
        dto.setTeacherCount(year.getTeacherCount() != null ? year.getTeacherCount() : 0);
        dto.setAbsenceCount(year.getAbsenceCount() != null ? year.getAbsenceCount() : 0);
        dto.setSanctionCount(year.getSanctionCount() != null ? year.getSanctionCount() : 0);
        dto.setExamCount(year.getExamCount() != null ? year.getExamCount() : 0);
        dto.setLessonCount(year.getLessonCount() != null ? year.getLessonCount() : 0);
        dto.setSchoolName(year.getSchoolName());
        dto.setClosedAt(year.getClosedAt());
        return dto;
    }
}
