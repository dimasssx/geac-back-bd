package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "speakers")
@Getter
@Setter
@NoArgsConstructor

public class Speaker {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String name;

    @Column(columnDefinition = "TEXT")
    private String bio;

    private String email;

    @OneToMany(mappedBy = "speaker", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<Qualification> qualifications = new HashSet<>();

    public void addQualification(Qualification qualification) {

        qualifications.add(qualification);
        qualification.setSpeaker(this);
    }

    public void removeQualification(Qualification qualification) {

        qualifications.remove(qualification);
        qualification.setSpeaker(null);
    }

    public void setQualifications(Set<Qualification> qualifications) {

        this.qualifications.clear();
        if (qualifications != null) {
            qualifications.forEach(this::addQualification);
        }
    }
}
