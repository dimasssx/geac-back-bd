package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.OrganizationEngagement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrganizationEngagementRepository extends JpaRepository<OrganizationEngagement, UUID> {
    @Query(value = """
            SELECT * FROM vw_engajamento_organizacoes 
            ORDER BY total_participantes_engajados DESC 
            """, nativeQuery = true)
    List<Object[]> findTopOrganizations();
    @Query(value = """
            SELECT 
                COUNT(*) as totalOrgs,
                SUM(total_eventos_realizados) as totalEvents,
                SUM(total_participantes_engajados) as totalEngaged,
                ROUND(AVG(total_eventos_realizados)::numeric, 1) as avgEventsPerOrg,
                ROUND(AVG(total_participantes_engajados)::numeric, 1) as avgEngagedPerOrg,
                COUNT(CASE WHEN total_eventos_realizados > 0 THEN 1 END) as activeOrgs,
                -- Distribuição de Atividade
                COUNT(CASE WHEN total_eventos_realizados = 0 THEN 1 END) as inactiveCount,
                COUNT(CASE WHEN total_eventos_realizados BETWEEN 1 AND 3 THEN 1 END) as lowCount,
                COUNT(CASE WHEN total_eventos_realizados BETWEEN 4 AND 10 THEN 1 END) as mediumCount,
                COUNT(CASE WHEN total_eventos_realizados > 10 THEN 1 END) as highCount
            FROM vw_engajamento_organizacoes
            """, nativeQuery = true)
    List<Object[]> getDashBoard();

    @Query(value = """
            SELECT organizer_id as orgId, organizer_name as orgName, total_eventos_realizados as value
            FROM vw_engajamento_organizacoes
            ORDER BY total_eventos_realizados DESC
            LIMIT 5
            """, nativeQuery = true)
    List<Object[]> findTop5ByEvents();
    @Query(value = """
            SELECT organizer_id as orgId, organizer_name as orgName, total_participantes_engajados as value
            FROM vw_engajamento_organizacoes
            ORDER BY total_participantes_engajados DESC
            LIMIT 5
            """, nativeQuery = true)
    List<Object[]> findTop5ByEngagement();

}
