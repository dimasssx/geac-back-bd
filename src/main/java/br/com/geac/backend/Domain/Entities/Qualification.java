package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "speaker_qualifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Qualification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "speaker_id", nullable = false)
    private Speaker speaker;

    @Column(name = "title_name", nullable = false)
    private String titleName;

    private String institution;


}
