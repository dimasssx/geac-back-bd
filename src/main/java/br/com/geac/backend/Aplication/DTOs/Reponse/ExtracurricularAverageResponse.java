package br.com.geac.backend.Aplication.DTOs.Reponse;

public record ExtracurricularAverageResponse(
        Long totalAlunos,
        Long totalCertificados,
        Double horasTotais,
        Double studentAverage
) {
}
