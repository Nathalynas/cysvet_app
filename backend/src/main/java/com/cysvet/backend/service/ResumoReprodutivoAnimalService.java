package com.cysvet.backend.service;

import com.cysvet.backend.entity.Animal;
import com.cysvet.backend.entity.EventoReprodutivo;
import com.cysvet.backend.entity.StatusReprodutivoAnimal;
import com.cysvet.backend.entity.TipoEventoReprodutivo;
import com.cysvet.backend.repository.EventoReprodutivoRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Recalcula o resumo reprodutivo do animal (lactacoes, ultimo parto, ultima IA,
 * touro e status reprodutivo) a partir da base informada manualmente e dos
 * eventos, sempre em ordem cronologica pela data do evento.
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

        List<EventoReprodutivo> eventos = eventoReprodutivoRepository.findAllByAnimalId(animal.getId()).stream()
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
    }

    private StatusReprodutivoAnimal calcularStatus(Animal animal, List<EventoReprodutivo> eventos) {
        StatusReprodutivoAnimal status = null;
        StatusReprodutivoAnimal statusBase = animal.getBaseStatusReprodutivo();

        // Eventos anteriores a correcao manual sao sobrepostos por ela; os
        // posteriores prevalecem sobre ela.
        for (EventoReprodutivo evento : eventos) {
            if (!ocorreDepoisDaBase(evento, animal)) {
                status = aplicarStatus(status, evento);
            }
        }
        if (statusBase != null) {
            status = statusBase;
        }
        for (EventoReprodutivo evento : eventos) {
            if (ocorreDepoisDaBase(evento, animal)) {
                status = aplicarStatus(status, evento);
            }
        }
        return status;
    }

    private boolean ocorreDepoisDaBase(EventoReprodutivo evento, Animal animal) {
        Instant baseEm = animal.getBaseStatusReprodutivoEm();
        if (animal.getBaseStatusReprodutivo() == null || baseEm == null) {
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
            case DRY_OFF -> StatusReprodutivoAnimal.DRY;
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
            return StatusReprodutivoAnimal.fromValue(valor);
        } catch (IllegalArgumentException exception) {
            return atual;
        }
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
