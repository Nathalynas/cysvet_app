package com.cysvet.backend.service;

import com.cysvet.backend.dto.dashboard.DashboardResponse;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.AnimalRepository;
import com.cysvet.backend.repository.PropriedadeRepository;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final PropriedadeRepository farmPropertyRepository;
    private final AnimalRepository animalRepository;
    private final EventoReprodutivoRepository reproductiveEventRepository;

    @Transactional(readOnly = true)
    public DashboardResponse getMetrics(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        List<Animal> animals = idPropriedade == null
                ? animalRepository.findAllByOrderByCodigoAsc()
                : animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(idPropriedade);

        List<EventoReprodutivo> events;
        if (idPropriedade == null) {
            events = reproductiveEventRepository.findAllByOrderByDataEventoDesc();
        } else if (dataInicio != null && dataFim != null) {
            events = reproductiveEventRepository.findAllByPropriedadeIdAndDataEventoBetweenOrderByDataEventoDesc(
                    idPropriedade,
                    dataInicio,
                    dataFim
            );
        } else {
            events = reproductiveEventRepository.findAllByPropriedadeIdOrderByDataEventoDesc(idPropriedade);
        }

        long inseminations = events.stream().filter(event -> event.getTipo() == TipoEventoReprodutivo.INSEMINATION).count();
        long pregnancies = events.stream()
                .filter(event -> event.getTipo() == TipoEventoReprodutivo.PREGNANCY_DIAGNOSIS && Boolean.TRUE.equals(event.getPrenhezConfirmada()))
                .count();
        double taxaPrenhez = inseminations == 0 ? 0.0 : (double) pregnancies / inseminations;

        long inseminatedAnimals = events.stream()
                .filter(event -> event.getTipo() == TipoEventoReprodutivo.INSEMINATION)
                .map(event -> event.getAnimal().getId())
                .distinct()
                .count();
        double taxaServico = animals.isEmpty() ? 0.0 : (double) inseminatedAnimals / animals.size();
        double mediaInseminacoes = inseminatedAnimals == 0 ? 0.0 : (double) inseminations / inseminatedAnimals;

        return new DashboardResponse(
                idPropriedade == null ? farmPropertyRepository.findAllByOrderByNomeAsc().size() : 1,
                animals.size(),
                events.size(),
                taxaPrenhez,
                taxaServico,
                mediaInseminacoes,
                calculateAverageCalvingInterval(events)
        );
    }

    private double calculateAverageCalvingInterval(List<EventoReprodutivo> events) {
        Map<Long, List<EventoReprodutivo>> byAnimal = events.stream()
                .filter(event -> event.getTipo() == TipoEventoReprodutivo.CALVING)
                .collect(Collectors.groupingBy(event -> event.getAnimal().getId()));

        List<Long> intervals = new ArrayList<>();
        byAnimal.values().forEach(animalEvents -> {
            List<EventoReprodutivo> sorted = animalEvents.stream()
                    .sorted(Comparator.comparing(EventoReprodutivo::getDataEvento))
                    .toList();
            for (int index = 1; index < sorted.size(); index++) {
                intervals.add(ChronoUnit.DAYS.between(sorted.get(index - 1).getDataEvento(), sorted.get(index).getDataEvento()));
            }
        });

        return intervals.stream().mapToLong(Long::longValue).average().orElse(0.0);
    }
}
