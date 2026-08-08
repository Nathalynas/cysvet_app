package com.cysvet.backend.dto.visita;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

@Schema(description = "Dados coletados para um animal durante a visita.")
public record VisitaAnimalItemDto(
        @Schema(description = "Identificador interno do animal.", example = "25")
        Long animalId,
        @Schema(description = "Identificador externo do animal.", example = "animal-001")
        String animalIdExterno,
        @Schema(description = "Codigo ou brinco do animal.", example = "46344")
        String animalCodigo,
        @Schema(description = "Categoria do animal.", example = "VACA")
        String animalCategoria,
        @Schema(description = "Idade do animal em meses.", example = "83")
        Integer idadeMeses,
        @Schema(description = "Data de nascimento do animal.", example = "2020-03-12")
        LocalDate dataNascimento,
        @Schema(description = "Situacao produtiva observada.", example = "lactante")
        String situacaoProdutiva,
        @Schema(description = "Situacao reprodutiva observada.", example = "inseminada")
        String situacaoReprodutiva,
        @Schema(description = "Decisao ou conduta definida.", example = "ST cef+pg")
        String decisao,
        @Schema(description = "Data do primeiro parto.", example = "2022-06-20")
        LocalDate dataPrimeiroParto,
        @Schema(description = "Data do ultimo parto.", example = "2026-03-01")
        LocalDate dataUltimoParto,
        @Schema(description = "Data do parto anterior ao ultimo.", example = "2025-02-18")
        LocalDate dataPartoAnterior,
        @Schema(description = "Numero de partos observados.", example = "3")
        Integer numeroPartos,
        @Schema(description = "Data da primeira IA registrada.", example = "2025-08-10")
        LocalDate dataPrimeiraIa,
        @Schema(description = "Data da segunda IA registrada.", example = "2025-09-01")
        LocalDate dataSegundaIa,
        @Schema(description = "Data da terceira IA registrada.", example = "2025-09-23")
        LocalDate dataTerceiraIa,
        @Schema(description = "Data da quarta IA registrada.", example = "2025-10-14")
        LocalDate dataQuartaIa,
        @Schema(description = "Data da quinta IA registrada.", example = "2025-11-03")
        LocalDate dataQuintaIa,
        @Schema(description = "Data da ultima IA.", example = "2025-11-10")
        LocalDate dataUltimaIa,
        @Schema(description = "Numero de IAs recebidas.", example = "1")
        Integer numeroIaRecebida,
        @Schema(description = "Data em que a secagem ocorreu de fato.", example = "2026-05-01")
        LocalDate dataSecagemEfetiva,
        @Schema(description = "Data de entrada no pre-parto.", example = "2026-06-10")
        LocalDate entradaPreParto,
        @Schema(description = "Controle leiteiro observado.", example = "29.5")
        Double controleLeiteiro,
        @Schema(description = "Dias de prenhez.", example = "22")
        Integer diasPrenhez,
        @Schema(description = "Diagnostico complementar.", example = "pg")
        String diagnostico,
        @Schema(description = "Dias em lactacao.", example = "76")
        Integer del,
        @Schema(description = "Idade ao primeiro parto em meses.", example = "25.5")
        Double idadePrimeiroPartoMeses,
        @Schema(description = "Idade na primeira IA em meses.", example = "15.5")
        Double idadePrimeiraIa,
        @Schema(description = "Mes de referencia do parto.", example = "Marco")
        String mesParto,
        @Schema(description = "Ano do ultimo parto.", example = "2026")
        Integer anoUltimoParto,
        @Schema(description = "Intervalo entre partos atual em meses.", example = "12.8")
        Double iepAtual,
        @Schema(description = "Classificacao de partos.", example = "Multipara")
        String classificacaoPartos,
        @Schema(description = "Indica se a vaca esta apta para manejo reprodutivo.", example = "true")
        Boolean vacaApta,
        @Schema(description = "Intervalo entre a primeira e segunda IA em dias.", example = "21")
        Integer intervalo1e2Ia,
        @Schema(description = "Intervalo entre a segunda e terceira IA em dias.", example = "22")
        Integer intervalo2e3Ia,
        @Schema(description = "Intervalo entre a terceira e quarta IA em dias.", example = "21")
        Integer intervalo3e4Ia,
        @Schema(description = "Intervalo entre a quarta e quinta IA em dias.", example = "20")
        Integer intervalo4e5Ia,
        @Schema(description = "Media de intervalo entre IAs em dias.", example = "21.0")
        Double mediaIntervaloIa,
        @Schema(description = "Data prevista para retorno ao cio.", example = "2026-01-10")
        LocalDate previsaoRetornoCio,
        @Schema(description = "DEL na primeira IA.", example = "62")
        Integer delPrimeiraIa,
        @Schema(description = "Periodo de servico em dias.", example = "118")
        Integer periodoServico,
        @Schema(description = "Dias restantes para secagem.", example = "168")
        Integer diasParaSecar,
        @Schema(description = "Data prevista para secagem.", example = "2026-05-19")
        LocalDate previsaoSecagem,
        @Schema(description = "Mes previsto para secagem.", example = "Maio")
        String mesSecagem,
        @Schema(description = "Diferenca calculada para secagem em dias.", example = "12")
        Integer diferencaSecagem,
        @Schema(description = "Periodo de lactacao em dias.", example = "305")
        Integer periodoLactacao,
        @Schema(description = "Data pre-parto.", example = "2026-06-20")
        LocalDate dataPreParto,
        @Schema(description = "Mes do pre-parto.", example = "Junho")
        String mesPreParto,
        @Schema(description = "Duracao do pre-parto em dias.", example = "30")
        Integer duracaoPreParto,
        @Schema(description = "Data prevista para parto.", example = "2026-07-20")
        LocalDate previsaoParto,
        @Schema(description = "Mes previsto para o parto.", example = "Julho")
        String mesPrevistoParto,
        @Schema(description = "IEP projetado em meses.", example = "13.1")
        Double iepProjetado,
        @Schema(description = "Controle leiteiro com desconto.", example = "27.4")
        Double controleLeiteiroComDesconto
) {
}
