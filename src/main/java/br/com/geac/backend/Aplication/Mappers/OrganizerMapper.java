package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.OrganizerRequestDTO;
import br.com.geac.backend.Domain.Entities.Organizer;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface OrganizerMapper {
    OrganizerResponseDTO toResponseDTO(Organizer organizer);

    Organizer toEntity(OrganizerRequestDTO dto);
}