package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.TeacherRoomCheck;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface TeacherRoomCheckRepository extends JpaRepository<TeacherRoomCheck, Long> {
    List<TeacherRoomCheck> findByCheckDateOrderByCheckedAtDesc(LocalDate checkDate);
    Optional<TeacherRoomCheck> findByScheduleItemIdAndCheckDate(Long scheduleItemId, LocalDate checkDate);
    @Query("SELECT c FROM TeacherRoomCheck c WHERE c.scheduleItemId = :scheduleItemId "
            + "AND c.checkDate = :checkDate AND c.school.id = :schoolId")
    Optional<TeacherRoomCheck> findByScheduleItemDateAndSchool(
            @Param("scheduleItemId") Long scheduleItemId,
            @Param("checkDate") LocalDate checkDate,
            @Param("schoolId") Long schoolId);
    List<TeacherRoomCheck> findByTeacherIdAndPresentFalseOrderByCheckedAtDesc(String teacherId);
}
