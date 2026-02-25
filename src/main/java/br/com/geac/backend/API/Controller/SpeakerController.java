package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.SpeakerResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.SpeakerRequestDTO;
import br.com.geac.backend.Aplication.Services.SpeakerService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/speakers")
@RequiredArgsConstructor
public class SpeakerController {
    private final SpeakerService service;

    @PostMapping()
    public ResponseEntity<SpeakerResponseDTO> createSpeaker(@Valid @RequestBody SpeakerRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createSpeaker(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<SpeakerResponseDTO> getById(@PathVariable @Positive Integer id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @GetMapping
    public ResponseEntity<List<SpeakerResponseDTO>> getAll() {

        return ResponseEntity.ok(service.getAll());
    }

    @PatchMapping("/{id}")
    public ResponseEntity<SpeakerResponseDTO> updateSpeaker(@PathVariable @Positive Integer id,
                                                            @RequestBody @Valid SpeakerPatchRequestDTO dto) {
        return ResponseEntity.ok(service.updateSpeaker(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable @Positive Integer id) {
        service.deleteSpeaker(id);
        return ResponseEntity.noContent().build();
    }
}
