package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventStatisticsResponseDTO;
import br.com.geac.backend.Domain.Entities.EventStatistics;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface EventStatisticsMapper {
    EventStatisticsResponseDTO toResponseDTO(EventStatistics entity);
}
