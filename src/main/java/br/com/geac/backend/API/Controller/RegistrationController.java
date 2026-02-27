package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.RegistrationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.PresenceRequestDTO;
import br.com.geac.backend.Aplication.Services.RegistrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/registrations")
@RequiredArgsConstructor
public class RegistrationController {

    private final RegistrationService registrationService;

    @PutMapping("/{eventId}/attendance/bulk")
    @PreAuthorize("hasAnyRole('PROFESSOR', 'ORGANIZER', 'ADMIN')")
    public ResponseEntity<Void> markAttendanceInBulk(
            @PathVariable UUID eventId,
            @RequestBody @Valid PresenceRequestDTO request) {

        registrationService.markAttendanceInBulk(eventId, request.userIds(), request.attended());

        return ResponseEntity.noContent().build();
    }

    @GetMapping("/event/{eventId}")
    @PreAuthorize("hasAnyRole('PROFESSOR', 'ORGANIZER', 'ADMIN')")
    public ResponseEntity<List<RegistrationResponseDTO>> getRegistrationsByEvent(@PathVariable UUID eventId) {

        List<RegistrationResponseDTO> list = registrationService.getRegistrationsByEvent(eventId);
        return ResponseEntity.ok(list);
    }

    @PostMapping("/{eventId}/register")
    public ResponseEntity<Void> registerToEvent(@PathVariable UUID eventId) {

        registrationService.registerToEvent(eventId);

        return ResponseEntity.status(201).build();
    }

    @DeleteMapping("/{eventId}/cancel")
    // Qualquer usuário autenticado pode acessar, pois vai cancelar a própria inscrição
    public ResponseEntity<Void> cancelRegistration(@PathVariable UUID eventId) {

        registrationService.cancelRegistration(eventId);

        return ResponseEntity.noContent().build(); // Retorna 204 No Content
    }

}