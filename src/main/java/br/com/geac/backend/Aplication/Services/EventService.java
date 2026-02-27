package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EventPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EventRequestDTO;
import br.com.geac.backend.Aplication.Mappers.EventMapper;
import br.com.geac.backend.Domain.Entities.*;
import br.com.geac.backend.Domain.Enums.EventStatus;
import br.com.geac.backend.Domain.Enums.Role;
import br.com.geac.backend.Domain.Exceptions.*;
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
    private final RegistrationRepository registrationRepository;


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
            throw new BadRequestException("Erro inesperado, não deveria ter chegado aqui pelo fluxo normal.");
        }

        if (eventRepository.existsByTitleIgnoreCaseAndOrganizerIdAndStartTime(dto.title(), organization.getId(), dto.startTime())) {
            throw new EventAlreadyExistsException("Um evento com este título e horário já foi cadastrado por esta organização.");
        }

        Event event = eventMapper.toEntity(dto);
        event.setOrganizer(organization);
        event.setCategory(category);
        event.setLocation(location);
        event.setRequirements(resolveRequirements(dto.requirementIds()));
        event.setTags(resolveTags(dto.tags()));
        event.setSpeakers(resolveSpeakers(dto.speakers()));
        Event saved = eventRepository.save(event);
        return eventMapper.toResponseDTO(saved, false);
    }

    private Set<EventRequirement> resolveRequirements(Collection<Integer> requirementIds) {
        if (requirementIds == null || requirementIds.isEmpty()) {
            return new HashSet<>();
        }

        List<EventRequirement> requirements = eventRequirementRepository.findAllById(requirementIds);

        if (requirements.size() != requirementIds.size()) {
            throw new RequirementNotFoundException("Um ou mais requisitos informados não foram encontrados no sistema.");
        }

        return new HashSet<>(requirements);
    }


    @Transactional(readOnly = true)
    public List<EventResponseDTO> getAllEvents() {
        List<Event> events = eventRepository.findAll();
        return events.stream()
                .map(event -> eventMapper.toResponseDTO(event, checkUserRegistration(event.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public EventResponseDTO getEventById(UUID id) {
        Event event = getEventByIdOrThrow(id);
        return eventMapper.toResponseDTO(event, checkUserRegistration(event.getId()));
    }

    @Transactional
    public EventResponseDTO patchEvent(UUID id, EventPatchRequestDTO dto) {

        Event event = getEventByIdOrThrow(id);
        validateEventOwnership(event);
        eventMapper.updateEventFromDto(dto, event);

        if (dto.speakers() != null) event.setSpeakers(resolveSpeakers(dto.speakers()));
        if (dto.tags() != null) event.setTags(resolveTags(dto.tags()));
        if (dto.requirementIds() != null) {
            event.setRequirements(resolveRequirements(dto.requirementIds()));
        }
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
                throw new BadRequestException("erro inesperado de validation em algum lugar pois não everia chegar aqui pelo fluxo normal");
            }
            event.setOrganizer(organization);
        }
        String checkTitle = dto.title() != null ? dto.title() : event.getTitle();
        LocalDateTime checkStartTime = dto.startTime() != null ? dto.startTime() : event.getStartTime();

        if (eventRepository.existsByTitleIgnoreCaseAndOrganizerIdAndStartTime(checkTitle, event.getOrganizer().getId(), checkStartTime)) {
            if (!checkTitle.equalsIgnoreCase(event.getTitle()) || !checkStartTime.equals(event.getStartTime())) {
                throw new EventAlreadyExistsException("Já existe outro evento com este título e horário nesta organização.");
            }
        }
        return eventMapper.toResponseDTO(eventRepository.save(event), checkUserRegistration(event.getId()));

    }

    private Boolean checkUserRegistration(UUID eventId) {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            return false;
        }
        try {
            User user = (User) authentication.getPrincipal();
            return registrationRepository.existsByUserIdAndEventId(user.getId(), eventId);
        } catch (ClassCastException e) {
            return false; // Prevenção caso o principal não seja do tipo User
        }
    }

    private void validateEventOwnership(Event event) {
        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (loggedUser.getRole() == Role.ADMIN) return; // Admin pode tudo

        boolean isMember = organizerMemberRepository.existsByOrganizerIdAndUserId(event.getOrganizer().getId(), loggedUser.getId());
        if (!isMember) {
            throw new AccessDeniedException("Você não pertence à organização dona deste evento.");
        }
    }

    @Transactional
    public void deleteEvent(UUID id) {
        Event event = getEventByIdOrThrow(id);
        validateEventOwnership(event);
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
                .orElseThrow(() -> new EventNotFoundException("Evento não encontrado com o ID: " + id));
    }

    public List<Event> getEventsBetween(LocalDateTime now, LocalDateTime eventDate) {
        return eventRepository.findAllByStartTimeBetween(now,eventDate);
    }

    public List<Event> getPastEvents(LocalDateTime now) {
        return eventRepository.findAllByStartTimeBeforeAndStatusNot(LocalDateTime.now().minusMinutes(1), EventStatus.COMPLETED);
    }
}
