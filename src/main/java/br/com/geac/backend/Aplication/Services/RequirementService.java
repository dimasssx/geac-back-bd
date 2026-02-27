package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.RequirementsResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.RequirementRequestDTO;
import br.com.geac.backend.Aplication.Mappers.RequirementMapper;
import br.com.geac.backend.Domain.Entities.EventRequirement;
import br.com.geac.backend.Domain.Exceptions.RequirementNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.EventRequirementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RequirementService {

    private final EventRequirementRepository repository;
    private final RequirementMapper mapper;

    @Transactional
    public RequirementsResponseDTO createRequirement(RequirementRequestDTO dto) {

        var toBeSaved = mapper.toEntity(dto);
        return mapper.toDTO(repository.save(toBeSaved));
    }

    public RequirementsResponseDTO getById(Integer id) {
        var requirement = getRequirementByIdOrThrowBadRequest(id);
        return mapper.toDTO(requirement);
    }

    public List<RequirementsResponseDTO> getAll() {
        return repository.findAll().stream()
                .map(mapper::toDTO)
                .toList();
    }

    @Transactional
    public RequirementsResponseDTO updateRequirement(Integer id, RequirementRequestDTO dto) {
        var requirement = getRequirementByIdOrThrowBadRequest(id);
        if (dto.description() != null) requirement.setDescription(dto.description());
        return mapper.toDTO(requirement);
    }

    @Transactional
    public void deleteRequirement(Integer id) {
        var requirement = getRequirementByIdOrThrowBadRequest(id);
        repository.delete(requirement);
    }

    private EventRequirement getRequirementByIdOrThrowBadRequest(Integer id) {
        return repository.findById(id)
                .orElseThrow(() -> new RequirementNotFoundException("Requirement not found"));
    }
}
