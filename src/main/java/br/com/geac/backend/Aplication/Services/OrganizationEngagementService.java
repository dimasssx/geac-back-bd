package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizationDashBoard;
import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizationEngagementResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.TopOrgProjection;
import br.com.geac.backend.Aplication.Mappers.OrganizationEngagementMapper;
import br.com.geac.backend.Domain.Exceptions.BadRequestException;
import br.com.geac.backend.Infrastructure.Repositories.OrganizationEngagementRepository;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.Nullable;
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

    public OrganizationDashBoard getOrganizationDashBoard() {
        var dashBoardList = repository.getDashBoard();
        if (dashBoardList == null || dashBoardList.isEmpty()) throw new BadRequestException("ERRO AO PEGAR VIEW");

        var dashboard = dashBoardList.getFirst();

        return new OrganizationDashBoard(
                ((Number) dashboard[0]).longValue(),
                ((Number) dashboard[1]).longValue(),
                ((Number) dashboard[2]).longValue(),
                ((Number) dashboard[3]).doubleValue(),
                ((Number) dashboard[4]).doubleValue(),
                ((Number) dashboard[5]).longValue(),
                ((Number) dashboard[6]).longValue(),
                ((Number) dashboard[7]).longValue(),
                ((Number) dashboard[8]).longValue(),
                ((Number) dashboard[9]).longValue()
        );
    }

    public List<TopOrgProjection> getByTopEvents() {

        return repository.findTop5ByEvents().stream().map(
                org -> new TopOrgProjection(
                        ((UUID) org[0]),
                        ((String) org[1]),
                        ((Number) org[2]).longValue()
                )
        ).toList();
    }

    public  List<TopOrgProjection> getByTopEngagement() {
        return repository.findTop5ByEngagement().stream().map(
                org -> new TopOrgProjection(
                        ((UUID) org[0]),
                        ((String) org[1]),
                        ((Number) org[2]).longValue()
                )
        ).toList();
    }
}
