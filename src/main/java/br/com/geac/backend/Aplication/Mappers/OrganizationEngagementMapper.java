package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizationEngagementResponseDTO;
import br.com.geac.backend.Domain.Entities.OrganizationEngagement;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface OrganizationEngagementMapper {
    OrganizationEngagementResponseDTO toResponseDTO(OrganizationEngagement entity);
}
