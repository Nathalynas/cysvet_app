package com.cysvet.backend.service;

import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.repository.AnimalRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Recalcula, na inicializacao, o resumo dos animais marcados por uma migration
 * que mudou a regra do recalculo (ex.: V19). Sem isso o resumo gravado so seria
 * corrigido na proxima visita, evento ou edicao do animal.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RecalculoResumoPendente implements ApplicationRunner {

    private final AnimalRepository animalRepository;
    private final ResumoReprodutivoAnimalService resumoReprodutivoAnimalService;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        List<Animal> pendentes = animalRepository.findAllByResumoPendenteTrue();
        if (pendentes.isEmpty()) {
            return;
        }
        resumoReprodutivoAnimalService.recalcularTodos(pendentes);
        pendentes.forEach(animal -> animal.setResumoPendente(false));
        log.info("Resumo reprodutivo recalculado para {} animais pendentes", pendentes.size());
    }
}
