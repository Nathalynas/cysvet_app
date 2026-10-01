package com.cysvet.backend.service;

import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.SituacaoProdutivaAnimal;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Recalcula o resumo reprodutivo do animal (lactacoes, ultimo parto, ultima IA,
 * touro, status reprodutivo e situacao produtiva) a partir da base informada
 * manualmente e dos eventos, sempre em ordem cronologica pela data do evento.
 *
 * <p>Situacao reprodutiva e produtiva sao independentes: a secagem muda so a
 * produtiva (a vaca seca continua prenha) e o parto volta a vaca para lactante.
 *
 * <p>Como o resultado nao depende da ordem em que os eventos chegam ao servidor,
 * visitas feitas offline e sincronizadas fora de ordem produzem o mesmo resumo.
 */
@Service
@RequiredArgsConstructor
public class ResumoReprodutivoAnimalService {

    // Datas de evento sao dias do calendario da fazenda; a base manual e um instante.
    private static final ZoneId FUSO_FAZENDA = ZoneId.of("America/Sao_Paulo");

    private static final Comparator<EventoReprodutivo> ORDEM_CRONOLOGICA = Comparator
            .comparing(EventoReprodutivo::getDataEvento)
            .thenComparingInt(evento -> prioridadeNoMesmoDia(evento.getTipo()))
            .thenComparing(EventoReprodutivo::getDataCriacao, Comparator.nullsLast(Comparator.naturalOrder()));

    private final EventoReprodutivoRepository eventoReprodutivoRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public void recalcular(Animal animal) {
        if (animal.getId() == null) {
            return;
        }
        recalcular(animal, eventoReprodutivoRepository.findAllByAnimalId(animal.getId()));
    }

    // Uma visita afeta o rebanho inteiro: os eventos de todos os animais vem numa
    // consulta so, em vez de uma por animal.
    @Transactional
    public void recalcularTodos(Collection<Animal> animais) {
        List<Animal> comId = animais.stream().filter(animal -> animal.getId() != null).toList();
        if (comId.isEmpty()) {
            return;
        }
        Map<Long, List<EventoReprodutivo>> eventosPorAnimal = eventoReprodutivoRepository
                .findAllByAnimalIdIn(comId.stream().map(Animal::getId).toList()).stream()
                .collect(Collectors.groupingBy(evento -> evento.getAnimal().getId()));
        comId.forEach(animal -> recalcular(animal, eventosPorAnimal.getOrDefault(animal.getId(), List.of())));
    }

    private void recalcular(Animal animal, List<EventoReprodutivo> eventosDoAnimal) {
        List<EventoReprodutivo> eventos = eventosDoAnimal.stream()
                .sorted(ORDEM_CRONOLOGICA)
                .toList();

        int lactacoes = animal.getBaseNumeroLactacao() == null ? 0 : animal.getBaseNumeroLactacao();
        LocalDate ultimoParto = animal.getBaseDataUltimoParto();
        LocalDate ultimaIa = animal.getBaseDataInseminacao();
        String touro = animal.getBaseTouroIa();

        for (EventoReprodutivo evento : eventos) {
            LocalDate data = evento.getDataEvento();
            if (evento.getTipo() == TipoEventoReprodutivo.CALVING
                    && (ultimoParto == null || data.isAfter(ultimoParto))) {
                // Partos ate a data do ultimo parto da base ja estao contados nela.
                lactacoes++;
                ultimoParto = data;
            }
            if (evento.getTipo() == TipoEventoReprodutivo.INSEMINATION
                    && (ultimaIa == null || !data.isBefore(ultimaIa))) {
                ultimaIa = data;
                String touroDoEvento = detalheTexto(evento, "touro");
                if (touroDoEvento != null) {
                    touro = touroDoEvento;
                }
            }
        }

        // A IA anterior ao ultimo parto pertence a lactacao passada.
        if (ultimaIa != null && ultimoParto != null && !ultimaIa.isAfter(ultimoParto)) {
            ultimaIa = null;
        }

        animal.setNumeroLactacao(lactacoes);
        animal.setDataUltimoParto(ultimoParto);
        animal.setDataInseminacao(ultimaIa);
        animal.setTouroIa(touro);
        animal.setStatusReprodutivo(calcularStatus(animal, eventos));
        animal.setSituacaoProdutiva(calcularSituacaoProdutiva(animal, eventos, lactacoes));
    }

    private StatusReprodutivoAnimal calcularStatus(Animal animal, List<EventoReprodutivo> eventos) {
        StatusReprodutivoAnimal status = null;
        // "Seca" como situacao reprodutiva (dado antigo) e produtiva: nao vale como base.
        StatusReprodutivoAnimal statusBase = animal.getBaseStatusReprodutivo() == StatusReprodutivoAnimal.DRY
                ? null
                : animal.getBaseStatusReprodutivo();
        Instant baseEm = statusBase == null ? null : animal.getBaseStatusReprodutivoEm();

        // Eventos anteriores a correcao manual sao sobrepostos por ela; os
        // posteriores prevalecem sobre ela.
        for (EventoReprodutivo evento : eventos) {
            if (!ocorreDepoisDaBase(evento, baseEm)) {
                status = aplicarStatus(status, evento);
            }
        }
        if (statusBase != null) {
            status = statusBase;
        }
        for (EventoReprodutivo evento : eventos) {
            if (ocorreDepoisDaBase(evento, baseEm)) {
                status = aplicarStatus(status, evento);
            }
        }
        return status;
    }

    private SituacaoProdutivaAnimal calcularSituacaoProdutiva(Animal animal, List<EventoReprodutivo> eventos,
                                                            int lactacoes) {
        SituacaoProdutivaAnimal situacao = null;
        SituacaoProdutivaAnimal situacaoBase = animal.getBaseSituacaoProdutiva();
        Instant baseEm = situacaoBase == null ? null : animal.getBaseSituacaoProdutivaEm();

        // Mesma regra da situacao reprodutiva em relacao a correcao manual.
        for (EventoReprodutivo evento : eventos) {
            if (!ocorreDepoisDaBase(evento, baseEm)) {
                situacao = aplicarSituacaoProdutiva(situacao, evento);
            }
        }
        if (situacaoBase != null) {
            situacao = situacaoBase;
        }
        for (EventoReprodutivo evento : eventos) {
            if (ocorreDepoisDaBase(evento, baseEm)) {
                situacao = aplicarSituacaoProdutiva(situacao, evento);
            }
        }
        if (situacao == null) {
            // Nada informado: quem ja pariu esta em lactacao; quem nao pariu e novilha.
            situacao = lactacoes > 0 ? SituacaoProdutivaAnimal.LACTANTE : SituacaoProdutivaAnimal.NOVILHA;
        }
        return situacao;
    }

    private boolean ocorreDepoisDaBase(EventoReprodutivo evento, Instant baseEm) {
        if (baseEm == null) {
            return true;
        }
        LocalDate diaDaBase = baseEm.atZone(FUSO_FAZENDA).toLocalDate();
        if (!evento.getDataEvento().equals(diaDaBase)) {
            return evento.getDataEvento().isAfter(diaDaBase);
        }
        return evento.getDataCriacao() != null && evento.getDataCriacao().isAfter(baseEm);
    }

    private StatusReprodutivoAnimal aplicarStatus(StatusReprodutivoAnimal atual, EventoReprodutivo evento) {
        return switch (evento.getTipo()) {
            case INSEMINATION -> StatusReprodutivoAnimal.INSEMINATED;
            case PREGNANCY_DIAGNOSIS -> evento.getPrenhezConfirmada() == null
                    ? atual
                    : evento.getPrenhezConfirmada() ? StatusReprodutivoAnimal.PREGNANT : StatusReprodutivoAnimal.EMPTY;
            case CALVING -> StatusReprodutivoAnimal.PENDING;
            // Secagem e produtiva: a situacao reprodutiva (ex.: prenha) continua.
            case DRY_OFF -> atual;
            case GESTATIONAL_LOSS -> StatusReprodutivoAnimal.EMPTY;
            case REPRODUCTIVE_STATUS_CHECK -> statusObservado(evento, atual);
            case POST_PARTUM_COMPLICATION, HEALTH_TREATMENT, MILK_CONTROL, LOT_MOVEMENT, DISCARD, DEATH -> atual;
        };
    }

    private StatusReprodutivoAnimal statusObservado(EventoReprodutivo evento, StatusReprodutivoAnimal atual) {
        String valor = detalheTexto(evento, "status");
        if (valor == null) {
            return atual;
        }
        try {
            StatusReprodutivoAnimal observado = StatusReprodutivoAnimal.fromValue(valor);
            return observado == StatusReprodutivoAnimal.DRY ? atual : observado;
        } catch (IllegalArgumentException exception) {
            return atual;
        }
    }

    private SituacaoProdutivaAnimal aplicarSituacaoProdutiva(SituacaoProdutivaAnimal atual, EventoReprodutivo evento) {
        return switch (evento.getTipo()) {
            case CALVING -> SituacaoProdutivaAnimal.LACTANTE;
            case DRY_OFF -> SituacaoProdutivaAnimal.SECA;
            case REPRODUCTIVE_STATUS_CHECK -> situacaoProdutivaObservada(evento, atual);
            case INSEMINATION, PREGNANCY_DIAGNOSIS, GESTATIONAL_LOSS, POST_PARTUM_COMPLICATION, HEALTH_TREATMENT,
                 MILK_CONTROL, LOT_MOVEMENT, DISCARD, DEATH -> atual;
        };
    }

    private SituacaoProdutivaAnimal situacaoProdutivaObservada(EventoReprodutivo evento, SituacaoProdutivaAnimal atual) {
        SituacaoProdutivaAnimal observada =
                SituacaoProdutivaAnimal.fromValueOrNull(detalheTexto(evento, "situacaoProdutiva"));
        if (observada != null) {
            return observada;
        }
        // Visitas antigas registravam "seca" na situacao reprodutiva.
        String status = detalheTexto(evento, "status");
        return status != null && SituacaoProdutivaAnimal.fromValueOrNull(status) == SituacaoProdutivaAnimal.SECA
                ? SituacaoProdutivaAnimal.SECA
                : atual;
    }

    // No mesmo dia: o parto encerra o ciclo anterior, a IA vem depois e a
    // observacao do veterinario resume a situacao ao final do dia.
    private static int prioridadeNoMesmoDia(TipoEventoReprodutivo tipo) {
        return switch (tipo) {
            case CALVING -> 0;
            case INSEMINATION -> 1;
            case DRY_OFF -> 2;
            case GESTATIONAL_LOSS -> 3;
            case PREGNANCY_DIAGNOSIS -> 4;
            case REPRODUCTIVE_STATUS_CHECK -> 5;
            case POST_PARTUM_COMPLICATION, HEALTH_TREATMENT, MILK_CONTROL, LOT_MOVEMENT, DISCARD, DEATH -> 6;
        };
    }

    private String detalheTexto(EventoReprodutivo evento, String chave) {
        if (evento.getDetalhesJson() == null || evento.getDetalhesJson().isBlank()) {
            return null;
        }
        try {
            JsonNode valor = objectMapper.readTree(evento.getDetalhesJson()).get(chave);
            if (valor == null || valor.isNull() || valor.asText().isBlank()) {
                return null;
            }
            return valor.asText().trim();
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Falha ao ler detalhes do evento " + evento.getIdExterno(), exception);
        }
    }
}
