package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Aplication.DTOs.Reponse.MemberResponseDTO;
import br.com.geac.backend.Aplication.DTOs.Request.AddMemberRequestDTO;
import br.com.geac.backend.Domain.Entities.Organizer;
import br.com.geac.backend.Domain.Entities.OrganizerMember;
import br.com.geac.backend.Domain.Entities.User;
import br.com.geac.backend.Domain.Exceptions.ConflictException;
import br.com.geac.backend.Repositories.OrganizerMemberRepository;
import br.com.geac.backend.Repositories.OrganizerRepository;
import br.com.geac.backend.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrganizerMemberService {

    private final OrganizerMemberRepository memberRepository;
    private final OrganizerRepository organizerRepository;
    private final UserRepository userRepository;

    @Transactional
    public void addMember(Integer organizerId, AddMemberRequestDTO dto) {
        //verifica se a org existe
        Organizer organizer = organizerRepository.findById(organizerId)
                .orElseThrow(() -> new RuntimeException("Organização não encontrada."));

        //verifica se o usuario existe
        User user = userRepository.findById(dto.userId())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado."));

        //verifica se o usuário ja eh membro
        if (memberRepository.existsByOrganizerIdAndUserId(organizerId, dto.userId())) {
            throw new ConflictException("Este usuário já é membro desta organização.");
        }

        OrganizerMember newMember = new OrganizerMember();
        newMember.setOrganizer(organizer);
        newMember.setUser(user);

        memberRepository.save(newMember);
    }

    //pegar todos os membros da org
    @Transactional(readOnly = true)
    public List<MemberResponseDTO> getMembersByOrganizerId(Integer organizerId) {
        if (!organizerRepository.existsById(organizerId)) {
            throw new RuntimeException("Organização não encontrada.");
        }

        List<OrganizerMember> members = memberRepository.findAllByOrganizerId(organizerId);

        return members.stream()
                .map(member -> new MemberResponseDTO(
                        member.getUser().getId(),
                        member.getUser().getName(),
                        member.getUser().getEmail(),
                        member.getCreatedAt()
                ))
                .toList();
    }

    @Transactional
    public void removeMember(Integer organizerId, UUID userId) {
        OrganizerMember memberLink = memberRepository.findByOrganizerIdAndUserId(organizerId, userId)
                .orElseThrow(() -> new RuntimeException("Vínculo de membro não encontrado nesta organização."));

        memberRepository.delete(memberLink);
    }
}