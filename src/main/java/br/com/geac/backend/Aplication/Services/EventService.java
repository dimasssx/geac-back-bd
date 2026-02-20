package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Request.EventRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.EventResponseDTO;
import br.com.geac.backend.Aplication.Mappers.EventMapperr;
import br.com.geac.backend.Aplication.Mappers.LocationMapper;
import br.com.geac.backend.Domain.Entities.*;
import br.com.geac.backend.Repositories.*;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EventService {
    private final EventRepository eventRepository;
    private final LocationRepository locationRepository;
    private final CategoryRepository categoryRepository;
    private final EventRequirementRepository eventRequirementRepository;
    private final EventMapperr eventMapperr;
    private final TagRepository tagRepository;
    // private final UserRepository userRepository;

    @Transactional
    public EventResponseDTO createEvent(EventRequestDTO dto) {
        User organizer = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (organizer.getRole() == null || !organizer.getRole().name().equals("PROFESSOR")) {
            throw new AccessDeniedException("Apenas organizadores podem cadastrar eventos.");
        }

        Category category = categoryRepository.findById(dto.categoryId())
                .orElseThrow(() -> new RuntimeException("Categoria não encontrada com ID: " + dto.categoryId()));

        Location location = null;
        if (dto.locationId() != null) {
            location = locationRepository.findById(dto.locationId())
                    .orElseThrow(() -> new RuntimeException("Local não encontrado com ID: " + dto.locationId()));
        }

        EventRequirement requirement = eventRequirementRepository.findById(dto.requirementId())
                .orElseThrow(() -> new RuntimeException("Requisito não encontrado com ID: " + dto.requirementId()));

        Event event = new Event();
        event.setTitle(dto.title());
        event.setDescription(dto.description());
        event.setOnlineLink(dto.onlineLink());
        event.setStartTime(dto.startTime());
        event.setEndTime(dto.endTime());
        event.setWorkloadHours(dto.workloadHours());
        event.setMaxCapacity(dto.maxCapacity());
        event.setStatus("ACTIVE");

        event.setOrganizer(organizer);
        event.setCategory(category);
        event.setLocation(location);
        event.setRequirement(requirement);
        event.setTags(resolveTags(dto.tags()));
        Event saved = eventRepository.save(event);

        return eventMapperr.toResponseDTO(saved);
    }


    @Transactional(readOnly = true)
    public List<EventResponseDTO> getAllEvents() {
        List<Event> events = eventRepository.findAll();
        return events.stream().map(eventMapperr::toResponseDTO).toList();
    }

    @Transactional(readOnly = true)
    public EventResponseDTO getEventById(UUID id) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Evento não encontrado com o ID: " + id));
        return eventMapperr.toResponseDTO(event);
    }


    private Set<Tag> resolveTags(Set<Integer> ids) {
        if (ids == null || ids.isEmpty()) return Set.of();
        return tagRepository.findAllByIdIn(ids);
    }

    protected List<String> resolveSpeakers(Event event) {
        return List.of("Palestrante 1", "Palestrante 2"); //TODO: implementar no banco
    }

    protected List<String> resolveRequirementDescriptions(Event event) {
        if (event.getRequirement() == null) return List.of();
        return List.of(event.getRequirement().getDescription());
    }

}
