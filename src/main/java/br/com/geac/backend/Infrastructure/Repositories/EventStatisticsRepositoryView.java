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

}

