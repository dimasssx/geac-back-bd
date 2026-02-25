package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.RequirementsResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.RequirementRequestDTO;
import br.com.geac.backend.Domain.Entities.EventRequirement;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface RequirementMapper {

    EventRequirement toEntity(RequirementRequestDTO dto);

    RequirementsResponseDTO toDTO(EventRequirement entity);
}
