package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.EvaluationResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.EvaluationRequestDTO;
import br.com.geac.backend.Aplication.Services.EvaluationService;
import br.com.geac.backend.Domain.Entities.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController()
@RequestMapping("/evaluation")
@RequiredArgsConstructor
public class EvaluationController {
    private final EvaluationService evaluationService;
    @PostMapping
    public ResponseEntity<EvaluationResponseDTO> save(@RequestBody EvaluationRequestDTO evaluation,
                                                      @AuthenticationPrincipal User authenticatedUser){

        return  ResponseEntity.status(HttpStatus.CREATED).body(evaluationService.createEvaluation(evaluation,authenticatedUser));
    }

    @GetMapping("/{id}")
    public ResponseEntity<List<EvaluationResponseDTO>> findAllByEvent(@PathVariable UUID id){
        return ResponseEntity.ok(evaluationService.getEventEvaluations(id));
    }
}
