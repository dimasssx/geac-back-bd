package br.com.geac.backend.Aplication.DTOs.Reponse;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;
import java.time.LocalDateTime;

@Data
@Builder
public class CertificateResponseDTO {
    private UUID certificateId;
    private UUID eventId;
    private String eventTitle;
    private Integer workloadHours;
    private LocalDateTime issuedAt;
    private String validationCode;
}