package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.StudentExtracurricularHours;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface StudentExtracurricularHoursRepository extends JpaRepository<StudentExtracurricularHours, UUID> {
    @Query(value = """
    SELECT * FROM vw_horas_extracurriculares_aluno 
    ORDER BY total_horas_acumuladas DESC 
    """, nativeQuery = true)
    List<Object[]> findTopStudentsByHours();
    @Query(value = """
    SELECT 
        (SELECT COUNT(*) FROM users WHERE user_type = 'STUDENT') AS totalAlunos,
        (SELECT COUNT(*) FROM certificates) AS totalCertificados,
        (SELECT COALESCE(SUM(workload_hours), 0) FROM events e JOIN certificates c ON e.id = c.event_id) AS horasTotais,
        (SELECT ROUND(AVG(total_horas_acumuladas), 2) FROM vw_horas_extracurriculares_aluno) AS studentAverage
    """, nativeQuery = true)
    List<Object[]> getGlobalMetrics();
}