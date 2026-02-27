package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Getter
@Setter
@Table(name = "certificates")
public class Certificate {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @Column(name = "validation_code", nullable = false, unique = true, length = 100)
    private String validationCode;

    @Column(name = "issued_at", nullable = false, updatable = false)
    private LocalDateTime issuedAt = LocalDateTime.now();
}