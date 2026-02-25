package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.TagResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.TagRequestDTO;
import br.com.geac.backend.Domain.Entities.Tag;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface TagMapper {

    Tag toEntity(TagRequestDTO dto);

    TagResponseDTO toDTO(Tag tag);
}
