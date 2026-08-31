package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {
    
    @Query("SELECT e FROM Event e WHERE e.category = :category")
    List<Event> findByCategory(@Param("category") String category);

    @Query(value = "SELECT * FROM events ORDER BY date ASC, hour ASC, minute ASC", nativeQuery = true)
    List<Event> findAllSorted();
}
