package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.SpeakerResponseDTO;
import br.com.geac.backend.Aplication.Mappers.SpeakerMapper;
import br.com.geac.backend.Repositories.SpeakerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/speakers")
@RequiredArgsConstructor
public class SpeakerController {
    private final SpeakerRepository repository;
    private final SpeakerMapper mapper;

    @GetMapping
    public ResponseEntity<List<SpeakerResponseDTO>> getAll() {
        List<SpeakerResponseDTO> list = repository.findAll().stream()
                .map(mapper::toDto)
                .toList();
        return ResponseEntity.ok(list);
    }

}
