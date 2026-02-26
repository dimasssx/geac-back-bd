package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EventPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EventRequestDTO;
import br.com.geac.backend.Aplication.Mappers.EventMapper;
import br.com.geac.backend.Domain.Entities.*;
import br.com.geac.backend.Domain.Enums.Role;
import br.com.geac.backend.Domain.Exceptions.BadRequestException;
import br.com.geac.backend.Domain.Exceptions.CategoryNotFoundException;
import br.com.geac.backend.Domain.Exceptions.LocationNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class EventService {
    private final EventRepository eventRepository;
    private final LocationRepository locationRepository;
    private final CategoryRepository categoryRepository;
    private final EventRequirementRepository eventRequirementRepository;
    private final EventMapper eventMapper;
    private final TagRepository tagRepository;
    private final SpeakerRepository speakerRepository;
    private final OrganizerMemberRepository organizerMemberRepository;
    private final OrganizerRepository organizerRepository;
    // private final UserRepository userRepository;


    /*
    * verifica se o usuário é um organizador ou admin -> procura as categorias, localizações e eventos no banco,
    * procura a organização que foi passada no frontEnd pelo ID
    * verifica se o usuário realment pertence a esta organização ( caso algo tenha dado errado, nao era pra entrar aqui pois há diversos filtros)
    * cria o evento e manda a resposta pelo  dtoresponse
     */
    @Transactional
    public EventResponseDTO createEvent(EventRequestDTO dto) {
        User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        List<String> authorites = List.of("ORGANIZER","ADMIN");

        if (user.getRole() == null || !authorites.contains(user.getRole().name())) { //nao necessário mas uma segurança  a mais
            throw new AccessDeniedException("Apenas organizadores e administradores podem cadastrar eventos.");
        }

        Category category = categoryRepository.findById(dto.categoryId())
                .orElseThrow(() -> new CategoryNotFoundException("Categoria não encontrada com ID: " + dto.categoryId()));
        Location location = null;
        if (dto.locationId() != null) {
            location = locationRepository.findById(dto.locationId())
                    .orElseThrow(() -> new LocationNotFoundException("Local não encontrado com ID: " + dto.locationId()));
        }

        var organization = organizerRepository.findById(dto.orgId()).orElseThrow(()-> new BadRequestException("O organizador com ID: " + dto.orgId()+"nao foi encontrado") );
        if (user.getRole() != Role.ADMIN && !organizerMemberRepository.existsByOrganizerIdAndUserId(organization.getId(), user.getId())) {
            throw new BadRequestException("erro inesperado de validation em algum lugar pois naod everia chegar aqwui");
        }

        Event event = new Event();  //algum heroi ajusta omapper
        event.setTitle(dto.title());
        event.setDescription(dto.description());
        event.setOnlineLink(dto.onlineLink());
        event.setStartTime(dto.startTime());
        event.setEndTime(dto.endTime());
        event.setWorkloadHours(dto.workloadHours());
        event.setMaxCapacity(dto.maxCapacity());
        event.setStatus("ACTIVE");
        event.setOrganizer(organization);
        event.setCategory(category);
        event.setLocation(location);
        event.setRequirements(resolveRequirements(dto.requirementIds()));
        event.setTags(resolveTags(dto.tags()));
        event.setSpeakers(resolveSpeakers(dto.speakers()));
        Event saved = eventRepository.save(event);
        //TODO: setar countRegistration e incrementa-la nas inscricoes, ta faltando na entity
        return eventMapper.toResponseDTO(saved);
    }

    private Set<EventRequirement> resolveRequirements(Collection<Integer> requirementIds) {
        if (requirementIds == null || requirementIds.isEmpty()) {
            return new HashSet<>();
        }

        List<EventRequirement> requirements = eventRequirementRepository.findAllById(requirementIds);

        if (requirements.size() != requirementIds.size()) {
            throw new RuntimeException("Um ou mais requisitos informados não foram encontrados no sistema.");
        }

        return new HashSet<>(requirements);
    }


    @Transactional(readOnly = true)
    public List<EventResponseDTO> getAllEvents() {
        List<Event> events = eventRepository.findAll();
        return events.stream().map(eventMapper::toResponseDTO).toList();
    }

    @Transactional(readOnly = true)
    public EventResponseDTO getEventById(UUID id) {
        Event event = getEventByIdOrThrow(id);
        return eventMapper.toResponseDTO(event);
    }

    @Transactional
    public EventResponseDTO patchEvent(UUID id, EventPatchRequestDTO dto) {

        Event event = getEventByIdOrThrow(id);
        eventMapper.updateEventFromDto(dto, event);

        if (dto.speakers() != null) event.setSpeakers(resolveSpeakers(dto.speakers()));
        if (dto.tags() != null) event.setTags(resolveTags(dto.tags()));
        if (dto.requirementIds() != null) {
            event.setRequirements(resolveRequirements(dto.requirementIds()));
        }
        // por enquanto so tem 1 categoria, mas se tiver mais de 1 no futuro, tem que resolver a mesma coisa dos speakers e tags
        if (dto.categoryId() != null) {
            var category = categoryRepository.findById(dto.categoryId()).orElseThrow();
            event.setCategory(category);
        }
        if (dto.locationId() != null) {
            Location location = locationRepository.findById(dto.locationId()).orElseThrow();
            event.setLocation(location);
        }
        if (dto.orgId() != null) {
            User user = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            List<String> authorites = List.of("ORGANIZER","ADMIN");
            if (user.getRole() == null || !authorites.contains(user.getRole().name())) { //nao necessário mas uma segurança  a mais
                throw new AccessDeniedException("Apenas organizadores e administradores podem editar eventos.");
            }
            var organization = organizerRepository.findById(dto.orgId()).orElseThrow(()-> new BadRequestException("O organizador com ID: " + dto.orgId()+"nao foi encontrado") );
            if (user.getRole() != Role.ADMIN && !organizerMemberRepository.existsByOrganizerIdAndUserId(organization.getId(), user.getId())) {
                throw new BadRequestException("erro inesperado de validation em algum lugar pois naod everia chegar aqwui");
            }
            event.setOrganizer(organization);
        }
        return eventMapper.toResponseDTO(eventRepository.save(event));

    }

    @Transactional
    public void deleteEvent(UUID id) {
        Event event = getEventByIdOrThrow(id);
        eventRepository.delete(event);
    }

    private Set<Tag> resolveTags(Set<Integer> ids) {
        if (ids == null || ids.isEmpty()) return Set.of();
        return tagRepository.findAllByIdIn(ids);
    }

    private Set<Speaker> resolveSpeakers(Set<Integer> ids) {
        if (ids == null || ids.isEmpty()) return Set.of();
        return speakerRepository.findAllByIdIn(ids);
    }

    private Event getEventByIdOrThrow(UUID id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Evento não encontrado com o ID: " + id));
    }

    public List<Event> getEventsBetween(LocalDateTime now, LocalDateTime eventDate) {
        return eventRepository.findAllByStartTimeBetween(now,eventDate);
    }
}
