package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Getter;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.Subselect;

import java.util.UUID;

@Entity
@Getter
@Immutable
@Subselect("SELECT * FROM vw_horas_extracurriculares_aluno")
public class StudentExtracurricularHours {

    @Id
    @Column(name = "student_id")
    private UUID studentId;

    @Column(name = "student_name")
    private String studentName;

    @Column(name = "student_email")
    private String studentEmail;

    @Column(name = "total_certificados_emitidos")
    private Long totalCertificadosEmitidos;

    @Column(name = "total_horas_acumuladas")
    private Long totalHorasAcumuladas;
}