package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.LocationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.TagResponseDTO;
import br.com.geac.backend.Repositories.LocationRepository;
import br.com.geac.backend.Repositories.TagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;


@RestController
@RequestMapping("/tags")
@RequiredArgsConstructor
public class TagController {
    private final TagRepository repository;

    @GetMapping
    public ResponseEntity<List<TagResponseDTO>> getAll() {
        List<TagResponseDTO> list = repository.findAll().stream()
                .map(tag -> new TagResponseDTO(tag.getId(), tag.getName()))
                .toList();
        return ResponseEntity.ok(list);
    }
}