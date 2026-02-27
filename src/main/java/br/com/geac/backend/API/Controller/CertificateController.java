package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.CertificateResponseDTO;
import br.com.geac.backend.Aplication.Services.CertificateService;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Exceptions.CertificateNotAvailableException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/certificate")
@RequiredArgsConstructor
public class CertificateController {

    private final CertificateService certificateService;

    @GetMapping("/me")
    public ResponseEntity<List<CertificateResponseDTO>> getMyCertificates(Authentication authentication) {
        UUID userId = extractUserIdFromAuth(authentication);
        return ResponseEntity.ok(certificateService.getUserAvailableCertificates(userId));
    }

    @GetMapping(value = "/download/{eventId}", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> downloadCertificate(
            @PathVariable UUID eventId,
            Authentication authentication) {

        UUID userId = extractUserIdFromAuth(authentication);
        byte[] pdfBytes = certificateService.downloadCertificatePdf(userId, eventId);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"certificado_" + eventId + ".pdf\"")
                .body(pdfBytes);
    }

    private UUID extractUserIdFromAuth(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof User) {
            User principal = (User) authentication.getPrincipal();
            return principal.getId();
        }
        throw new CertificateNotAvailableException("Acesso negado: Usuário não identificado.");
    }
}