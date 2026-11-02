package com.cysvet.backend.service;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Taxas de servico, concepcao e prenhez pelo metodo de ciclos de 21 dias
 * (a duracao do ciclo estral), o mesmo usado nas planilhas de campo:
 *
 * <ul>
 *   <li><b>Apta</b> no ciclo: nao prenhe no inicio do ciclo e ja liberada para
 *   servico (vaca: {@value #PEV_DIAS} dias apos o parto; novilha: a partir de
 *   {@value #IDADE_NOVILHA_MESES} meses).</li>
 *   <li><b>Servida</b>: apta que recebeu IA no ciclo.</li>
 *   <li><b>Concebida</b>: servida cuja IA do ciclo resultou em prenhez.</li>
 * </ul>
 *
 * <p>Taxa de servico = servidas / aptas; concepcao = concebidas / servidas;
 * prenhez = concebidas / aptas. Ciclos que terminaram ha menos de
 * {@value #DIAS_ATE_DIAGNOSTICO} dias ainda nao tem diagnostico e ficam fora da
 * concepcao e da prenhez (entram so no servico).
 *
 * <p>Classe pura (sem banco) para ser testada com rebanhos montados a mao.
 * Os parametros devem ser validados pelo veterinario responsavel.
 */
public final class IndicadoresCiclo21Dias {

    public static final int DIAS_CICLO = 21;
    public static final int PEV_DIAS = 60;
    public static final int IDADE_NOVILHA_MESES = 14;
    public static final int DIAS_ATE_DIAGNOSTICO = 30;

    private IndicadoresCiclo21Dias() {
    }

    /**
     * Linha do tempo reprodutiva de uma femea ativa.
     *
     * @param concepcoes datas das IAs que resultaram em prenhez
     * @param fimDePrenhez partos, perdas e diagnosticos negativos
     */
    public record Historico(
            LocalDate nascimento,
            List<LocalDate> partos,
            List<LocalDate> ias,
            List<LocalDate> concepcoes,
            List<LocalDate> fimDePrenhez
    ) {
    }

    public record Taxas(
            int ciclos,
            long aptas,
            long servidas,
            long concebidas,
            Double taxaServico,
            Double taxaConcepcao,
            Double taxaPrenhez
    ) {
    }

    public record PontoMensal(YearMonth mes, Double taxaServico, Double taxaConcepcao, Double taxaPrenhez) {
    }

    public static Taxas calcular(Collection<Historico> rebanho, LocalDate inicio, LocalDate fim, LocalDate hoje) {
        return somar(ciclos(rebanho, inicio, fim, hoje));
    }

    /** Um ponto por mes, com os ciclos que comecam naquele mes. */
    public static List<PontoMensal> serieMensal(Collection<Historico> rebanho, YearMonth primeiro, YearMonth ultimo,
                                                LocalDate hoje) {
        Map<YearMonth, List<Ciclo>> porMes = new LinkedHashMap<>();
        for (YearMonth mes = primeiro; !mes.isAfter(ultimo); mes = mes.plusMonths(1)) {
            porMes.put(mes, new ArrayList<>());
        }
        LocalDate fim = ultimo.atEndOfMonth().isAfter(hoje) ? hoje : ultimo.atEndOfMonth();
        for (Ciclo ciclo : ciclos(rebanho, primeiro.atDay(1), fim, hoje)) {
            List<Ciclo> doMes = porMes.get(YearMonth.from(ciclo.inicio()));
            if (doMes != null) {
                doMes.add(ciclo);
            }
        }
        List<PontoMensal> serie = new ArrayList<>();
        porMes.forEach((mes, ciclos) -> {
            Taxas taxas = somar(ciclos);
            serie.add(new PontoMensal(mes, taxas.taxaServico(), taxas.taxaConcepcao(), taxas.taxaPrenhez()));
        });
        return serie;
    }

    private record Ciclo(LocalDate inicio, long aptas, long servidas, long aptasConhecidas,
                         long servidasConhecidas, long concebidas) {
    }

    private static List<Ciclo> ciclos(Collection<Historico> rebanho, LocalDate inicio, LocalDate fim, LocalDate hoje) {
        List<Ciclo> ciclos = new ArrayList<>();
        LocalDate limiteDiagnostico = hoje.minusDays(DIAS_ATE_DIAGNOSTICO);
        for (LocalDate ini = inicio; !ini.isAfter(fim); ini = ini.plusDays(DIAS_CICLO)) {
            LocalDate ultimoDia = ini.plusDays(DIAS_CICLO - 1L);
            boolean conhecido = !ultimoDia.isAfter(limiteDiagnostico);
            long aptas = 0;
            long servidas = 0;
            long concebidas = 0;
            for (Historico animal : rebanho) {
                if (!apta(animal, ini)) {
                    continue;
                }
                aptas++;
                if (algumaEntre(animal.ias(), ini, ultimoDia)) {
                    servidas++;
                    if (conhecido && algumaEntre(animal.concepcoes(), ini, ultimoDia)) {
                        concebidas++;
                    }
                }
            }
            ciclos.add(new Ciclo(ini, aptas, servidas, conhecido ? aptas : 0, conhecido ? servidas : 0, concebidas));
        }
        return ciclos;
    }

    private static Taxas somar(List<Ciclo> ciclos) {
        long aptas = 0;
        long servidas = 0;
        long aptasConhecidas = 0;
        long servidasConhecidas = 0;
        long concebidas = 0;
        for (Ciclo ciclo : ciclos) {
            aptas += ciclo.aptas();
            servidas += ciclo.servidas();
            aptasConhecidas += ciclo.aptasConhecidas();
            servidasConhecidas += ciclo.servidasConhecidas();
            concebidas += ciclo.concebidas();
        }
        return new Taxas(ciclos.size(), aptas, servidas, concebidas,
                razao(servidas, aptas), razao(concebidas, servidasConhecidas), razao(concebidas, aptasConhecidas));
    }

    static boolean apta(Historico animal, LocalDate inicioCiclo) {
        LocalDate ultimoParto = ultimaAte(animal.partos(), inicioCiclo);
        boolean liberada;
        if (ultimoParto != null) {
            liberada = !inicioCiclo.isBefore(ultimoParto.plusDays(PEV_DIAS));
        } else if (animal.nascimento() != null) {
            liberada = !inicioCiclo.isBefore(animal.nascimento().plusMonths(IDADE_NOVILHA_MESES));
        } else {
            // Sem parto nem nascimento nao da para saber se ja pode ser servida.
            liberada = false;
        }
        return liberada && !prenheEm(animal, inicioCiclo);
    }

    private static boolean prenheEm(Historico animal, LocalDate dia) {
        LocalDate concepcao = ultimaAntes(animal.concepcoes(), dia);
        if (concepcao == null) {
            return false;
        }
        return animal.fimDePrenhez().stream()
                .noneMatch(fim -> fim.isAfter(concepcao) && !fim.isAfter(dia));
    }

    private static boolean algumaEntre(List<LocalDate> datas, LocalDate inicio, LocalDate fim) {
        return datas.stream().anyMatch(data -> !data.isBefore(inicio) && !data.isAfter(fim));
    }

    private static LocalDate ultimaAte(List<LocalDate> datas, LocalDate dia) {
        return datas.stream().filter(data -> !data.isAfter(dia)).max(LocalDate::compareTo).orElse(null);
    }

    private static LocalDate ultimaAntes(List<LocalDate> datas, LocalDate dia) {
        return datas.stream().filter(data -> data.isBefore(dia)).max(LocalDate::compareTo).orElse(null);
    }

    private static Double razao(long numerador, long denominador) {
        return denominador == 0 ? null : (double) numerador / denominador;
    }
}
