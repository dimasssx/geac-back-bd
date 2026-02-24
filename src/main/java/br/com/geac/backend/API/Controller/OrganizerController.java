package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.OrganizerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.OrganizerRequestDTO;
import br.com.geac.backend.Aplication.Services.OrganizerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/organizers")
@RequiredArgsConstructor
public class OrganizerController {

    private final OrganizerService organizerService;

    @PostMapping
    // TODO: adicionar @PreAuthorize("hasRole('ADMIN')") conforme requisito
    public ResponseEntity<OrganizerResponseDTO> createOrganizer(@RequestBody @Valid OrganizerRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(organizerService.createOrganizer(dto));
    }

    @GetMapping
    public ResponseEntity<List<OrganizerResponseDTO>> getAllOrganizers() {
        return ResponseEntity.ok(organizerService.getAllOrganizers());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrganizerResponseDTO> getOrganizerById(@PathVariable Integer id) {
        return ResponseEntity.ok(organizerService.getOrganizerById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrganizerResponseDTO> updateOrganizer(@PathVariable Integer id, @RequestBody @Valid OrganizerRequestDTO dto) {
        return ResponseEntity.ok(organizerService.updateOrganizer(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOrganizer(@PathVariable Integer id) {
        organizerService.deleteOrganizer(id);
        return ResponseEntity.noContent().build();
    }
}