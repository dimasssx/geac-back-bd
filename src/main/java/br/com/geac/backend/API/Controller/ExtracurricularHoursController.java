package br.com.geac.backend.API.Controller;

import br.com.geac.backend.Aplication.DTOs.Request.StudentHoursResponseDTO;
import br.com.geac.backend.Aplication.Services.ExtracurricularHoursService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/extracurricular-hours")
@RequiredArgsConstructor
public class ExtracurricularHoursController {

    private final ExtracurricularHoursService service;

    // Rota para o próprio estudante logado ver suas horas
    @GetMapping("/me")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<StudentHoursResponseDTO> getMyHours() {
        return ResponseEntity.ok(service.getMyHours());
    }

    // Rota para administradores ou professores consultarem as horas de um aluno específico
    @GetMapping("/student/{studentId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'PROFESSOR', 'ORGANIZER')")
    public ResponseEntity<StudentHoursResponseDTO> getStudentHours(@PathVariable UUID studentId) {
        return ResponseEntity.ok(service.getHoursByStudentId(studentId));
    }

    // Rota para administradores visualizarem as horas de todos os alunos (painel admin)
    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<StudentHoursResponseDTO>> getAllStudentHours() {
        return ResponseEntity.ok(service.getAllStudentHours());
    }
}