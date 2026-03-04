package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.EventResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.OrganizerRequestDTO;
import br.com.geac.backend.Aplication.Services.OrganizerService;
import br.com.geac.backend.Domain.Entities.Organizer;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/organizers")
@RequiredArgsConstructor
public class OrganizerController {

    private final OrganizerService organizerService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<OrganizerResponseDTO> createOrganizer(@RequestBody @Valid OrganizerRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(organizerService.createOrganizer(dto));
    }

    @GetMapping
    public ResponseEntity<List<OrganizerResponseDTO>> getAllOrganizers() {
        return ResponseEntity.ok(organizerService.getAllOrganizers());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrganizerResponseDTO> getOrganizerById(@PathVariable UUID id) {
        return ResponseEntity.ok(organizerService.getOrganizerById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrganizerResponseDTO> updateOrganizer(@PathVariable UUID id, @RequestBody @Valid OrganizerRequestDTO dto) {
        return ResponseEntity.ok(organizerService.updateOrganizer(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOrganizer(@PathVariable UUID id) {
        organizerService.deleteOrganizer(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/user/{id}")
    public ResponseEntity<List<OrganizerResponseDTO>> getUserOrganizers(@PathVariable UUID id) {
        return ResponseEntity.ok(organizerService.getAllUserOrganizer(id));
    }

}