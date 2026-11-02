package com.cysvet.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import com.cysvet.backend.service.IndicadoresCiclo21Dias.Historico;
import com.cysvet.backend.service.IndicadoresCiclo21Dias.Taxas;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * Rebanho montado a mao, com o resultado conferido ciclo a ciclo.
 *
 * <pre>
 * Ciclos: C1 01/01-21/01, C2 22/01-11/02, C3 12/02-04/03 (2026)
 * A  parto 01/10/25, IA 05/01 concebeu         C1 apta/servida/concebida; C2 e C3 prenhe
 * B  parto 10/12/25, sem IA                    DEL 22, 43, 64: so apta no C3
 * C  parto 01/09/25, IA 10/01 falhou,          C1 apta/servida; C2 apta/servida/concebida;
 *    IA 01/02 concebeu                         C3 prenhe
 * D  novilha nascida 01/10/24 (14 m em 12/25)  apta nos 3, sem IA
 * E  sem parto nem nascimento                  nunca apta
 * F  prenhe desde 01/11/25                     nunca apta
 * Totais: aptas 3+2+2 = 7, servidas 2+1+0 = 3, concebidas 1+1 = 2
 * </pre>
 */
class IndicadoresCiclo21DiasTest {

    private static final LocalDate INICIO = LocalDate.of(2026, 1, 1);
    private static final LocalDate FIM = LocalDate.of(2026, 3, 4);

    private static LocalDate d(int ano, int mes, int dia) {
        return LocalDate.of(ano, mes, dia);
    }

    private static final List<Historico> REBANHO = List.of(
            new Historico(null, List.of(d(2025, 10, 1)), List.of(d(2026, 1, 5)), List.of(d(2026, 1, 5)), List.of()),
            new Historico(null, List.of(d(2025, 12, 10)), List.of(), List.of(), List.of()),
            new Historico(null, List.of(d(2025, 9, 1)), List.of(d(2026, 1, 10), d(2026, 2, 1)),
                    List.of(d(2026, 2, 1)), List.of()),
            new Historico(d(2024, 10, 1), List.of(), List.of(), List.of(), List.of()),
            new Historico(null, List.of(), List.of(), List.of(), List.of()),
            new Historico(null, List.of(d(2024, 12, 1)), List.of(d(2025, 11, 1)), List.of(d(2025, 11, 1)), List.of()));

    @Test
    void taxasDosCiclosConferidasAMao() {
        Taxas taxas = IndicadoresCiclo21Dias.calcular(REBANHO, INICIO, FIM, d(2026, 6, 1));

        assertEquals(3, taxas.ciclos());
        assertEquals(7, taxas.aptas());
        assertEquals(3, taxas.servidas());
        assertEquals(2, taxas.concebidas());
        assertEquals(3.0 / 7, taxas.taxaServico(), 1e-9);
        assertEquals(2.0 / 3, taxas.taxaConcepcao(), 1e-9);
        assertEquals(2.0 / 7, taxas.taxaPrenhez(), 1e-9);
    }

    @Test
    void cicloSemTempoParaODiagnosticoFicaForaDaConcepcaoEDaPrenhez() {
        // Hoje 20/02: so o C1 (ate 21/01) tem 30 dias para o DG.
        Taxas taxas = IndicadoresCiclo21Dias.calcular(REBANHO, INICIO, FIM, d(2026, 2, 20));

        assertEquals(3.0 / 7, taxas.taxaServico(), 1e-9);
        assertEquals(1.0 / 2, taxas.taxaConcepcao(), 1e-9);
        assertEquals(1.0 / 3, taxas.taxaPrenhez(), 1e-9);
    }

    @Test
    void partoEncerraAPrenhezEAVacaVoltaASerAptaDepoisDoPev() {
        Historico vaca = new Historico(null, List.of(d(2025, 1, 1), d(2025, 10, 10)), List.of(d(2025, 1, 15)),
                List.of(d(2025, 1, 15)), List.of(d(2025, 10, 10)));

        assertEquals(false, IndicadoresCiclo21Dias.apta(vaca, d(2025, 12, 1)), "DEL 52, ainda no PEV");
        assertEquals(true, IndicadoresCiclo21Dias.apta(vaca, d(2025, 12, 9)), "DEL 60");
    }

    @Test
    void semAnimaisAptosAsTaxasFicamVazias() {
        Taxas taxas = IndicadoresCiclo21Dias.calcular(List.of(), INICIO, FIM, d(2026, 6, 1));
        assertNull(taxas.taxaServico());
        assertNull(taxas.taxaPrenhez());
    }
}
