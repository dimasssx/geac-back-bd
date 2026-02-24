package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.SpeakerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.QualificationRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerRequestDTO;
import br.com.geac.backend.Aplication.Mappers.QualificationMapper;
import br.com.geac.backend.Aplication.Mappers.SpeakerMapper;
import br.com.geac.backend.Domain.Entities.Qualification;
import br.com.geac.backend.Domain.Entities.Speaker;
import br.com.geac.backend.Repositories.SpeakerRepository;
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
            throw new RuntimeException("Speaker with the same name and email already exists");
        }

        var toBeSaved = mapper.toEntity(dto);
        toBeSaved.setQualifications(resolveQualifications(dto.qualifications()));

        return mapper.toDto(repository.save(toBeSaved));
    }

    public SpeakerResponseDTO getById(Integer id) {
        var speaker = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Speaker with id " + id + " not found"));
        return mapper.toDto(speaker);
    }

    public List<SpeakerResponseDTO> getAll() {
        return repository.findAll().stream()
                .map(mapper::toDto)
                .toList();
    }

    @Transactional
    public SpeakerResponseDTO updateSpeaker(Integer id, SpeakerPatchRequestDTO dto) {

        var speaker = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Speaker with id " + id + " not found"));
        mapper.updateEntityFromDTO(dto, speaker);

        if (repository.existsByNameAndEmailAndIdNot(speaker.getName(), speaker.getEmail(), id)) {
            throw new RuntimeException("Another speaker with the same name and email already exists");
        }

        //TODO: verificacao meia boca, se der melhorar dps
        if (dto.qualifications() != null && !dto.qualifications().isEmpty() && qualificationsChanged(speaker, dto.qualifications())) {
            var qualifications = resolveQualifications(dto.qualifications());
            speaker.setQualifications(qualifications);
        }
        return mapper.toDto(repository.save(speaker));

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

    @Transactional
    public void deleteSpeaker(Integer id) {
        repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Speaker with id " + id + " not found"));
        repository.deleteById(id);
    }

    private Set<Qualification> resolveQualifications(Set<QualificationRequestDTO> dtos) {
        return dtos
                .stream()
                .map(qualificationMapper::toEntity)
                .collect(Collectors.toSet());
    }

}
