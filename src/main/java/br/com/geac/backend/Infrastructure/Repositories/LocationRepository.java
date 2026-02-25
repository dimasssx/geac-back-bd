package br.com.geac.backend.Infrastructure.Repositories;

import br.com.geac.backend.Domain.Entities.Location;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LocationRepository extends JpaRepository<Location, Integer> {


    boolean existsByZipCodeAndNumberAndNameAndIdNot(String zipCode, String number, String name, Integer id);

    boolean existsByZipCodeAndNumberAndName(String zipCode, String number, String name);
}