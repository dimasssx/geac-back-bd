package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Request.CategoryPatchRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CategoryRequestDTO;
import br.com.geac.backend.Aplication.DTOs.Reponse.CategoryResponseDTO;
import br.com.geac.backend.Aplication.Services.CategoryService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService service;

    @PostMapping()
    public ResponseEntity<CategoryResponseDTO> createCategory(@Valid @RequestBody CategoryRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createCategory(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponseDTO> getById(@PathVariable @Positive Integer id ) {
        return ResponseEntity.ok(service.getCategoryById(id));
    }
    @GetMapping
    public ResponseEntity<List<CategoryResponseDTO>> getAll() {
        return ResponseEntity.ok(service.getAllCategory());
    }

    @PatchMapping("{id}")
    public ResponseEntity<CategoryResponseDTO> updateCategory(@Valid @RequestBody CategoryPatchRequestDTO dto, @PathVariable Integer id) {
        return ResponseEntity.ok(service.updateCategory(id, dto));
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        service.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}