package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.RegistrationResponseDTO;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.Notification;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Enums.EventStatus;
import br.com.geac.backend.Domain.Exceptions.*;
import br.com.geac.backend.Infrastructure.Repositories.EventRepository;
import br.com.geac.backend.Infrastructure.Repositories.RegistrationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import br.com.geac.backend.Infrastructure.Repositories.OrganizerMemberRepository;
import br.com.geac.backend.Aplication.Services.CertificateService;

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
    private final OrganizerMemberRepository organizerMemberRepository;
    private final CertificateService certificateService;

    @Transactional
    public void markAttendanceInBulk(UUID eventId, List<UUID> userIds, boolean attended) {

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new EventNotFoundException("Evento não encontrado com o ID: " + eventId));

        //agora usa o metodo que valida se o usuario e Admin ou membro da organizacao
        validateOrganizerAccess(event);

        registrationRepository.updateAttendanceInBulk(eventId, userIds, attended);

        //emissao de certificados
        if (attended) {
            certificateService.issueCertificatesForEvent(eventId);
        }
    }

    @Transactional(readOnly = true)
    public List<RegistrationResponseDTO> getRegistrationsByEvent(UUID eventId) {

        // 1. Busca o evento para validar o organizador
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new EventNotFoundException("Evento não encontrado."));

//TODO        validateOrganizerAccess(event);

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
                .orElseThrow(() -> new EventNotFoundException("Evento não encontrado com o ID: " + eventId));

        if (registrationRepository.existsByUserIdAndEventId(loggedUser.getId(), eventId)) {
            throw new UserAlreadySubscribedInEvent("Você já está inscrito neste evento.");
        }

        if (organizerMemberRepository.existsByOrganizerIdAndUserId(event.getOrganizer().getId(), loggedUser.getId())) {
            throw new MemberOfPromoterOrgException("Você não pode se inscrever no evento que sua organização está promovendo.");
        }

        if (event.getRegisteredCount() >= event.getMaxCapacity()) {
            throw new EventMaxCapacityAchievedException("Desculpe, este evento já atingiu a capacidade máxima de " + event.getMaxCapacity() + " participantes.");
        }
        if((event.getStatus() != EventStatus.ACTIVE) && (event.getStatus() != EventStatus.UPCOMING)) {
            throw new EventNotAvailableException("O Evento que voce está tentando se inscrever ainda nao está disponivel ou já foi encerrado");
        }

        event.setRegisteredCount(event.getRegisteredCount() + 1);
        eventRepository.save(event);

        Registration registration = new Registration();
        registration.setUser(loggedUser);
        registration.setEvent(event);
        registration.setStatus("CONFIRMED");

        Notification notification = new Notification();
        notification.setUser(loggedUser);
        notification.setEvent(event);
        notification.setTitle("Inscrição Confirmada");
        notification.setMessage("Parabéns! Sua inscrição no evento '" + event.getTitle() + "' foi realizada com sucesso.");
        notification.setType("SUBSCRIBE");
        notification.setRead(false);
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
                .orElseThrow(() -> new RegistrationNotFoundException("Você não possui uma inscrição ativa neste evento."));

        // 3. (Opcional) Regra de negócio extra: Não permitir cancelar se a presença já foi dada
        if (Boolean.TRUE.equals(registration.getAttended())) {
            throw new BadRequestException("Não é possível cancelar a inscrição pois sua presença já foi validada no evento.");
        }

        // 4. DECREMENTA O CONTADOR E SALVA (Devolve a vaga)
        Event event = registration.getEvent();
        if (event.getRegisteredCount() > 0) {
            event.setRegisteredCount(event.getRegisteredCount() - 1);
            eventRepository.save(event);
        }

        Notification notification = new Notification();
        notification.setUser(loggedUser);
        notification.setEvent(event);
        notification.setTitle("Inscrição Cancelada");
        notification.setMessage("Sua inscrição no evento '" + event.getTitle() + "' foi cancelada com sucesso. Uma vaga foi liberada.");
        notification.setType("CANCEL");
        notification.setRead(false);
        notification.setCreatedAt(LocalDateTime.now());

        notificationService.notify(notification);

        registrationRepository.delete(registration);
    }

    public void saveAll(List<Registration> registrations) {
        registrationRepository.saveAll(registrations);
    }

    private void validateOrganizerAccess(Event event) {
        User loggedUser = getLoggedUser();

        boolean isAdmin = loggedUser.getRole() == br.com.geac.backend.Domain.Enums.Role.ADMIN;
        boolean isMember = organizerMemberRepository.existsByOrganizerIdAndUserId(event.getOrganizer().getId(), loggedUser.getId());

        if (!isAdmin && !isMember) {
            throw new BadRequestException("Acesso negado: Você não é membro da organização responsável por este evento."); //todo colocar forbiden no handler ou unauthorized
        }
    }

    private User getLoggedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}