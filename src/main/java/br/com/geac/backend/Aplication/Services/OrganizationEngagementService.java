package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizationEngagementResponseDTO;
import br.com.geac.backend.Aplication.Mappers.OrganizationEngagementMapper;
import br.com.geac.backend.Infrastructure.Repositories.OrganizationEngagementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class OrganizationEngagementService {

    private final OrganizationEngagementRepository repository;
    private final OrganizationEngagementMapper mapper;

    public List<OrganizationEngagementResponseDTO> getAllOrganizationEngagement() {
        return repository.findAll()
                .stream()
                .map(mapper::toResponseDTO)
                .toList();
    }
}
