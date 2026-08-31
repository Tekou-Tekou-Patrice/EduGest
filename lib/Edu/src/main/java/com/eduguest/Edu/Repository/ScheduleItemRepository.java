package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.ScheduleItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ScheduleItemRepository extends JpaRepository<ScheduleItem, Long> {
    
    @Query("SELECT s FROM ScheduleItem s WHERE s.className = :className")
    List<ScheduleItem> findByClassName(@Param("className") String className);
    
    @Query("SELECT s FROM ScheduleItem s WHERE s.teacherName = :teacherName")
    List<ScheduleItem> findByTeacherName(@Param("teacherName") String teacherName);
    
    @Query("SELECT s FROM ScheduleItem s WHERE s.day = :day ORDER BY s.startTime ASC")
    List<ScheduleItem> findByDay(@Param("day") String day);

    @Query(value = "SELECT * FROM schedule_items WHERE class_name = :className AND day = :day", nativeQuery = true)
    List<ScheduleItem> findByClassAndDay(@Param("className") String className, @Param("day") String day);
}
