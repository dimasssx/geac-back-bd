package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.RegistrationResponseDTO;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.Notification;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Infrastructure.Repositories.EventRepository;
import br.com.geac.backend.Infrastructure.Repositories.RegistrationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Log4j2
public class RegistrationService {

    private final RegistrationRepository registrationRepository;
    private final EventRepository eventRepository;
    private final NotificationService notificationService;

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
//        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
//        if (!event.getOrganizer().getId().equals(loggedUser.getId())) {
//            throw new AccessDeniedException("Acesso negado: Você não pode ver a lista de presença de um evento que não organiza.");
//        }

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
    public List<Registration> getUnotifiedRegistrationsById(UUID eventId) {
        return registrationRepository.findByEventIdAndNotified(eventId,false);
    }
    @Transactional
    public void registerToEvent(UUID eventId) {

        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Evento não encontrado com o ID: " + eventId));

        if (registrationRepository.existsByUserIdAndEventId(loggedUser.getId(), eventId)) {
            throw new ConflictException("Você já está inscrito neste evento.");
        }

        if (event.getOrganizer().getId().equals(loggedUser.getId())) {
            throw new ConflictException("Você não pode se inscrever no evento que você mesmo está organizando.");
        }

        long currentRegistrations = registrationRepository.countByEventId(eventId);
        if (currentRegistrations >= event.getMaxCapacity()) {
            throw new ConflictException("Desculpe, este evento já atingiu a capacidade máxima de " + event.getMaxCapacity() + " participantes.");
        }

        Registration registration = new Registration();
        registration.setUser(loggedUser);
        registration.setEvent(event);
        registration.setStatus("CONFIRMED");

        Notification notification = new Notification();
        notification.setUser(loggedUser);
        notification.setMessage("Congrats, your registration was sucessfull");
        notification.setRead(false);
        notification.setType("SUBSCRIBE");
        notification.setEvent(event);
        notification.setCreatedAt(LocalDateTime.now());

        notificationService.notify(notification);
        log.info("Registrado com sucesso"+ notification.getMessage());
        registrationRepository.save(registration);
    }

    @Transactional
    public void cancelRegistration(UUID eventId) {
        // 1. Pega o usuário logado
        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        // 2. Busca a inscrição dele no evento
        Registration registration = registrationRepository.findByUserIdAndEventId(loggedUser.getId(), eventId)
                .orElseThrow(() -> new ConflictException("Você não possui uma inscrição ativa neste evento."));

        // 3. (Opcional) Regra de negócio extra: Não permitir cancelar se a presença já foi dada
        if (Boolean.TRUE.equals(registration.getAttended())) {
            throw new ConflictException("Não é possível cancelar a inscrição pois sua presença já foi validada no evento.");
        }

        // 4. Deleta a inscrição do banco (liberando a vaga automaticamente)

//        Notification notification = new Notification(); TODO
//        notification.setUser(loggedUser);
//        notification.setMessage("Congrats, your registration was sucessfull");
//        notification.setRead(false);
//        notification.setType("SUBSCRIBE");
//        notification.setEvent(event);
//        notification.setCreatedAt(LocalDateTime.now());
//
//        notificationService.notify(notification);
        registrationRepository.delete(registration);
    }

    public void saveAll(List<Registration> registrations) {
        registrationRepository.saveAll(registrations);
    }
}