package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.LocationResponseDTO;
import br.com.geac.backend.Repositories.LocationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/locations")
@RequiredArgsConstructor
public class LocationController {
    private final LocationRepository repository;

    @GetMapping
    public ResponseEntity<List<LocationResponseDTO>> getAll() {
        List<LocationResponseDTO> list = repository.findAll().stream()
                .map(l -> new LocationResponseDTO(l.getId(), l.getName(), l.getStreet(), l.getNumber(), l.getNeighborhood(), l.getCity(), l.getState(), l.getZipCode(), l.getReferencePoint(), l.getCapacity()))
                .toList();
        return ResponseEntity.ok(list);
    }
}