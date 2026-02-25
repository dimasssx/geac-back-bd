package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.OrganizerRequestDTO;
import br.com.geac.backend.Aplication.Mappers.OrganizerMapper;
import br.com.geac.backend.Domain.Entities.Organizer;
import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Infrastructure.Repositories.OrganizerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class OrganizerService {

    private final OrganizerRepository organizerRepository;
    private final OrganizerMapper organizerMapper;

    @Transactional
    public OrganizerResponseDTO createOrganizer(OrganizerRequestDTO dto) {
        if (organizerRepository.existsByName(dto.name())) {
            throw new ConflictException("Já existe uma organização cadastrada com este nome.");
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
    public OrganizerResponseDTO getOrganizerById(Integer id) {
        Organizer organizer = findByIdOrThrow(id);
        return organizerMapper.toResponseDTO(organizer);
    }

    @Transactional
    public OrganizerResponseDTO updateOrganizer(Integer id, OrganizerRequestDTO dto) {
        Organizer organizer = findByIdOrThrow(id);

        if (!organizer.getName().equalsIgnoreCase(dto.name()) && organizerRepository.existsByName(dto.name())) {
            throw new ConflictException("Já existe outra organização cadastrada com este nome.");
        }

        organizer.setName(dto.name());
        organizer.setContactEmail(dto.contactEmail());

        return organizerMapper.toResponseDTO(organizerRepository.save(organizer));
    }

    @Transactional
    public void deleteOrganizer(Integer id) {
        Organizer organizer = findByIdOrThrow(id);
        organizerRepository.delete(organizer);
    }

    private Organizer findByIdOrThrow(Integer id) {
        return organizerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Organização não encontrada com o ID: " + id)); // Posteriormente podemos criar uma EntityNotFoundException global
    }
}