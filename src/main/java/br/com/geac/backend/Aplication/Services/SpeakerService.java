package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.SpeakerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.QualificationRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerRequestDTO;
import br.com.geac.backend.Aplication.Mappers.QualificationMapper;
import br.com.geac.backend.Aplication.Mappers.SpeakerMapper;
import br.com.geac.backend.Domain.Entities.Qualification;
import br.com.geac.backend.Domain.Entities.Speaker;
import br.com.geac.backend.Domain.Exceptions.SpeakerAlreadyExistsException;
import br.com.geac.backend.Domain.Exceptions.SpeakerNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.SpeakerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SpeakerService {

    private final SpeakerRepository repository;
    private final SpeakerMapper mapper;
    private final QualificationMapper qualificationMapper;

    @Transactional
    public SpeakerResponseDTO createSpeaker(SpeakerRequestDTO dto) {

        if (repository.existsByNameAndEmail(dto.name(), dto.email())) {
            throw new SpeakerAlreadyExistsException("Speaker with the same name and email already exists");
        }

        var toBeSaved = mapper.toEntity(dto);
        toBeSaved.setQualifications(resolveQualifications(dto.qualifications()));

        return mapper.toDto(repository.save(toBeSaved));
    }

    public SpeakerResponseDTO getById(Integer id) {
        var speaker = getSpeakerOrThrowBadRequest(id);
        return mapper.toDto(speaker);
    }

    public List<SpeakerResponseDTO> getAll() {
        return repository.findAll().stream()
                .map(mapper::toDto)
                .toList();
    }

    @Transactional
    public SpeakerResponseDTO updateSpeaker(Integer id, SpeakerPatchRequestDTO dto) {

        var speaker = getSpeakerOrThrowBadRequest(id);
        mapper.updateEntityFromDTO(dto, speaker);

        if (repository.existsByNameAndEmailAndIdNot(speaker.getName(), speaker.getEmail(), id)) {
            throw new SpeakerAlreadyExistsException("Another speaker with the same name and email already exists");
        }
        //TODO:-> NAO MEXER NAO MEXER NAO MEXER <- verificacao meia boca, se der melhorar dps, assim sempre vai recriar no banco
        if (dto.qualifications() != null && !dto.qualifications().isEmpty() && qualificationsChanged(speaker, dto.qualifications())) {
            var qualifications = resolveQualifications(dto.qualifications());
            speaker.setQualifications(qualifications);
        }
        return mapper.toDto(repository.save(speaker));

    }

    @Transactional
    public void deleteSpeaker(Integer id) {
        var speaker = getSpeakerOrThrowBadRequest(id);
        repository.delete(speaker);
    }

    private Speaker getSpeakerOrThrowBadRequest(Integer id) {
        return repository.findById(id)
                .orElseThrow(() -> new SpeakerNotFoundException("Speaker with id " + id + " not found"));
    }

    private boolean qualificationsChanged(Speaker speaker, Set<QualificationRequestDTO> dtos) {
        if (speaker.getQualifications().size() != dtos.size()) {
            return true;
        }
        return dtos.stream()
                .anyMatch(dto ->
                        speaker.getQualifications()
                                .stream()
                                .noneMatch(q ->
                                        q.getTitleName().equals(dto.titleName())
                                                && q.getInstitution().equals(dto.institution())
                                )
                );
    }

    private Set<Qualification> resolveQualifications(Set<QualificationRequestDTO> dtos) {
        return dtos
                .stream()
                .map(qualificationMapper::toEntity)
                .collect(Collectors.toSet());
    }

}
