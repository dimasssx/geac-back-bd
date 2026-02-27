package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.PendingRequestResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CreateOrganizerRequestDTO;
import br.com.geac.backend.Domain.Entities.*;
import br.com.geac.backend.Domain.Enums.RequestStatus;
import br.com.geac.backend.Domain.Enums.Role;
import br.com.geac.backend.Domain.Exceptions.*;
import br.com.geac.backend.Infrastructure.Repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class OrganizerRequestService {

    private final OrganizerRequestRepository requestRepository;
    private final OrganizerMemberRepository memberRepository;
    private final UserRepository userRepository;
    private final OrganizerRepository organizerRepository;
    private final NotificationService notificationService;

    @Transactional(readOnly = true)
    public List<PendingRequestResponseDTO> getPendingRequests() {
        return requestRepository.findAllByStatus(RequestStatus.PENDING).stream()
                .map(req -> new PendingRequestResponseDTO(
                        req.getId(),
                        req.getUser().getName(),
                        req.getUser().getEmail(),
                        req.getOrganizer().getName(),
                        req.getJustification(),
                        req.getCreatedAt()
                )).toList();
    }

    @Transactional
    public void approveRequest(Integer requestId) { // TODO:DEVERIA USAR ADDMEMBER de organizer member
        OrganizerRequest request = findRequestOrThrow(requestId);
        var user = userRepository.findById(request.getUser().getId())
                .orElseThrow(()->new UserNotFoundException("Usuário nao encontrado"));

        request.setStatus(RequestStatus.APPROVED);
        request.setResolvedAt(LocalDateTime.now());
        requestRepository.save(request);

        // Se foi aprovado, adiciona como membro da organização (se ainda não for)
        boolean alreadyMember = memberRepository.existsByOrganizerIdAndUserId(
                request.getOrganizer().getId(), request.getUser().getId());

        if (!alreadyMember) {
            OrganizerMember newMember = new OrganizerMember();
            newMember.setOrganizer(request.getOrganizer());
            newMember.setUser(request.getUser());
            memberRepository.save(newMember);
            if (user.getRole().equals(Role.STUDENT) || user.getRole().equals(Role.PROFESSOR)) {
                user.setRole(Role.ORGANIZER);
                userRepository.save(user);
            }

            Notification notif = new Notification();
            notif.setUser(user);
            notif.setTitle("Solicitação Aprovada!");
            notif.setMessage("Parabéns! Sua solicitação para participar da organização '" + request.getOrganizer().getName() + "' foi aceita. Você agora é um organizador.");
            notif.setType("APPROVED");
            notif.setRead(false);
            notif.setCreatedAt(LocalDateTime.now());
            notificationService.notify(notif);

        }
    }

    @Transactional
    public void rejectRequest(Integer requestId) {
        OrganizerRequest request = findRequestOrThrow(requestId);
        request.setStatus(RequestStatus.REJECTED);
        request.setResolvedAt(LocalDateTime.now());
        requestRepository.save(request);
        Notification notif = new Notification();
        notif.setUser(request.getUser());
        notif.setTitle("Solicitação não foi aceita!");
        notif.setMessage("Sua solicitação para participar da organização '" + request.getOrganizer().getName() + "' não foi aceita. Fale com algum professor e tente novamente");
        notif.setType("REJECTED");
        notif.setRead(false);
        notif.setCreatedAt(LocalDateTime.now());
        notificationService.notify(notif);
    }

    @Transactional
    public void createRequest(CreateOrganizerRequestDTO dto) {
        if (requestRepository.existsByUserIdAndOrganizerIdAndStatus(dto.userId(), dto.organizerId(), RequestStatus.PENDING)) {
            throw new RequestAlreadyExists("Já existe uma solicitação pendente deste usuário para esta organização.");
        }
        if (memberRepository.existsByOrganizerIdAndUserId(dto.organizerId(), dto.userId())) {
            throw new UserIsAlreadyOrgMember("Usuário já é membro desta organização.");
        }

        User user = userRepository.findById(dto.userId())
                .orElseThrow(() -> new UserNotFoundException("Usuário não encontrado."));
        Organizer organizer = organizerRepository.findById(dto.organizerId())
                .orElseThrow(() -> new OrganizerNotFoundExceptio("Organização não encontrada."));

        OrganizerRequest request = new OrganizerRequest();
        request.setUser(user);
        request.setOrganizer(organizer);
        request.setJustification(dto.justification());
        request.setStatus(RequestStatus.PENDING);

        requestRepository.save(request);

        List<User> admins = userRepository.findAllByRole(Role.ADMIN);
        for (User admin : admins) {
            Notification adminNotif = new Notification();
            adminNotif.setUser(admin);
            adminNotif.setTitle("Nova Solicitação de Organização");
            adminNotif.setMessage("O usuário " + user.getName() + " solicitou entrada na organização '" + organizer.getName() + "'. Acesse o painel para aprovar ou rejeitar.");
            adminNotif.setType("REQUEST");
            adminNotif.setRead(false);
            adminNotif.setCreatedAt(LocalDateTime.now());
            notificationService.notify(adminNotif);

        }

    }

    private OrganizerRequest findRequestOrThrow(Integer id) {
        OrganizerRequest request = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Solicitação não encontrada."));
        if (request.getStatus() != RequestStatus.PENDING) {
            throw new ConflictException("Esta solicitação já foi " + request.getStatus().name() + " e não pode ser alterada.");
        }
        return request;
    }
}