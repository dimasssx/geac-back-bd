package br.com.geac.backend.Aplication.DTOs.Request;

import java.util.UUID;

public record StudentHoursResponseDTO(
        UUID studentId,
        String studentName,
        String studentEmail,
        Long totalCertificadosEmitidos,
        Long totalHorasAcumuladas
) {
}
