package br.com.geac.backend.Domain.Entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
@Table(name = "locations")
public class Location {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(length = 100, nullable = false)
    private String name;

    @Column(length = 150, nullable = false)
    private String street;

    @Column(length = 20)
    private String number;

    @Column(length = 100, nullable = false)
    private String neighborhood;

    @Column(length = 100, nullable = false)
    private String city;

    @Column(length = 2, nullable = false)
    private String state;

    @Column(name = "zip_code", length = 10, nullable = false)
    private String zipCode;

    @Column(name = "reference_point", columnDefinition = "TEXT")
    private String referencePoint;

    @Column(nullable = false)
    private Integer capacity;
}