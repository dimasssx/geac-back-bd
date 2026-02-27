package br.com.geac.backend.Aplication.Mappers;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.RequirementsResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.UserRegistrationContextResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EventPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EventRequestDTO;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.EventRequirement;
import br.com.geac.backend.Domain.Entities.Speaker;
import br.com.geac.backend.Domain.Entities.Tag;
import org.mapstruct.*;

import java.util.List;
import java.util.Set;

@Mapper(componentModel = "spring", uses = {LocationMapper.class})
public interface EventMapper {

    @Mapping(target = "categoryId", source = "event.category.id")
    @Mapping(target = "categoryName", source = "event.category.name")
    @Mapping(target = "organizerName", source = "event.organizer.name")
    @Mapping(target = "organizerEmail", source = "event.organizer.contactEmail")
    @Mapping(target = "speakers", source = "event", qualifiedByName = "mapSpeakers")
    @Mapping(target = "status", source = "event.status")
    @Mapping(target = "isRegistered", source = "context.isRegistered")
    @Mapping(target = "userRegistrationStatus", source = "context.status")
    @Mapping(target = "userAttended", source = "context.attended")
    EventResponseDTO toResponseDTO(Event event, UserRegistrationContextResponseDTO context);

    @Mapping(target = "categoryId", source = "event.category.id")
    @Mapping(target = "categoryName", source = "event.category.name")
    @Mapping(target = "organizerName", source = "event.organizer.name")
    @Mapping(target = "organizerEmail", source = "event.organizer.contactEmail")
    @Mapping(target = "speakers", source = "event", qualifiedByName = "mapSpeakers")
    @Mapping(target = "status", source = "event.status")
    @Mapping(target = "isRegistered", source = "context.isRegistered")
    @Mapping(target = "userRegistrationStatus", source = "context.status")
    @Mapping(target = "userAttended", source = "context.attended")
    @Mapping(target = "registeredCount", source = "count",defaultValue = "0")
    EventResponseDTO toResponseDTO(Event event, UserRegistrationContextResponseDTO context,Integer count);

    RequirementsResponseDTO toRequirementDTO(EventRequirement eventRequirement);

    @Named("mapSpeakers")
    default List<String> mapSpeakers(Event event) {
        if (event.getSpeakers() == null) return List.of();
        return event.getSpeakers().stream()
                .map(Speaker::getName)
                .toList();
    }

    default List<String> mapTags(Set<Tag> tags) {
        if (tags == null) return List.of();
        return tags.stream().map(Tag::getName).toList();
    }



    @Mapping(target = "id", ignore = true)
    @Mapping(target = "organizer", ignore = true)
    @Mapping(target = "category", ignore = true)
    @Mapping(target = "location", ignore = true)
    @Mapping(target = "requirements", ignore = true)
    @Mapping(target = "tags", ignore = true)
    @Mapping(target = "speakers", ignore = true)
    @Mapping(target = "status", constant = "ACTIVE")
    @Mapping(target = "createdAt", ignore = true)
    Event toEntity(EventRequestDTO dto);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mapping(target = "tags", ignore = true)
    @Mapping(target = "speakers", ignore = true)
    @Mapping(target = "category", ignore = true)
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "requirements", ignore = true)
    @Mapping(target = "location", ignore = true)
    @Mapping(target = "organizer", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    void updateEventFromDto(EventPatchRequestDTO dto, @MappingTarget Event entity);

}