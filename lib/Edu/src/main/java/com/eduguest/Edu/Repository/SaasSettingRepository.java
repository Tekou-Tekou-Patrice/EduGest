package com.eduguest.Edu.Repository;

import com.eduguest.Edu.Entity.SaasSetting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SaasSettingRepository extends JpaRepository<SaasSetting, Long> {
}
