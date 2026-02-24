package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.TagResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.TagRequestDTO;
import br.com.geac.backend.Aplication.Services.TagService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("/tags")
@RequiredArgsConstructor

public class TagController {

    private final TagService service;

    @PostMapping()
    public ResponseEntity<TagResponseDTO> createTag(@Valid @RequestBody TagRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createTag(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TagResponseDTO> getById(@PathVariable @Positive Integer id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @GetMapping
    public ResponseEntity<List<TagResponseDTO>> getAll() {
        return ResponseEntity.ok(service.getAll());
    }

    @PatchMapping("/{id}") //semanticamente é um put mas ta tudo patch msm, vai que muda
    public ResponseEntity<TagResponseDTO> updateTag(@PathVariable @Positive Integer id,
                                                    @RequestBody @Valid TagRequestDTO dto) {
        return ResponseEntity.ok(service.updateSpeaker(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable @Positive Integer id) {
        service.deleteTag(id);
        return ResponseEntity.noContent().build();
    }
}
