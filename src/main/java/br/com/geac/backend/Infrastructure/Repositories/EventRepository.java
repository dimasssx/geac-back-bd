package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Enums.EventStatus;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface EventRepository extends JpaRepository<Event, UUID> {
    List<Event> findAllByStartTimeBetween(LocalDateTime startTimeAfter, LocalDateTime startTimeBefore);
    boolean existsByTitleIgnoreCaseAndOrganizerIdAndStartTime(String title, UUID organizerId, LocalDateTime startTime);

    @Query("SELECT e, (SELECT COUNT(r) FROM Registration r WHERE r.event.id = e.id) as inscritos FROM Event e")
    List<Object[]> findAllWithRegistrationCount();

    List<Event> findAllByStartTimeBeforeAndStatusNot(LocalDateTime startTimeBefore, EventStatus status);

    List<Event> findAllByStartTimeBetweenAndDaysBeforeNotify(LocalDateTime startTimeAfter, LocalDateTime startTimeBefore, Integer daysBeforeNotify);

    List<Event> findAllByStartTimeBetweenAndStatusNot(LocalDateTime startTimeAfter, LocalDateTime startTimeBefore, EventStatus status);

    List<Event> findAllByOrganizerId(UUID organizerId);

    List<Event> findAllByOrganizerIdIn(Collection<UUID> organizerIds);

    List<Event> findAllByEndTimeBeforeAndStatusNot(LocalDateTime endTimeBefore, EventStatus status);

    @Modifying
    @Transactional
    @Query("UPDATE Event e SET e.status = :status " +
            "WHERE e.endTime < :time AND e.status != :status")
    int markPastEventsAsCompleted(@Param("time") LocalDateTime time, @Param("status") EventStatus status);

    @Modifying
    @Transactional
    @Query("UPDATE Event e SET e.status = :newStatus " +
            "WHERE e.startTime <= :now AND e.endTime > :now " +
            "AND e.status != :newStatus")
    int updateEventsToInProgress(@Param("now") LocalDateTime now, @Param("newStatus") EventStatus newStatus);
    @Modifying
    @Transactional
    @Query("UPDATE Event e SET e.status = :newStatus " +
            "WHERE e.startTime <= :oneWeekFromNow " +
            "AND e.startTime > :now " +
            "AND e.status = :oldStatus")
    int updateToUpcoming(@Param("now") LocalDateTime now,
                         @Param("oneWeekFromNow") LocalDateTime oneWeekFromNow,
                         @Param("oldStatus") EventStatus oldStatus,
                         @Param("newStatus") EventStatus newStatus);
}
