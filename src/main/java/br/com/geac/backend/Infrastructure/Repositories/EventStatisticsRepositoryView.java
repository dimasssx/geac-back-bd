package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.EventStatistics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EventStatisticsRepositoryView extends JpaRepository<EventStatistics, UUID> {
    @Query(value = """
    SELECT * FROM vw_eventos_estatisticas 
    ORDER BY total_presentes DESC, media_avaliacao DESC 
    """, nativeQuery = true)
    List<Object[]> findTopEventsByEngagement();

    @Query(value = """
        SELECT 
            COUNT(*) as totalEvents,
            COUNT(CASE WHEN event_status = 'ACTIVE' THEN 1 END) as activeEvents,
            COUNT(CASE WHEN event_status = 'COMPLETED' THEN 1 END) as completedEvents,
            COUNT(CASE WHEN event_status = 'CANCELLED' THEN 1 END) as cancelledEvents,
            COUNT(CASE WHEN event_status = 'UPCOMING' THEN 1 END) as upcomingEvents,
            SUM(total_inscritos) as totalInscritos,
            SUM(total_presentes) as totalPresentes,
            CASE 
                WHEN SUM(total_inscritos) > 0 
                THEN ROUND((CAST(SUM(total_presentes) AS FLOAT) / SUM(total_inscritos)) * 100) 
                ELSE 0 
            END as taxaPresenca,
            ROUND(AVG(CASE WHEN media_avaliacao > 0 THEN media_avaliacao END), 1) as avgRating
        FROM vw_eventos_estatisticas
        """, nativeQuery = true)
    List<Object[]> getGlobalDashboardStats();
}

