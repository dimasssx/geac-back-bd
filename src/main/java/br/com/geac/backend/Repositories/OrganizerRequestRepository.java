package br.com.geac.backend.Repositories;

import br.com.geac.backend.Domain.Entities.OrganizerRequest;
import br.com.geac.backend.Domain.Enums.RequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrganizerRequestRepository extends JpaRepository<OrganizerRequest, Integer> {
    List<OrganizerRequest> findAllByStatus(RequestStatus status);
    boolean existsByUserIdAndOrganizerIdAndStatus(UUID userId, Integer organizerId, RequestStatus status);
}