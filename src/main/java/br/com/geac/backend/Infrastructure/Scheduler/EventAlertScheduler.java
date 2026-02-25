package br.com.geac.backend.Infrastructure.Scheduler;

import br.com.geac.backend.Aplication.Services.EventService;
import br.com.geac.backend.Aplication.Services.NotificationService;
import br.com.geac.backend.Aplication.Services.RegistrationService;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Entities.User;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Component
@RequiredArgsConstructor
public class EventAlertScheduler {

    private final EventService eventService;
    private final RegistrationService registrationService;
    private final NotificationService notificationService;

    @Scheduled(cron = "0 */1 * * * *") //TODO: mudar pra 1h quando estiver pronto, de 1 em 1 pra testar
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
            registrationsByEvent.forEach(registration ->  registration.setNotified(true));
            registrationService.saveAll(registrationsByEvent);


        }
    }
}
