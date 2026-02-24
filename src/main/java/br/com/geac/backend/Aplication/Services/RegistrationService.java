package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.RegistrationResponseDTO;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Repositories.EventRepository;
import br.com.geac.backend.Repositories.RegistrationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RegistrationService {

    private final RegistrationRepository registrationRepository;
    private final EventRepository eventRepository;

    @Transactional
    public void markAttendanceInBulk(UUID eventId, List<UUID> userIds, boolean attended) {

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Evento não encontrado com o ID: " + eventId));

        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        if (!event.getOrganizer().getId().equals(loggedUser.getId())) {
            throw new AccessDeniedException("Acesso negado: Você não é o organizador deste evento e não pode registrar presenças.");
        }

        registrationRepository.updateAttendanceInBulk(eventId, userIds, attended);
    }

    @Transactional(readOnly = true)
    public List<RegistrationResponseDTO> getRegistrationsByEvent(UUID eventId) {

        // 1. Busca o evento para validar o organizador
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Evento não encontrado."));

        // 2. Valida se quem está pedindo a lista é o organizador do evento
        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (!event.getOrganizer().getId().equals(loggedUser.getId())) {
            throw new AccessDeniedException("Acesso negado: Você não pode ver a lista de presença de um evento que não organiza.");
        }

        // 3. Busca as inscrições e converte para DTO
        List<Registration> registrations = registrationRepository.findByEventId(eventId);

        return registrations.stream()
                .map(reg -> new RegistrationResponseDTO(
                        reg.getUser().getId(),
                        reg.getUser().getName(),
                        reg.getUser().getEmail(),
                        reg.getAttended(),
                        reg.getStatus()
                ))
                .toList();
    }
}