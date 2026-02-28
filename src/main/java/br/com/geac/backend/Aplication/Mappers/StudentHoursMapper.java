package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Request.StudentHoursResponseDTO;
import br.com.geac.backend.Domain.Entities.StudentExtracurricularHours;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface StudentHoursMapper {
    StudentHoursResponseDTO toResponseDTO(StudentExtracurricularHours entity);
}