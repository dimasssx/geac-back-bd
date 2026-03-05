package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizationEngagementResponseDTO;
import br.com.geac.backend.Aplication.Mappers.OrganizationEngagementMapper;
import br.com.geac.backend.Infrastructure.Repositories.OrganizationEngagementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrganizationEngagementService {

    private final OrganizationEngagementRepository repository;
    private final OrganizationEngagementMapper mapper;

    public List<OrganizationEngagementResponseDTO> getAllOrganizationEngagement() {
        return repository.findTopOrganizations()
                .stream()
                .map(row -> new OrganizationEngagementResponseDTO(
                        ((UUID) row[0]),
                        (String) row[1],
                        ((Number) row[2]).longValue(),
                        ((Number) row[3]).longValue()
                ))
                .toList();
    }
}
