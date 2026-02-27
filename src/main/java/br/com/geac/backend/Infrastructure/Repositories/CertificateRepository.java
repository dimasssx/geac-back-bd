package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.Certificate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CertificateRepository extends JpaRepository<Certificate, UUID> {
    List<Certificate> findByUserId(UUID userId);
    Optional<Certificate> findByUserIdAndEventId(UUID userId, UUID eventId);
    boolean existsByUserIdAndEventId(UUID userId, UUID eventId);
}