package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.QualificationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.QualificationRequestDTO;
import br.com.geac.backend.Domain.Entities.Qualification;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface QualificationMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "speaker", ignore = true)
    Qualification toEntity(QualificationRequestDTO dto);

    QualificationResponseDTO toDTO(Qualification entity);
}
