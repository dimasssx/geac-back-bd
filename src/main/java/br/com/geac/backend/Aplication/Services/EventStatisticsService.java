package br.com.geac.backend.Aplication.Services;

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

}
