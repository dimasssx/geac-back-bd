package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.CertificateResponseDTO;
import br.com.geac.backend.Domain.Entities.Certificate;
import br.com.geac.backend.Domain.Entities.Registration;
import br.com.geac.backend.Domain.Exceptions.CertificateNotAvailableException;
import br.com.geac.backend.Domain.Exceptions.CertificateProcessingException;
import br.com.geac.backend.Infrastructure.Repositories.CertificateRepository;
import br.com.geac.backend.Infrastructure.Repositories.RegistrationRepository;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CertificateService {

    private final CertificateRepository certificateRepository;
    private final RegistrationRepository registrationRepository;

    @Transactional
    public void issueCertificatesForEvent(UUID eventId) {
        List<Registration> attendees = registrationRepository.findByEventId(eventId).stream()
                .filter(Registration::getAttended)
                .collect(Collectors.toList());

        for (Registration reg : attendees) {
            if (!certificateRepository.existsByUserIdAndEventId(reg.getUser().getId(), eventId)) {
                Certificate certificate = new Certificate();
                certificate.setUser(reg.getUser());
                certificate.setEvent(reg.getEvent());
                certificate.setIssuedAt(LocalDateTime.now());

                String uniqueCode = "GEAC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
                certificate.setValidationCode(uniqueCode);

                certificateRepository.save(certificate);
            }
        }
    }

    public List<CertificateResponseDTO> getUserAvailableCertificates(UUID userId) {
        return certificateRepository.findByUserId(userId).stream()
                .map(cert -> CertificateResponseDTO.builder()
                        .certificateId(cert.getId())
                        .eventId(cert.getEvent().getId())
                        .eventTitle(cert.getEvent().getTitle())
                        .workloadHours(cert.getEvent().getWorkloadHours())
                        .issuedAt(cert.getIssuedAt())
                        .validationCode(cert.getValidationCode())
                        .build()
                ).collect(Collectors.toList());
    }

    public byte[] downloadCertificatePdf(UUID userId, UUID eventId) {
        Certificate certificate = certificateRepository.findByUserIdAndEventId(userId, eventId)
                .orElseThrow(() -> new CertificateNotAvailableException("Certificado não encontrado."));

        try (InputStream templateStream = new ClassPathResource("templates/certificado_modelo.pdf").getInputStream();
             PDDocument pdfDocument = PDDocument.load(templateStream)) {

            PDAcroForm acroForm = pdfDocument.getDocumentCatalog().getAcroForm();

            if (acroForm != null) {
                acroForm.getField("nome_aluno").setValue(certificate.getUser().getName());
                acroForm.getField("nome_evento").setValue(certificate.getEvent().getTitle());
                acroForm.getField("carga_horaria").setValue(certificate.getEvent().getWorkloadHours().toString());
                acroForm.flatten();
            }

            try (PDPageContentStream contentStream = new PDPageContentStream(
                    pdfDocument, pdfDocument.getPage(0), PDPageContentStream.AppendMode.APPEND, true, true)) {
                contentStream.beginText();
                contentStream.setFont(PDType1Font.HELVETICA_BOLD, 10);
                contentStream.newLineAtOffset(50, 50);
                contentStream.showText("Código de Validação: " + certificate.getValidationCode());
                contentStream.endText();
            }

            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            pdfDocument.save(outputStream);
            return outputStream.toByteArray();

        } catch (IOException e) {
            throw new CertificateProcessingException("Erro ao gerar o PDF.", e);
        }
    }
}