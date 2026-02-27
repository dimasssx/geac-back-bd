package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Enums.EventStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface EventRepository extends JpaRepository<Event, UUID> {
    List<Event> findAllByStartTimeBetween(LocalDateTime startTimeAfter, LocalDateTime startTimeBefore);

    boolean existsByTitleIgnoreCaseAndOrganizerIdAndStartTime(String title, UUID organizerId, LocalDateTime startTime);

    @Query("SELECT e, (SELECT COUNT(r) FROM Registration r WHERE r.event.id = e.id) as inscritos FROM Event e")
    List<Object[]> findAllWithRegistrationCount();

    List<Event> findAllByStartTimeBeforeAndStatusNot(LocalDateTime startTimeBefore, EventStatus status);
}
