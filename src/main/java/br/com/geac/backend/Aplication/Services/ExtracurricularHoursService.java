package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.ExtracurricularAverageResponse;
import br.com.geac.backend.Aplication.DTOs.Request.StudentHoursResponseDTO;
import br.com.geac.backend.Aplication.Mappers.StudentHoursMapper;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Exceptions.UserNotFoundException;
import br.com.geac.backend.Infrastructure.Repositories.StudentExtracurricularHoursRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ExtracurricularHoursService {

    private final StudentExtracurricularHoursRepository repository;
    private final StudentHoursMapper mapper;

    // Retorna as horas do usuário logado no momento
    public StudentHoursResponseDTO getMyHours() {
        User loggedUser = (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return getHoursByStudentId(loggedUser.getId());
    }

    // Retorna as horas de um aluno específico pelo ID (útil para admins/professores)
    public StudentHoursResponseDTO getHoursByStudentId(UUID studentId) {
        var hours = repository.findById(studentId)
                .orElseThrow(() -> new UserNotFoundException("Dados de horas não encontrados para o aluno especificado."));
        return mapper.toResponseDTO(hours);
    }

    // Retorna as horas de todos os alunos (para painel administrativo)
    public List<StudentHoursResponseDTO> getAllStudentHours() {
        return repository.findTopStudentsByHours().stream()
                .map(student -> new StudentHoursResponseDTO(
                        ((UUID) student[0]), // organizer_id
                        (String) student[1],               // organizer_name
                        ((String) student[2]),
                        ((Number) student[3]).longValue(),
                        ((Number) student[3]).longValue()
                )).toList();
    }

    public ExtracurricularAverageResponse getStatistics(){
        var result =  repository.getGlobalMetrics();

        if (result == null || result.isEmpty()) return new ExtracurricularAverageResponse(0L,0L,0.0,0.0);
        Object[] row = result.get(0);
        return new ExtracurricularAverageResponse(
                ((Number) row[0]).longValue(),
                ((Number) row[1]).longValue(),
                ((Number) row[2]).doubleValue(),
                ((Number) row[3]).doubleValue()
        );
    }
}