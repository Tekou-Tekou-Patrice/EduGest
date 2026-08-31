package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.SchoolInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SchoolInfoRepository extends JpaRepository<SchoolInfo, String> {
}
