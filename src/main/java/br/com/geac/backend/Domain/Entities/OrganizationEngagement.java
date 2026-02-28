package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import org.hibernate.annotations.Immutable;

import java.util.UUID;

@Entity
@Table(name = "vw_engajamento_organizacoes")
@Immutable
@Getter
public class OrganizationEngagement {

    @Id
    @Column(name = "organizer_id")
    private UUID organizerId;

    @Column(name = "organizer_name")
    private String organizerName;

    @Column(name = "total_eventos_realizados")
    private Long totalEventosRealizados;

    @Column(name = "total_participantes_engajados")
    private Long totalParticipantesEngajados;
}
