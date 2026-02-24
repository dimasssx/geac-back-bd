package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.SpeakerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.LocationPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerRequestDTO;
import br.com.geac.backend.Domain.Entities.Location;
import br.com.geac.backend.Domain.Entities.Speaker;
import org.mapstruct.*;

@Mapper(componentModel = "spring", uses = QualificationMapper.class)
public interface SpeakerMapper {

    SpeakerResponseDTO toDto(Speaker speaker);

    @Mapping(target = "qualifications", ignore = true)
    @Mapping(target = "id", ignore = true)
    Speaker toEntity(SpeakerRequestDTO requestDTO);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mapping(target = "qualifications", ignore = true)
    void updateEntityFromDTO(SpeakerPatchRequestDTO dto, @MappingTarget Speaker location);

}
