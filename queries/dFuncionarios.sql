select
	arqfunc.funcempe as id_loja,
	EMPE.cadanome as DESC_LOJA,
	arqfunc.funccodi as id_funcionario,
	vend.codvend as id_vendedor,
	TRIM(func.cadanome) as desc_funcionario,
	func.cadasexo as desc_sexo,
	arqeciv.ecivdesc as desc_estado_civil,
	arqtabe.tabedesc as desc_departamento,
	arqfunc.funcdadm as data_admissao,
	arqfunc.funcddem as data_demissao,
	func.cadadtna::date as data_nascimento,
	to_char(func.cadadtna,'MM') AS desc_mes_aniversario,
	to_char(func.cadadtna,'DD/MM') AS desc_data_aniversario,
	arqccus.ccusdesc as desc_centro_custo,
	func.cadacnpj as num_cnpj,
	func.cadaiest as desc_inscricao_estadual,
	(arqfunc.funcddem - arqfunc.funcdadm) as dias_trabalhados,
	-- Última data de transferência de saída (se houver)
    (
	select
		h.htradtro
	from
		arqhtra h
	where
		h.htracodi = arqfunc.funccodi
		-- origem = funcionário
		and h.htracodd <> arqfunc.funccodi
		-- destino diferente
	order by
		h.htradtro desc nulls last
	limit 1
    ) as data_transferencia_saida,
	-- Último salário (pela ordem data + prioridade)
    coalesce((
        select hs.hsalvalo
        from arqhsal hs
        where hs.hsalcodi = arqfunc.funccodi
        order by hs.hsaldata desc, hs.hsalcpri desc
        limit 1
    ), '0') as valor_salario,
	-- Último cargo (descrição)
    coalesce((
        select tc.tcardesc
        from arqhsal hs
        left join arqtcar tc on tc.tcarcodi = hs.hsaltcar
        where hs.hsalcodi = arqfunc.funccodi
        order by hs.hsaldata desc, hs.hsalcpri desc
        limit 1
    ), '') as desc_cargo,
    case 
    	when arqfunc.funcstat = 'AT' then 'ATIVO' 
    	when arqfunc.funcstat = 'TR' then 'TRANSFERIDO' 
    	when arqfunc.funcstat = 'DL' then 'DESLIGADO' 
    	when arqfunc.funcstat = 'DM' then 'DEMITIDO' 
    	else ''
    end as desc_status,
    arqfunc.funcapos as desc_aposentado
from
	arqfunc	
	-- Dados cadastrais do próprio funcionário
left join arqcada func on func.cadacodi = arqfunc.funccodi
	-- Estado civil (via cadastro geral de pessoa)
left join arqcgfp on arqcgfp.cgfpcodi = arqfunc.funccodi
left join arqeciv on arqeciv.ecivcodi = arqcgfp.cgfpeciv
	-- Departamento (tabela de códigos, índice 306)
left join arqtabe on arqtabe.tabecodi = arqfunc.funcdepa
	and arqtabe.tabeindi = 306
	-- Centro de custo (apenas para descrição)
left join arqccus on arqccus.ccuscodi = arqfunc.funcccus
	-- Mapeamento funcionário → vendedor (mesmo CNPJ)
left join (
	select
		distinct
        fun.cadacnpj,
		fun.cadacodi as codfun,
		ven.cadacodi as codvend
	from arqcada fun
	left join (
		select
			cadacnpj,
			cadacodi
		from arqcada
		where cadatipo = 'VEND') ven on fun.cadacnpj = ven.cadacnpj
	where fun.cadatipo = 'FUNC') vend on vend.codfun = arqfunc.funccodi
left join
	(select 
		CADACODI, 
		CADANOME 
	from arqcada 
	where cadatipo = 'EMPE') EMPE on EMPE.CADACODI = ARQFUNC.FUNCEMPE
