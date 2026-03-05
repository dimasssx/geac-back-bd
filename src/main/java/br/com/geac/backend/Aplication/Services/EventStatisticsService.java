package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventDashBoardResponse;
import br.com.geac.backend.Aplication.DTOs.Reponse.EventStatisticsResponseDTO;
import br.com.geac.backend.Aplication.Mappers.EventStatisticsMapper;
import br.com.geac.backend.Infrastructure.Repositories.EventStatisticsRepositoryView;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EventStatisticsService {

    private final EventStatisticsRepositoryView repository;
    private final EventStatisticsMapper mapper;

    public List<EventStatisticsResponseDTO> getAllEventStatistics() {
        return repository.findTopEventsByEngagement().stream()
                .map(event -> new EventStatisticsResponseDTO(
                        (UUID) event[0],
                        (String) event[1],
                        ((String) event[2]),
                        event[3] != null ? ((Number) event[3]).longValue() : 0L,
                        event[4] != null ? ((Number) event[4]).longValue() : 0L,
                        event[5] != null ? ((Number) event[5]).doubleValue() : 0.0)
                ).toList();
    }

    public EventDashBoardResponse getEventDashBoard() {

        var dashboard = repository.getGlobalDashboardStats();
        if (dashboard == null || dashboard.isEmpty()) {
            return new EventDashBoardResponse(0L, 0L, 0L, 0L, 0L, 0L, 0L,0D, 0D);
        }
        var stats = dashboard.getFirst();
        return new EventDashBoardResponse(
                        ((Number) stats[0]).longValue(),
                        ((Number) stats[1]).longValue(),
                        ((Number) stats[2]).longValue(),
                        ((Number) stats[3]).longValue(),
                        ((Number) stats[4]).longValue(),
                        ((Number) stats[5]).longValue(),
                        ((Number) stats[6]).longValue(),
                        ((Number) stats[7]).doubleValue(),
                        ((Number) stats[8]).doubleValue()
                );

    }
}
