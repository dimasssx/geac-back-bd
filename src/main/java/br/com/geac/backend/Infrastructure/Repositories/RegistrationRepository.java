package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.Registration;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RegistrationRepository extends JpaRepository<Registration, UUID> {

    Optional<Registration> findByUserIdAndEventId(UUID userId, UUID eventId);

    boolean existsByUserIdAndEventId(UUID userId, UUID eventId);

    long countByEventId(UUID eventId);

    List<Registration> findByEventId(UUID eventId);

    // Faz o UPDATE apenas nos usuários que vieram na lista, dentro do evento específico
    @Modifying
    @Query("UPDATE Registration r SET r.attended = :attended WHERE r.event.id = :eventId AND r.user.id IN :userIds")
    void updateAttendanceInBulk(
            @Param("eventId") UUID eventId,
            @Param("userIds") List<UUID> userIds,
            @Param("attended") boolean attended
    );

    List<Registration> findByEventIdAndNotifiedIsFalse(UUID eventId, boolean notified);

    List<Registration> findByEventIdAndNotified(UUID eventId, boolean notified);
}