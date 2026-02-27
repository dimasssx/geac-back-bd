package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.OrganizerRequestDTO;
import br.com.geac.backend.Aplication.Mappers.OrganizerMapper;
import br.com.geac.backend.Domain.Entities.Organizer;
import br.com.geac.backend.Domain.Entities.OrganizerMember;
import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Domain.Exceptions.OrganizerAlreadyExists;
import br.com.geac.backend.Domain.Exceptions.OrganizerNotFoundExceptio;
import br.com.geac.backend.Infrastructure.Repositories.OrganizerMemberRepository;
import br.com.geac.backend.Infrastructure.Repositories.OrganizerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrganizerService {

    private final OrganizerRepository organizerRepository;
    private final OrganizerMapper organizerMapper;
    private final OrganizerMemberRepository organizerMemberRepository;

    @Transactional
    public OrganizerResponseDTO createOrganizer(OrganizerRequestDTO dto) {
        if (organizerRepository.existsByName(dto.name())) {
            throw new OrganizerAlreadyExists("Já existe uma organização cadastrada com este nome.");
        }

        Organizer organizer = organizerMapper.toEntity(dto);
        Organizer saved = organizerRepository.save(organizer);
        return organizerMapper.toResponseDTO(saved);
    }

    @Transactional(readOnly = true)
    public List<OrganizerResponseDTO> getAllOrganizers() {
        return organizerRepository.findAll().stream()
                .map(organizerMapper::toResponseDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public OrganizerResponseDTO getOrganizerById(UUID id) {
        Organizer organizer = findByIdOrThrow(id);
        return organizerMapper.toResponseDTO(organizer);
    }

    @Transactional
    public OrganizerResponseDTO updateOrganizer(UUID id, OrganizerRequestDTO dto) {
        Organizer organizer = findByIdOrThrow(id);

        if (!organizer.getName().equalsIgnoreCase(dto.name()) && organizerRepository.existsByName(dto.name())) {
            throw new OrganizerAlreadyExists("Já existe outra organização cadastrada com este nome.");
        }

        organizer.setName(dto.name());
        organizer.setContactEmail(dto.contactEmail());

        return organizerMapper.toResponseDTO(organizerRepository.save(organizer));
    }

    @Transactional
    public void deleteOrganizer(UUID id) {
        Organizer organizer = findByIdOrThrow(id);
        organizerRepository.delete(organizer);
    }

    private Organizer findByIdOrThrow(UUID id) {
        return organizerRepository.findById(id)
                .orElseThrow(() -> new OrganizerNotFoundExceptio("Organização não encontrada com o ID: " + id)); // Posteriormente podemos criar uma EntityNotFoundException global
    }

    public List<OrganizerResponseDTO> getAllUserOrganizer(UUID uuid) {
           var userOrgsIds= organizerMemberRepository.getAllByUserId(uuid)
                   .stream()
                   .map(organizerMember ->
                                   organizerMember.getOrganizer().getId()
                           )
                   .toList();
           return organizerRepository.findAllByIdIn(userOrgsIds)
                   .stream()
                   .map(organizerMapper::toResponseDTO)
                   .toList();
    }
}