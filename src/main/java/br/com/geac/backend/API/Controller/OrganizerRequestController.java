package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Reponse.PendingRequestResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.CreateOrganizerRequestDTO;
import br.com.geac.backend.Aplication.Services.OrganizerRequestService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/organizer-requests")
@RequiredArgsConstructor
public class OrganizerRequestController {

    private final OrganizerRequestService service;

    //ver as requests pendentes
    @GetMapping("/pending")
    public ResponseEntity<List<PendingRequestResponseDTO>> getPendingRequests() {
        return ResponseEntity.ok(service.getPendingRequests());
    }

    @PostMapping("/{requestId}/approve")
    public ResponseEntity<Void> approveRequest(@PathVariable Integer requestId) {
        service.approveRequest(requestId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{requestId}/reject")
    public ResponseEntity<Void> rejectRequest(@PathVariable Integer requestId) {
        service.rejectRequest(requestId);
        return ResponseEntity.ok().build();
    }

    //para o usuário fazer a solicitação
    @PostMapping
    public ResponseEntity<Void> createRequest(@RequestBody @Valid CreateOrganizerRequestDTO dto) {
        service.createRequest(dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}