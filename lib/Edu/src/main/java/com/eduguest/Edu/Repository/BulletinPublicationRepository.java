package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.BulletinPublication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BulletinPublicationRepository extends JpaRepository<BulletinPublication, Long> {

    Optional<BulletinPublication> findFirstByClassNameAndPeriodAndStudentIdIsNull(String className, String period);

    Optional<BulletinPublication> findFirstByClassNameAndPeriodAndStudentId(String className, String period, String studentId);

    List<BulletinPublication> findByClassNameAndPeriod(String className, String period);

    List<BulletinPublication> findByPeriod(String period);
}
