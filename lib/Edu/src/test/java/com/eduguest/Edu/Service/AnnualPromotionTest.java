package com.eduguest.Edu.Service;

import com.eduguest.Edu.Entity.Classroom;
import com.eduguest.Edu.Entity.AcademicYear;
import com.eduguest.Edu.Entity.BulletinPublication;
import com.eduguest.Edu.Entity.Exam;
import com.eduguest.Edu.Entity.Grade;
import com.eduguest.Edu.Entity.Student;
import com.eduguest.Edu.Entity.Subject;
import com.eduguest.Edu.Repository.BulletinPublicationRepository;
import com.eduguest.Edu.Repository.ClassroomRepository;
import com.eduguest.Edu.Repository.ExamRepository;
import com.eduguest.Edu.Repository.GradeRepository;
import com.eduguest.Edu.Repository.StudentRepository;
import com.eduguest.Edu.Repository.SubjectRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AnnualPromotionTest {

    @Mock private BulletinPublicationRepository publicationRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private ExamRepository examRepository;
    @Mock private GradeRepository gradeRepository;
    @Mock private AppNotificationService notificationService;
    @Mock private AcademicYearService academicYearService;
    @Mock private SchoolContextService schoolContextService;
    @Mock private AuditLogService auditLogService;
    @Mock private SubjectRepository subjectRepository;
    @Mock private ClassroomRepository classroomRepository;

    private BulletinPublicationService service;
    private Classroom currentClass;
    private Classroom nextClass;
    private Student student;
    private Exam exam;
    private Grade grade;

    @BeforeEach
    void setUp() {
        service = new BulletinPublicationService(
                publicationRepository,
                studentRepository,
                examRepository,
                gradeRepository,
                notificationService,
                academicYearService,
                schoolContextService,
                auditLogService,
                subjectRepository,
                classroomRepository);

        currentClass = new Classroom();
        currentClass.setId(1L);
        currentClass.setName("CM2");
        currentClass.setPromotionThreshold(12.0);
        currentClass.setPromotionTargetClassId(2L);

        nextClass = new Classroom();
        nextClass.setId(2L);
        nextClass.setName("6ème");

        student = new Student();
        student.setId(10L);
        student.setClassName("CM2");
        student.setClassroom(currentClass);

        exam = new Exam();
        exam.setId(30L);
        exam.setClassName("CM2");
        exam.setSubject("Mathématiques");
        exam.setCoefficient(1.0);

        grade = new Grade();
        grade.setStudentId("10");
        grade.setExamId("30");
        grade.setScore(12.0);

        when(schoolContextService.scope(anyCollection())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    private void stubPromotionData() {
        Subject subject = new Subject();
        subject.setName("Mathématiques");
        subject.setCoefficient(1.0);
        when(classroomRepository.findAll()).thenReturn(List.of(currentClass, nextClass));
        when(examRepository.findByClassName("CM2")).thenReturn(List.of(exam));
        when(academicYearService.filterCurrentYear(anyList(), any()))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(subjectRepository.findAll()).thenReturn(List.of(subject));
        when(studentRepository.findByClassName("CM2")).thenReturn(List.of(student));
        when(studentRepository.findByClassroomName("CM2")).thenReturn(List.of());
        when(gradeRepository.findByExamId("30")).thenReturn(List.of(grade));
    }

    @Test
    void promotesStudentWhenAverageMeetsClassThreshold() {
        stubPromotionData();
        service.deliberateAndPromote("CM2", 2026L);

        assertThat(student.getClassName()).isEqualTo("6ème");
        assertThat(student.getClassroom()).isSameAs(nextClass);
        assertThat(student.getLastAnnualDeliberationYearId()).isEqualTo(2026L);
        assertThat(student.getAnnualPromotionFromClassId()).isEqualTo(1L);
        assertThat(student.getAnnualPromotionToClassId()).isEqualTo(2L);
    }

    @Test
    void recordsTheAnnualDecisionAndLeavesBelowThresholdStudentInClass() {
        stubPromotionData();
        grade.setScore(11.99);

        service.deliberateAndPromote("CM2", 2026L);

        assertThat(student.getClassName()).isEqualTo("CM2");
        assertThat(student.getClassroom()).isSameAs(currentClass);
        assertThat(student.getLastAnnualDeliberationYearId()).isEqualTo(2026L);
        assertThat(student.getLastAnnualDeliberationClassId()).isEqualTo(1L);
    }

    @Test
    void unpublishingAnnualResultsReversesPromotionsForTheActiveYear() {
        student.setClassName(nextClass.getName());
        student.setClassroom(nextClass);
        student.setLastAnnualDeliberationYearId(2026L);
        student.setLastAnnualDeliberationClassId(currentClass.getId());
        student.setAnnualPromotionFromClassId(currentClass.getId());
        student.setAnnualPromotionToClassId(nextClass.getId());

        BulletinPublication publication = new BulletinPublication();
        publication.setClassName(currentClass.getName());
        publication.setPeriod("Bilan Annuel");
        publication.setPublished(true);
        publication.setAcademicYearId(2026L);
        publication.setPromotionSourceClassId(currentClass.getId());

        AcademicYear activeYear = new AcademicYear();
        activeYear.setId(2026L);
        activeYear.setActive(true);
        when(publicationRepository.findAll()).thenReturn(List.of(publication));
        when(publicationRepository.save(any(BulletinPublication.class))).thenReturn(publication);
        when(academicYearService.findActive()).thenReturn(Optional.of(activeYear));
        when(academicYearService.filterCurrentYear(anyList(), any()))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(classroomRepository.findAll()).thenReturn(List.of(currentClass, nextClass));
        when(studentRepository.findAll()).thenReturn(List.of(student));

        service.unpublish("CM2", "Bilan Annuel", null);

        assertThat(student.getClassName()).isEqualTo("CM2");
        assertThat(student.getClassroom()).isSameAs(currentClass);
        assertThat(student.getLastAnnualDeliberationYearId()).isNull();
        assertThat(student.getLastAnnualDeliberationClassId()).isNull();
    }

    @Test
    void promotedStudentCanStillSeeTheAnnualBulletinForThePreviousClass() {
        student.setClassName(nextClass.getName());
        student.setClassroom(nextClass);
        student.setLastAnnualDeliberationYearId(2026L);
        student.setLastAnnualDeliberationClassId(currentClass.getId());

        BulletinPublication publication = new BulletinPublication();
        publication.setClassName(currentClass.getName());
        publication.setPeriod("Bilan Annuel");
        publication.setPublished(true);
        publication.setAcademicYearId(2026L);
        publication.setPromotionSourceClassId(currentClass.getId());

        AcademicYear activeYear = new AcademicYear();
        activeYear.setId(2026L);
        activeYear.setActive(true);
        when(publicationRepository.findAll()).thenReturn(List.of(publication));
        when(studentRepository.findAll()).thenReturn(List.of(student));
        when(academicYearService.findActive()).thenReturn(Optional.of(activeYear));

        var publications = service.getPublications(null, null, "10");

        assertThat(publications).hasSize(1);
        assertThat(publications.get(0).getClassName()).isEqualTo("CM2");
    }
}
