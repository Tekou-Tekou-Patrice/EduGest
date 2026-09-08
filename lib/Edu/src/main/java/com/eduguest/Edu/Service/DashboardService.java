package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.*;
import com.eduguest.Edu.Repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DashboardService {

    private final ExamRepository examRepository;
    private final GradeRepository gradeRepository;
    private final StudentRepository studentRepository;
    private final LessonRepository lessonRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final PaymentRepository paymentRepository;
    private final AbsenceRepository absenceRepository;
    private final SchoolContextService schoolContextService;
    private final AcademicYearService academicYearService;
    private final ExamService examService;

    public DashboardService(ExamRepository examRepository,
                            GradeRepository gradeRepository,
                            StudentRepository studentRepository,
                            LessonRepository lessonRepository,
                            ScheduleItemRepository scheduleItemRepository,
                            PaymentRepository paymentRepository,
                            AbsenceRepository absenceRepository,
                            SchoolContextService schoolContextService,
                            AcademicYearService academicYearService,
                            ExamService examService) {
        this.examRepository = examRepository;
        this.gradeRepository = gradeRepository;
        this.studentRepository = studentRepository;
        this.lessonRepository = lessonRepository;
        this.scheduleItemRepository = scheduleItemRepository;
        this.paymentRepository = paymentRepository;
        this.absenceRepository = absenceRepository;
        this.schoolContextService = schoolContextService;
        this.academicYearService = academicYearService;
        this.examService = examService;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getDashboardInsights(String period) {
        academicYearService.autoCloseIfDue();

        List<Student> students = schoolContextService.scope(studentRepository.findAll());
        List<Exam> exams = academicYearService.filterCurrentYear(
                schoolContextService.scope(examRepository.findAll()),
                Exam::getAcademicYearId
        );
        List<Absence> absences = academicYearService.filterCurrentYear(
                schoolContextService.scope(absenceRepository.findAll()),
                Absence::getAcademicYearId
        );
        List<Payment> payments = academicYearService.filterCurrentYear(
                schoolContextService.scope(paymentRepository.findAll()),
                Payment::getAcademicYearId
        );
        List<Lesson> lessons = academicYearService.filterCurrentYear(
                schoolContextService.scope(lessonRepository.findAll()),
                Lesson::getAcademicYearId
        );

        // 1. Matières non encore transmises & Retards de saisie
        List<Map<String, Object>> pendingSubjects = examService.getPendingSubjectSubmissions(period);
        int submissionDelaysCount = pendingSubjects.size();

        // 2. Notes manquantes
        int totalMissingGrades = 0;
        List<Map<String, Object>> missingGradesDetails = new ArrayList<>();
        for (Exam exam : exams) {
            String examId = String.valueOf(exam.getId());
            List<Grade> examGrades = schoolContextService.scope(gradeRepository.findByExamId(examId));
            Set<String> gradedStudentIds = examGrades.stream().map(Grade::getStudentId).collect(Collectors.toSet());

            List<Student> classStudents = students.stream()
                    .filter(s -> exam.getClassName() != null && exam.getClassName().equalsIgnoreCase(s.getClassName()))
                    .toList();

            int missingInExam = 0;
            for (Student student : classStudents) {
                if (!gradedStudentIds.contains(String.valueOf(student.getId()))) {
                    missingInExam++;
                }
            }

            if (missingInExam > 0) {
                totalMissingGrades += missingInExam;
                Map<String, Object> detail = new LinkedHashMap<>();
                detail.put("examId", examId);
                detail.put("examTitle", exam.getTitle());
                detail.put("className", exam.getClassName());
                detail.put("subject", exam.getSubject());
                detail.put("teacherName", exam.getTeacherName() != null ? exam.getTeacherName() : "Non spécifié");
                detail.put("missingCount", missingInExam);
                missingGradesDetails.add(detail);
            }
        }

        // 3. Taux d'absences réel
        int totalStudents = students.size();
        double absenceRate = 0.0;
        if (totalStudents > 0) {
            // Taux basé sur les élèves ayant au moins une absence ou le volume total
            long studentsWithAbsence = absences.stream().map(Absence::getStudentId).distinct().count();
            absenceRate = Math.min(100.0, ((double) studentsWithAbsence / totalStudents) * 100.0);
        }

        // 4. Paiements en retard / Impayés
        // Calcul des élèves n'ayant pas encore payé le montant standard ou ayant un solde
        double expectedFeePerStudent = 50000.0; // Standard indicatif scolarité
        Map<String, Double> studentPayments = new HashMap<>();
        for (Payment p : payments) {
            if (p.getStudentId() != null) {
                studentPayments.put(p.getStudentId(),
                        studentPayments.getOrDefault(p.getStudentId(), 0.0) + (p.getAmount() != null ? p.getAmount() : 0));
            }
        }

        List<Map<String, Object>> overdueList = new ArrayList<>();
        double totalOverdueAmount = 0.0;
        for (Student s : students) {
            String sId = String.valueOf(s.getId());
            double paid = studentPayments.getOrDefault(sId, 0.0);
            if (paid < expectedFeePerStudent) {
                double due = expectedFeePerStudent - paid;
                totalOverdueAmount += due;
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("studentId", sId);
                item.put("studentName", s.getFirstName() + " " + s.getLastName());
                item.put("className", s.getClassName());
                item.put("paidAmount", paid);
                item.put("dueAmount", due);
                item.put("parentPhone", s.getParentPhone());
                overdueList.add(item);
            }
        }

        // 5. Derniers envois d'enseignants (Timeline combinée notes + cahiers de texte)
        List<Map<String, Object>> recentSubmissions = new ArrayList<>();

        for (Exam e : exams) {
            if (e.getSubmittedAt() != null) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("type", "NOTES");
                item.put("title", "Notes : " + e.getSubject());
                item.put("subject", e.getSubject());
                item.put("className", e.getClassName());
                item.put("teacherName", e.getTeacherName() != null ? e.getTeacherName() : "Enseignant");
                item.put("date", e.getSubmittedAt().toString());
                item.put("details", e.getTitle() + " (Coeff " + e.getCoefficient() + ")");
                recentSubmissions.add(item);
            }
        }

        for (Lesson l : lessons) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("type", "CAHIER_TEXTE");
            item.put("title", "Leçon : " + l.getTitle());
            item.put("subject", l.getSubject());
            item.put("className", l.getClassName());
            item.put("teacherName", l.getTeacherName() != null ? l.getTeacherName() : "Enseignant");
            item.put("date", l.getDate() != null ? l.getDate().toString() : LocalDateTime.now().toString());
            item.put("details", l.getContent() != null && l.getContent().length() > 60
                    ? l.getContent().substring(0, 60) + "..." : l.getContent());
            recentSubmissions.add(item);
        }

        recentSubmissions.sort((a, b) -> {
            String da = a.get("date") != null ? a.get("date").toString() : "";
            String db = b.get("date") != null ? b.get("date").toString() : "";
            return db.compareTo(da);
        });
        if (recentSubmissions.size() > 10) {
            recentSubmissions = recentSubmissions.subList(0, 10);
        }

        Map<String, Object> insights = new LinkedHashMap<>();
        insights.put("submissionDelaysCount", submissionDelaysCount);
        insights.put("pendingSubjects", pendingSubjects);
        insights.put("missingGradesCount", totalMissingGrades);
        insights.put("missingGradesDetails", missingGradesDetails);
        insights.put("absenceRate", Math.round(absenceRate * 10.0) / 10.0);
        insights.put("totalAbsences", absences.size());
        insights.put("overduePaymentsCount", overdueList.size());
        insights.put("totalOverdueAmount", totalOverdueAmount);
        insights.put("overdueList", overdueList.stream().limit(15).toList());
        insights.put("recentTeacherSubmissions", recentSubmissions);

        return insights;
    }
}
