package br.com.geac.backend.Infrastructure.Scheduler;

import br.com.geac.backend.Aplication.Services.EventService;
import br.com.geac.backend.Aplication.Services.NotificationService;
import br.com.geac.backend.Aplication.Services.RegistrationService;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Enums.EventStatus;
import br.com.geac.backend.Infrastructure.Repositories.EventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Log4j2
public class EventAlertScheduler {

    private final EventService eventService;
    private final EventRepository eventRepository;
    private final RegistrationService registrationService;
    private final NotificationService notificationService;

    @Scheduled(cron = "0 0 * * * *")
    public void checkCloseEvents() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime eventTimeCheck = now.plusHours(24);

        List<Event> closeEvents = eventService.getEventsBetween(now, eventTimeCheck);

        for (Event event : closeEvents) {

            var registrationsByEvent = registrationService.getUnotifiedRegistrationsById(event.getId());
            if (registrationsByEvent.isEmpty()) {
                continue;
            }
            List<User> users = registrationsByEvent.stream()
                    .map(Registration::getUser)
                    .toList();

            notificationService.notifyAll(users, event);
            registrationsByEvent.forEach(registration -> registration.setNotified(true));
            registrationService.saveAll(registrationsByEvent);


        }


    }

    @Scheduled(cron = "0 */30 * * * *")
    public void updateEventStatus() {  //dava pra fazer direto nno banco mas deixa ai, n vai pesar acho

        LocalDateTime now = LocalDateTime.now();
        List<Event> endEvents = eventService.getPastEvents(now);

        //todo:verificar finalizado ou inprogress
        if(!endEvents.isEmpty()) {
            endEvents.forEach(event -> event.setStatus(EventStatus.COMPLETED));
            eventRepository.saveAll(endEvents);
            log.info("Updated {} to completed status",endEvents.size());
        }else {
            log.info("No events found to update");
        }
    }

}
