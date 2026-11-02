package com.cysvet.backend.service;

import com.cysvet.backend.dto.dashboard.DashboardResponse;
import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.StatusAnimal;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.repository.AnimalRepository;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import com.cysvet.backend.repository.PropriedadeRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Indicadores do dashboard, calculados so aqui (o app apenas exibe). Taxas de
 * servico, concepcao e prenhez pelo metodo de ciclos de 21 dias
 * ({@link IndicadoresCiclo21Dias}); concepcao por IA a parte.
 */
@Service
@RequiredArgsConstructor
public class DashboardService {

    private static final ZoneId FUSO_FAZENDA = ZoneId.of("America/Sao_Paulo");

    /** Sem periodo informado: os ultimos 12 meses ate hoje. */
    private static final int DIAS_PERIODO_PADRAO = 365;

    private final PropriedadeRepository farmPropertyRepository;
    private final AnimalRepository animalRepository;
    private final EventoReprodutivoRepository reproductiveEventRepository;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public DashboardResponse getMetrics(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        List<Animal> animals = idPropriedade == null
                ? animalRepository.findAllByOrderByCodigoAsc()
                : animalRepository.findAllByPropriedadeIdOrderByCodigoAsc(idPropriedade);

        // Todos os eventos (nao so os do periodo): saber se a vaca estava prenhe
        // no inicio de um ciclo depende de IAs e partos anteriores.
        List<EventoReprodutivo> allEvents = idPropriedade == null
                ? reproductiveEventRepository.findAllByOrderByDataEventoDesc()
                : reproductiveEventRepository.findAllByPropriedadeIdOrderByDataEventoDesc(idPropriedade);

        LocalDate hoje = LocalDate.now(FUSO_FAZENDA);
        LocalDate fim = dataFim != null ? dataFim : hoje;
        LocalDate inicio = dataInicio != null ? dataInicio : fim.minusDays(DIAS_PERIODO_PADRAO - 1L);
        // O periodo agora vale tambem sem propriedade selecionada.
        boolean periodoInformado = dataInicio != null || dataFim != null;
        List<EventoReprodutivo> events = periodoInformado
                ? allEvents.stream()
                        .filter(event -> !event.getDataEvento().isBefore(inicio) && !event.getDataEvento().isAfter(fim))
                        .toList()
                : allEvents;

        long inseminations = events.stream().filter(event -> event.getTipo() == TipoEventoReprodutivo.INSEMINATION).count();
        long pregnancies = countInseminationsFollowedByPregnancy(events);
        Double taxaConcepcaoIa = inseminations == 0 ? null : (double) pregnancies / inseminations;

        long inseminatedAnimals = events.stream()
                .filter(event -> event.getTipo() == TipoEventoReprodutivo.INSEMINATION)
                .map(event -> event.getAnimal().getId())
                .distinct()
                .count();
        double mediaInseminacoes = inseminatedAnimals == 0 ? 0.0 : (double) inseminations / inseminatedAnimals;

        List<IndicadoresCiclo21Dias.Historico> rebanho = historicos(animals, allEvents);
        IndicadoresCiclo21Dias.Taxas taxas = IndicadoresCiclo21Dias.calcular(rebanho, inicio, fim, hoje);
        YearMonth ultimoMes = YearMonth.from(fim);
        List<DashboardResponse.PontoMensal> serie = IndicadoresCiclo21Dias
                .serieMensal(rebanho, ultimoMes.minusMonths(5), ultimoMes, hoje).stream()
                .map(ponto -> new DashboardResponse.PontoMensal(ponto.mes().toString(), ponto.taxaServico(),
                        ponto.taxaConcepcao(), ponto.taxaPrenhez()))
                .toList();

        return new DashboardResponse(
                idPropriedade == null ? farmPropertyRepository.findAllByOrderByNomeAsc().size() : 1,
                animals.size(),
                events.size(),
                orZero(taxas.taxaPrenhez()),
                orZero(taxas.taxaServico()),
                mediaInseminacoes,
                calculateAverageCalvingInterval(allEvents),
                taxas.taxaConcepcao(),
                taxaConcepcaoIa,
                taxas.ciclos(),
                taxas.aptas(),
                taxas.servidas(),
                taxas.concebidas(),
                inicio,
                fim,
                serie
        );
    }

    private static double orZero(Double value) {
        return value == null ? 0.0 : value;
    }

    /**
     * Linha do tempo de cada femea ativa: eventos + o resumo do cadastro (rebanho
     * importado da planilha costuma ter so a data do parto e da IA, sem eventos).
     */
    private List<IndicadoresCiclo21Dias.Historico> historicos(List<Animal> animals, List<EventoReprodutivo> events) {
        Map<Long, List<EventoReprodutivo>> byAnimal = events.stream()
                .collect(Collectors.groupingBy(event -> event.getAnimal().getId()));
        List<IndicadoresCiclo21Dias.Historico> rebanho = new ArrayList<>();
        for (Animal animal : animals) {
            if (animal.getStatus() != StatusAnimal.ATIVO) {
                continue;
            }
            List<EventoReprodutivo> doAnimal = byAnimal.getOrDefault(animal.getId(), List.of());
            Set<LocalDate> partos = new TreeSet<>();
            Set<LocalDate> ias = new TreeSet<>();
            Set<LocalDate> fimDePrenhez = new TreeSet<>();
            for (EventoReprodutivo event : doAnimal) {
                switch (event.getTipo()) {
                    case CALVING -> {
                        partos.add(event.getDataEvento());
                        fimDePrenhez.add(event.getDataEvento());
                    }
                    case INSEMINATION -> ias.add(event.getDataEvento());
                    case GESTATIONAL_LOSS -> fimDePrenhez.add(event.getDataEvento());
                    case PREGNANCY_DIAGNOSIS -> {
                        if (Boolean.FALSE.equals(event.getPrenhezConfirmada())) {
                            fimDePrenhez.add(event.getDataEvento());
                        }
                    }
                    case REPRODUCTIVE_STATUS_CHECK -> {
                        if (statusObservado(event) == StatusReprodutivoAnimal.EMPTY) {
                            fimDePrenhez.add(event.getDataEvento());
                        }
                    }
                    default -> {
                        // demais eventos nao mudam a linha do tempo reprodutiva
                    }
                }
            }
            if (animal.getDataUltimoParto() != null) {
                partos.add(animal.getDataUltimoParto());
                fimDePrenhez.add(animal.getDataUltimoParto());
            }
            if (animal.getDataInseminacao() != null) {
                ias.add(animal.getDataInseminacao());
            }
            Set<LocalDate> concepcoes = new TreeSet<>(concepcoes(doAnimal));
            if (animal.getStatusReprodutivo() == StatusReprodutivoAnimal.PREGNANT && animal.getDataInseminacao() != null) {
                concepcoes.add(animal.getDataInseminacao());
            }
            rebanho.add(new IndicadoresCiclo21Dias.Historico(animal.getDataNascimento(), List.copyOf(partos),
                    List.copyOf(ias), List.copyOf(concepcoes), List.copyOf(fimDePrenhez)));
        }
        return rebanho;
    }

    /**
     * IAs seguidas de prenhez: a vaca foi vista prenha depois da IA e antes da proxima IA.
     * A visita registra "prenha" na verificacao de status, e uma mesma prenhez costuma
     * aparecer em varias visitas; por isso a contagem e por IA, nao por diagnostico.
     */
    private long countInseminationsFollowedByPregnancy(List<EventoReprodutivo> events) {
        return events.stream()
                .filter(event -> event.getTipo() == TipoEventoReprodutivo.INSEMINATION || isPositiveDiagnosis(event))
                .collect(Collectors.groupingBy(event -> event.getAnimal().getId()))
                .values().stream()
                .mapToLong(animalEvents -> concepcoes(animalEvents).size())
                .sum();
    }

    /** IAs do animal seguidas de diagnostico positivo antes da proxima IA. */
    private List<LocalDate> concepcoes(List<EventoReprodutivo> animalEvents) {
        List<LocalDate> inseminations = animalEvents.stream()
                .filter(event -> event.getTipo() == TipoEventoReprodutivo.INSEMINATION)
                .map(EventoReprodutivo::getDataEvento)
                .sorted()
                .toList();
        List<LocalDate> diagnoses = animalEvents.stream()
                .filter(this::isPositiveDiagnosis)
                .map(EventoReprodutivo::getDataEvento)
                .toList();
        List<LocalDate> result = new ArrayList<>();
        for (int index = 0; index < inseminations.size(); index++) {
            LocalDate insemination = inseminations.get(index);
            LocalDate next = index + 1 < inseminations.size() ? inseminations.get(index + 1) : null;
            boolean pregnant = diagnoses.stream()
                    .anyMatch(date -> date.isAfter(insemination) && (next == null || !date.isAfter(next)));
            if (pregnant) {
                result.add(insemination);
            }
        }
        return result;
    }

    private boolean isPositiveDiagnosis(EventoReprodutivo event) {
        if (event.getTipo() == TipoEventoReprodutivo.PREGNANCY_DIAGNOSIS) {
            return Boolean.TRUE.equals(event.getPrenhezConfirmada());
        }
        return event.getTipo() == TipoEventoReprodutivo.REPRODUCTIVE_STATUS_CHECK
                && statusObservado(event) == StatusReprodutivoAnimal.PREGNANT;
    }

    private StatusReprodutivoAnimal statusObservado(EventoReprodutivo event) {
        if (event.getDetalhesJson() == null || event.getDetalhesJson().isBlank()) {
            return null;
        }
        JsonNode status;
        try {
            status = objectMapper.readTree(event.getDetalhesJson()).get("status");
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao ler detalhes do evento " + event.getIdExterno(), exception);
        }
        if (status == null || status.isNull()) {
            return null;
        }
        try {
            return StatusReprodutivoAnimal.fromValue(status.asText());
        } catch (IllegalArgumentException exception) {
            return null;
        }
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
