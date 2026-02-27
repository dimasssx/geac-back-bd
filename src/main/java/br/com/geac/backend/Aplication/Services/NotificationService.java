package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.NotificationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.RegistrationResponseDTO;
import br.com.geac.backend.Aplication.Mappers.NotificationMapper;
import br.com.geac.backend.Domain.Entities.Event;
import br.com.geac.backend.Domain.Entities.Notification;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Infrastructure.Repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Log4j2
public class NotificationService {

    private final EmailService emailService;
    private final NotificationRepository notificationRepository;
    private final NotificationMapper notificationMapper;

    public void notifyAll(List<User> users, Event event) {
        for (User user : users) {
            var notification = new Notification();
            notification.setEvent(event);
            notification.setCreatedAt(LocalDateTime.now());
            notification.setUser(user);
            notification.setType("REMINDER");
            notification.setMessage("Seu evento começará em 24 horas");
            notification.setTitle(event.getTitle());
            notification.setRead(false);
            notificationRepository.save(notification);
            emailService.sendAlert(user.getEmail(), event);

        }
    }

    public void notify(Notification notification) {
            notificationRepository.save(notification);
    }

    public List<NotificationResponseDTO> getUnreadNotifications() {
        return getUserNotifications().stream()
                .map(notificationMapper::toDTO)
                .toList();
    }

    public Integer getUnreadCount() {
        return getUserNotifications().size();
    }

    @Transactional
    public void markAsRead(Long id) {
        var notification = notificationRepository.findById(id).orElseThrow(() -> new ConflictException("meudeusainda é conflito alguem me ajuda"));
        var user = getAuthenticatedUser();
        if (!notification.getUser().getId().equals(user.getId())) {
            throw new ConflictException("Você não tem permissão para marcar esta notificação");
        }
        notification.setRead(true);
        notificationRepository.save(notification);
    }

    public void markAllAsRead() {
        List<Notification> notifications = getUserNotifications();
        notifications.forEach(notification -> notification.setRead(true));
        notificationRepository.saveAll(notifications);
    }
    private List<Notification> getUserNotifications() {
        var user = getAuthenticatedUser();
        return notificationRepository.findByUserIdAndIsRead(user.getId(), false);
    }
    private static User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }


}
