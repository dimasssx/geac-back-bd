package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Notification {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @JoinColumn(name = "user_id", nullable = false) @ManyToOne(fetch = FetchType.LAZY)
    private User user;
    @JoinColumn(name = "event_id", nullable = false) @ManyToOne(fetch = FetchType.LAZY)
    private Event event;
    @Column(name = "status")
    private boolean isRead = false;
    private String type;
    private String title;
    @Column(columnDefinition = "TEXT")
    private String message;
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
