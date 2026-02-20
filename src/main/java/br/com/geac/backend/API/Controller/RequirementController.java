package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.RequirementsResponseDTO;
import br.com.geac.backend.Repositories.EventRequirementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/requirements")
@RequiredArgsConstructor
public class RequirementController {
    private final EventRequirementRepository repository;

    @GetMapping
    public ResponseEntity<List<RequirementsResponseDTO>> getAll() {
        List<RequirementsResponseDTO> list = repository.findAll().stream()
                .map(r -> new RequirementsResponseDTO(r.getId(), r.getDescription()))
                .toList();
        return ResponseEntity.ok(list);
    }
}