package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.EvaluationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EvaluationRequestDTO;
import br.com.geac.backend.Aplication.Mappers.EvaluationMapper;
import br.com.geac.backend.Domain.Entities.Evaluation;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Enums.EventStatus;
import br.com.geac.backend.Domain.Exceptions.BadRequestException;
import br.com.geac.backend.Domain.Exceptions.EventNotFinishedException;
import br.com.geac.backend.Domain.Exceptions.EventNotFoundException;
import br.com.geac.backend.Domain.Exceptions.RegistrationNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.EvaluationRepository;
import br.com.geac.backend.Infrastructure.Repositories.EventRepository;
import br.com.geac.backend.Infrastructure.Repositories.RegistrationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Log4j2
public class EvaluationService {
    private final EvaluationRepository evaluationRepository;
    private final RegistrationRepository registrationRepository;
    private final EventRepository eventRepository;
    private final EvaluationMapper mapper;
    //TODO: EDITAR E REMOVER

    public EvaluationResponseDTO createEvaluation(EvaluationRequestDTO dto, User authenticatedUser) {

        Registration registration = registrationRepository.findByUserIdAndEventId(authenticatedUser.getId(),dto.eventId())
                .orElseThrow(()-> new RegistrationNotFoundException("A inscrição não foi encontrada"));
        if (!registration.getUser().getId().equals(authenticatedUser.getId())) {
            throw new BadRequestException("Você está tentando avaliar uma inscrição que nao é sua");
        }
        if(!registration.getAttended()){
            throw new BadRequestException("Você não pode avaliar um evento que não compareceu");
        }
        if(!registration.getEvent().getStatus().equals(EventStatus.COMPLETED)){
            throw new EventNotFinishedException("Voce só pode avaliar um evento que acabou");
        }
        if(evaluationRepository.existsByRegistrationId((registration.getId()))){
            throw new BadRequestException("Voce já avaliou este evento");
        }

        Evaluation evaluation = new Evaluation();
        evaluation.setCreatedAt(LocalDateTime.now());
        evaluation.setRegistration(registration);
        evaluation.setComment(dto.comment());
        evaluation.setRating(dto.rating());
        var saved = evaluationRepository.save(evaluation);

        log.info("Avaliação {} criada pelo usuário {} para o evento {}",
                saved.getId(), authenticatedUser.getUsername(), dto.eventId());
        return mapper.toDTO(saved);

    }
    public List<EvaluationResponseDTO> getEventEvaluations(UUID eventId){
        var relatedEvent = eventRepository.findById(eventId)
                .orElseThrow(()-> new EventNotFoundException("Evento nao encontrado"));

        return  evaluationRepository.findAllByRegistrationEvent(relatedEvent)
                .stream()
                .map(mapper::toDTO)
                .toList();

    }
}
