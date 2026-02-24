package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.SpeakerResponseDTO;
import br.com.geac.backend.Domain.Entities.Qualification;
import br.com.geac.backend.Domain.Entities.Speaker;
import org.mapstruct.Mapper;

import java.util.Set;
import java.util.stream.Collectors;

@Mapper(componentModel = "spring")
public interface SpeakerMapper {

    SpeakerResponseDTO toDto(Speaker speaker);
    default Set<String> mapQualifications(Set<Qualification> qualifications) {
        if (qualifications == null) return Set.of();
        return qualifications.stream()
                .map(Qualification::getTitleName)
                .collect(Collectors.toSet());
    }
}
