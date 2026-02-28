package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventStatisticsResponseDTO;
import br.com.geac.backend.Aplication.Mappers.EventStatisticsMapper;
import br.com.geac.backend.Infrastructure.Repositories.EventStatisticsRepositoryView;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EventStatisticsService {

    private final EventStatisticsRepositoryView repository;
    private final EventStatisticsMapper mapper;

    public List<EventStatisticsResponseDTO> getAllEventStatistics() {
        return repository.findAll()
                .stream()
                .map(mapper::toResponseDTO)
                .toList();
    }
}
