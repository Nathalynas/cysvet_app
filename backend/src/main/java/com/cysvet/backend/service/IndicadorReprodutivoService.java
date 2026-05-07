package com.cysvet.backend.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.cysvet.backend.dto.dashboard.DashboardResponse;
import com.cysvet.backend.dto.indicador.IndicadorReprodutivoResponse;
import com.cysvet.backend.entity.IndicadorReprodutivo;
import com.cysvet.backend.entity.Propriedade;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.IndicadorReprodutivoRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class IndicadorReprodutivoService {

    private final IndicadorReprodutivoRepository reproductiveIndicatorRepository;
    private final DashboardService dashboardService;
    private final UsuarioAutenticadoProvider authenticatedUserProvider;
    private final PropriedadeService propriedadeService;

    @Transactional
    public IndicadorReprodutivoResponse snapshot(Long idPropriedade, LocalDate dataInicio, LocalDate dataFim) {
        Usuario user = authenticatedUserProvider.getCurrentUser();
        DashboardResponse dashboard = dashboardService.getMetrics(idPropriedade, dataInicio, dataFim);
        IndicadorReprodutivo indicator = new IndicadorReprodutivo();
        indicator.setUsuario(user);
        indicator.setPropriedade(idPropriedade == null ? null : propriedadeService.getEntity(idPropriedade));
        indicator.setDataReferencia(LocalDate.now());
        indicator.setDataInicio(dataInicio);
        indicator.setDataFim(dataFim);
        indicator.setTotalPropriedades(dashboard.totalPropriedades());
        indicator.setTotalAnimais(dashboard.totalAnimais());
        indicator.setTotalEventos(dashboard.totalEventos());
        indicator.setTaxaPrenhez(dashboard.taxaPrenhez());
        indicator.setTaxaServico(dashboard.taxaServico());
        indicator.setMediaInseminacoes(dashboard.mediaInseminacoes());
        indicator.setIntervaloMedioPartos(dashboard.intervaloMedioPartos());
        return toResponse(reproductiveIndicatorRepository.save(indicator));
    }

    @Transactional(readOnly = true)
    public List<IndicadorReprodutivoResponse> list() {
        return reproductiveIndicatorRepository.findAllByOrderByDataReferenciaDesc().stream()
                .map(this::toResponse)
                .toList();
    }

    private IndicadorReprodutivoResponse toResponse(IndicadorReprodutivo indicator) {
        Propriedade propriedade = indicator.getPropriedade();
        return new IndicadorReprodutivoResponse(
                indicator.getId(),
                propriedade == null ? null : propriedade.getId(),
                indicator.getDataReferencia(),
                indicator.getDataInicio(),
                indicator.getDataFim(),
                indicator.getTotalPropriedades(),
                indicator.getTotalAnimais(),
                indicator.getTotalEventos(),
                indicator.getTaxaPrenhez(),
                indicator.getTaxaServico(),
                indicator.getMediaInseminacoes(),
                indicator.getIntervaloMedioPartos(),
                indicator.getDataCriacao()
        );
    }
}
