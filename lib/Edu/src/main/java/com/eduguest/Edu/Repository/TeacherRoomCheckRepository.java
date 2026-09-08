package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.TeacherRoomCheck;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface TeacherRoomCheckRepository extends JpaRepository<TeacherRoomCheck, Long> {
    List<TeacherRoomCheck> findByCheckDateOrderByCheckedAtDesc(LocalDate checkDate);
    Optional<TeacherRoomCheck> findByScheduleItemIdAndCheckDate(Long scheduleItemId, LocalDate checkDate);
    List<TeacherRoomCheck> findByTeacherIdAndPresentFalseOrderByCheckedAtDesc(String teacherId);
}
