package com.cysvet.backend.repository;

import com.cysvet.backend.entity.IndicadorReprodutivo;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IndicadorReprodutivoRepository extends JpaRepository<IndicadorReprodutivo, Long> {

    List<IndicadorReprodutivo> findAllByUsuarioIdOrderByDataReferenciaDesc(Long idUsuario);
}
