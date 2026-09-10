package com.cysvet.backend.repository;

import com.cysvet.backend.entity.AnimalHistorico;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AnimalHistoricoRepository extends JpaRepository<AnimalHistorico, Long> {

    List<AnimalHistorico> findAllByAnimalIdOrderByDataCriacaoDesc(Long animalId);
}
