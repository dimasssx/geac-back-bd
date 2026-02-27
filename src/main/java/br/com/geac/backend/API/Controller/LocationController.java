package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.LocationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.LocationPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.LocationRequestDTO;
import br.com.geac.backend.Aplication.Services.LocationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/locations")
@RequiredArgsConstructor

public class LocationController {
    private final LocationService service;


    @PostMapping()
    public ResponseEntity<LocationResponseDTO> createLocation(@RequestBody @Valid LocationRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createLocation(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<LocationResponseDTO> getById(@PathVariable @Positive Integer id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @GetMapping
    public ResponseEntity<List<LocationResponseDTO>> getAll() {
        return ResponseEntity.ok(service.getAll());
    }

    @PatchMapping("/{id}")
     @PreAuthorize("hasRole('ORGANIZER') or hasRole('ADMIN')")
    public ResponseEntity<LocationResponseDTO> updateLocation(@PathVariable @Positive Integer id, @RequestBody @Valid LocationPatchRequestDTO dto) {
        return ResponseEntity.ok(service.updateLocation(id, dto));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable @Positive Integer id) {
        service.deleteLocation(id);
        return ResponseEntity.noContent().build();
    }
}