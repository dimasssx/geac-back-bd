package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.RequirementsResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.RequirementRequestDTO;
import br.com.geac.backend.Aplication.Services.RequirementService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/requirements")
@RequiredArgsConstructor
public class RequirementController {

    private final RequirementService service;


    @PostMapping()
    public ResponseEntity<RequirementsResponseDTO> createRequirement(@Valid @RequestBody RequirementRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createRequirement(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RequirementsResponseDTO> getById(@PathVariable @Positive Integer id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @GetMapping
    public ResponseEntity<List<RequirementsResponseDTO>> getAll() {
        return ResponseEntity.ok(service.getAll());
    }

    @PatchMapping("/{id}")
    public ResponseEntity<RequirementsResponseDTO> updateRequirement(@RequestBody RequirementRequestDTO dto, @PathVariable @Positive Integer id) {
        return ResponseEntity.ok(service.updateRequirement(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable @Positive Integer id) {
        service.deleteRequirement(id);
        return ResponseEntity.noContent().build();
    }
}