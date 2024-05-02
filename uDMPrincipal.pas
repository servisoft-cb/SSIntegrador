unit uDMPrincipal;

interface

uses
  System.SysUtils,
  System.Classes,
  Classe.Campos,
  System.Generics.Collections,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait,
  Data.DB,
  FireDAC.Comp.Client,
  GravarLog,
  Model.CupomFiscalItem;

type
  TEnumConexao = (tpLocal, tpServer);

type
  TDMPrincipal = class(TDataModule)
    FDLocal: TFDConnection;
    FDServer: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FConsulta: TFDQuery;
  public
    vTabela: String;
    vCondicao: String;
    vTerminal: String;
    ListaTipo: TStringList;
    ListaDados: TObjectList<TCampos>;
    NumReg: Integer;
    function conectar: boolean;
    function desconectar: boolean;

    function Abrir_Tabela_Log(Conexao: TEnumConexao): TFDQuery;
    function Abrir_Tabela(Conexao: TEnumConexao): TFDQuery;
    function Abrir_Tabela_Produto(Conexao: TEnumConexao): TFDQuery;
    function Abrir_Tabela_CupomParc(Conexao: TEnumConexao): TFDQuery;
    function Abrir_Tabela_CupomItem(Conexao: TEnumConexao): TFDQuery;
    function Abrir_Tabela_CupomPendente(Conexao: TEnumConexao): TFDQuery;
    function Abrir_Tabela_Parametro(Conexao: TEnumConexao): TFDQuery;
    procedure AdicionaDados(aValue, aCampo: String; Clear: boolean = True);

    { Public declarations }
  end;

var
  DMPrincipal: TDMPrincipal;

implementation

uses
  Vcl.Dialogs,
  System.Types;

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
{ TDMPrincipal }

function TDMPrincipal.Abrir_Tabela_CupomItem(Conexao: TEnumConexao): TFDQuery;
var
  Consulta: TFDQuery;
  Condicao: String;
  i: Integer;
begin
  Condicao := '';
  Consulta := TFDQuery.Create(Self);
  case Conexao of
    tpLocal:
      Consulta.Connection := FDLocal;
    tpServer:
      Consulta.Connection := FDServer;
  end;
  Consulta.Close;
  Consulta.SQL.Clear;
  Consulta.SQL.Add(GetCupomFiscalItem);
  for i := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
      Consulta.SQL.Add(' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
  end;
  Consulta.Open;
  Result := Consulta;
end;

function TDMPrincipal.Abrir_Tabela_CupomParc(Conexao: TEnumConexao): TFDQuery;
var
  Consulta: TFDQuery;
  Condicao: String;
  i: Integer;
begin
  Condicao := '';
  Consulta := TFDQuery.Create(Self);
  case Conexao of
    tpLocal:
      Consulta.Connection := FDLocal;
    tpServer:
      Consulta.Connection := FDServer;
  end;
  Consulta.Close;
  Consulta.SQL.Clear;
  Consulta.SQL.Add('SELECT ID, PARCELA, DTVENCIMENTO, VLR_VENCIMENTO, ');
  Consulta.SQL.Add('ID_TIPOCOBRANCA, EDITADA from CUPOMFISCAL_PARC ');
  Consulta.SQL.Add('WHERE 0=0 ');
  for i := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
      Consulta.SQL.Add(' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
  end;
  Consulta.Open;
  Result := Consulta;
end;

function TDMPrincipal.Abrir_Tabela_CupomPendente(Conexao: TEnumConexao): TFDQuery;
var
  i: Integer;
  Condicao: String;
begin
  Condicao := '';
  FConsulta := TFDQuery.Create(Self);
  case Conexao of
    tpLocal:
      FConsulta.Connection := FDLocal;
    tpServer:
      FConsulta.Connection := FDServer;
  end;
  FConsulta.Close;
  FConsulta.SQL.Clear;
  FConsulta.SQL.Add('SELECT ');
  FConsulta.SQL.Add('ID_CUPOM, ID_TERMINAL');
  FConsulta.SQL.Add(' FROM CUPOMFISCAL_PENDENTE WHERE 0=0 ');
  for i := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
      FConsulta.SQL.Add(' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
  end;
  FConsulta.Open;
  Result := FConsulta;
end;

function TDMPrincipal.Abrir_Tabela_Log(Conexao: TEnumConexao): TFDQuery;
var
  // Consulta : TFDQuery;
  i: Integer;
  Condicao: String;
begin
  Condicao := '';
  for i := 0 to ListaTipo.Count - 1 do
  begin
    if i = 0 then
      Condicao := QuotedStr(ListaTipo.Strings[i])
    else
      Condicao := Condicao + ',' + QuotedStr(ListaTipo.Strings[i]);
  end;
  FConsulta := TFDQuery.Create(Self);
  try
    case Conexao of
      tpLocal:
        FConsulta.Connection := FDLocal;
      tpServer:
        FConsulta.Connection := FDServer;
    end;
    // FConsulta.FetchOptions.RowsetSize := 5;
    FConsulta.Close;
    FConsulta.SQL.Clear;
    FConsulta.SQL.Add('SELECT ');
    if NumReg > 0 then
      FConsulta.SQL.Add('First(' + NumReg.ToString + ') ');
    FConsulta.SQL.Add('* FROM ' + vTabela + ' WHERE TIPO in ( ' + Condicao + ')');
    FConsulta.SQL.Add(' and id_terminal = ' + vTerminal);
    // FConsulta.FetchOptions.RowsetSize := 5;
    FConsulta.Open;
    Result := FConsulta;
  finally
    // FConsulta.Free;
  end;
end;

function TDMPrincipal.Abrir_Tabela_Parametro(Conexao: TEnumConexao): TFDQuery;
var
  Consulta: TFDQuery;
  Condicao: String;
  i: Integer;
begin
  Condicao := '';
  Consulta := TFDQuery.Create(Self);
  case Conexao of
    tpLocal:
      Consulta.Connection := FDLocal;
    tpServer:
      Consulta.Connection := FDServer;
  end;
  Consulta.Close;
  Consulta.SQL.Clear;
  Consulta.SQL.Add('select ID, SERIENORMAL, SERIECONTINGENCIA, LOCALSERVIDORNFE, ');
  Consulta.SQL.Add('EMAILRESPONSAVELSISTEMA, NFEPRODUCAO, ANEXARDANFE, VERSAONFE, ');
  Consulta.SQL.Add('VERSAOEMISSAONFE, TIPOLOGONFE, APLICARDESCONTONOICMS, ');
  Consulta.SQL.Add('APLICARDESCONTONOIPI, SOMARNOPROD_FRETE, SOMARNOPROD_OUTRASDESP, ');
  Consulta.SQL.Add('SOMARNOPROD_SEGURO, AJUSTELOGONFEAUTOMATICO, INFNUMNOTAMANUAL, ');
  Consulta.SQL.Add('OPCAO_DTENTREGAPEDIDO, OBS_SIMPLES, IMP_OBSSIMPLES, ');
  Consulta.SQL.Add('IMP_REFERENCIANANOTA, ENVIARNOTABENEF_NANFE, ESPECIE_NOTA, ');
  Consulta.SQL.Add('MARCA_NOTA, USA_QTDPACOTE_NTE, ATUALIZAR_PRECO, ');
  Consulta.SQL.Add('USA_VENDEDOR, USA_CONSUMO, IMP_CODPRODCLI_DANFE, USA_DESCRICAODANOTA, ');
  Consulta.SQL.Add('ID_OPERACAO_BENEF_RET, ID_OPERACAO_MAOOBRA, CONFECCAO, ');
  Consulta.SQL.Add('ID_OPERACAO_TRIANGULAR, CADASTRAR_REF_DUP, MOSTRAR_NO_CONSUMO, ');
  Consulta.SQL.Add('USA_COD_BARRAS, USA_ID_PRODUTO, USA_AGENDA_POR_FUNC, EMPRESA_VEICULO, ');
  Consulta.SQL.Add('ID_CONTA_PADRAO, ID_TIPO_COBRANCA_PADRAO, PERMITE_QTDMAIOR_PEDIDO, ');
  Consulta.SQL.Add('USA_TAB_PRECO, PERMITE_MESMA_OC, EMAIL_CONTADOR, ID_BANCO_REMESSA, ');
  Consulta.SQL.Add('USA_SERVICO, ID_CFOP_REQ, ID_CFOP_REQ2, USA_PROJETO_OC, ');
  Consulta.SQL.Add('MOSTRAR_CONSULTA, ID_CLIENTE_CONSUMIDOR, IMPRESSORA_FISCAL, ');
  Consulta.SQL.Add('QUITAR_AVISTA_AUT, IMPRESSAO_MATRICIAL, EMPRESA_RH, ');
  Consulta.SQL.Add('IMPRESSORA_CAMINHO, GRAVAR_NA_REF_CODPRODFORN, GRAVAR_PROD_MAT_RECXML, ');
  Consulta.SQL.Add('NOTA_ENTRADA_MOSTRAR_PROD, ATUALIZAR_PRECO_DOC, BAIXAR_REQ_AUTOMATICO, ');
  Consulta.SQL.Add('DESTACAR_IMPOSTO_NOTA, CONTROLAR_PEDIDO_LIBERACAO, USA_GRADE, ');
  Consulta.SQL.Add('TIPO_GRADE_REG, INFORMA_MAT_PEDIDO, MOSTRAR_NOME_ETIQUETA, ');
  Consulta.SQL.Add('MOSTRAR_MATERIAL_PED, MOSTRAR_CFOP_PEDIDO, DIGITACAO_PED_ITENS, ');
  Consulta.SQL.Add('ID_CLIENTE_ESTOQUE, USA_LOTE, USA_POSICAO_CONSUMO, ');
  Consulta.SQL.Add('GRAVAR_INF_ADICIONAIS_NTE, USA_AMOSTRA_GRATIS, CALCULAR_PESO_CONSUMO, ');
  Consulta.SQL.Add('TIPO_REL_PEDIDO, USA_CARIMBO, MOSTRAR_MAT_LOTE, ID_CONTA_FECHAMENTO, ');
  Consulta.SQL.Add('EMPRESA_INJETADO, EMPRESA_TRANSPASS, USA_TAMANHO_AGRUPADO_NFE, ');
  Consulta.SQL.Add('EMPRESA_CARTONAGEM, USA_DTPRODUCAO, EMPRESA_NAVALHA, IMP_PRECO_PED, ');
  Consulta.SQL.Add('USA_NUM_SERIE_PROD, PERC_IPI_PADRAO, ID_NCM_PADRAO, ');
  Consulta.SQL.Add('USA_CONTA_ORCAMENTO, ID_CONTA_ORC_SERVICO, ID_CONTA_ORC_COMISSAO,');
  Consulta.SQL.Add('TIPO_LEI_TRANSPARENCIA, USA_PRECO_FORN, END_IMPRESSORA_DOS, ');
  Consulta.SQL.Add('IMP_PESO_PED, USA_EDI, ID_OPERACAO_VENDA, USA_FAIXA_SIMPLES, ');
  Consulta.SQL.Add('ESCOLA, ALTURA_ETIQ_ROT, EMPRESA_SUCATA, BAIXA_ESTOQUE_MP, ');
  Consulta.SQL.Add('VERSAO_LEIAUTE_SPED, IMP_MESANO_REF_NOITEM_NFSE, ');
  Consulta.SQL.Add('USA_LIMITE_CREDITO, SENHA_CREDITO, USA_SPED, TIPO_COMISSAO_NFSE, ');
  Consulta.SQL.Add('TIPO_COMISSAO_PROD, OBS_EXPORTACAO_EXCEL, END_SALVAR_EXCEL_EXP, ');
  Consulta.SQL.Add('USA_PEDIDO_CONTROLE_MOBRA, IMP_NFE_REF_PROD, ID_OBS_LEI_SIMPLES, ');
  Consulta.SQL.Add('PERC_JUROS_PADRAO, USA_FCI, ARREDONDAR_5, ');
  Consulta.SQL.Add('LEI_TRANSPARENCIA_IMP_ITEM, LEI_TRANSPARENCIA_TEXTO_ITEM, ');
  Consulta.SQL.Add('LEI_TRANSPARENCIA_PERC_ADIC, LEI_TRANSPARENCIA_SERVICO, ');
  Consulta.SQL.Add('USA_VALE, SENHA_EXCLUIR_VALE, IMP_MEIA_FOLHA_PED,');
  Consulta.SQL.Add('USA_PRODUTO_CLIENTE, SOMAR_PIS_COFINS_IMP, USA_CUPOM_FISCAL, ');
  Consulta.SQL.Add('ALERTA_VALE, PRODUTO_PRECO_POR_FINALIDADE, SENHA_PEDIDO, ');
  Consulta.SQL.Add('ALERTA_VLR_ATRASO, ID_CONTA_ORC_JUROS_REC, ');
  Consulta.SQL.Add('ID_CONTA_ORC_TAXA_BANCARIA_REC, ID_CONTA_ORC_DESPESA_REC, ');
  Consulta.SQL.Add('ID_CONTA_ORC_JUROS_PAG, ID_CONTA_ORC_DESPESA_PAG, TIPO_REL_OC, ');
  Consulta.SQL.Add('USA_PERC_MARGEM_RECEPCAO, USA_BOLETO_ACBR, USA_PREVISAO, ');
  Consulta.SQL.Add('USA_ENVIO_EMAIL_CATEGORIA, USA_DANFE_FLEXDOCS, USA_DESONERACAO, ');
  Consulta.SQL.Add('TIPO_REG_PRODUTO_PADRAO, TIPO_CONSULTA_PRODUTO_PADRAO, ');
  Consulta.SQL.Add('ABRIR_NFECONFIG, CADASTRA_ORGAO_PUBLICO, CONTROLAR_NOTIFICACAO, ');
  Consulta.SQL.Add('USA_RECIBO_NFSE, INFORMAR_COR_MATERIAL, NFSE_RETEN_PIS, ');
  Consulta.SQL.Add('NUMERO_SERIE_INTERNO, USA_PEDIDO_FUT, ID_OPERACAO_PED_FUT, ');
  Consulta.SQL.Add('USA_COPIA_OS_NOTA, EMPRESA_CONTABIL, ID_COND_PGTO_NFSE, ');
  Consulta.SQL.Add('IMP_TIPO_TRIBUTOS_ITENS, IMP_TIPO_TRIBUTOS, ');
  Consulta.SQL.Add('IMP_PERC_TRIB_DADOS_ADIC, IMP_PERC_TRIB_ITENS, ');
  Consulta.SQL.Add('IMP_TIPO_TRIBUTOS_SERVICO, IMP_PERC_TRIB_SERVICO, ');
  Consulta.SQL.Add('IMP_NOME_POSICAO, PROCURAR_POR_REF_XML, QTD_DIG_COD_CLI_CTB, ');
  Consulta.SQL.Add('EMPRESA_AMBIENTES, INFORMAR_COR_PROD, INV_TRAZER_QTD_ZERADA, ');
  Consulta.SQL.Add('MOSTRAR_MARCAR_PROD, MOSTRAR_LINHA_PROD, MOSTRAR_EMBALAGEM, ');
  Consulta.SQL.Add('CONTROLAR_FAT_SEPARADO, CONTROLAR_DUP_PEDIDO, ID_RESP_SUPORTE, ');
  Consulta.SQL.Add('CONTROLAR_ISSQN_RET, OBS_SIMPLES2, PERC_COMISSAO_PAGA_NOTA, ');
  Consulta.SQL.Add('USA_SETOR_CONSUMO, MOSTRAR_ATELIER_PROD, GERAR_TALAO_AUXILIAR, ');
  Consulta.SQL.Add('TIPO_ESTOQUE, USA_COD_BARRAS_PROPRIO, USA_ETIQUETA_IND, ');
  Consulta.SQL.Add('CALC_VOLUME_EMB, GERAR_ROTULO_EMB, USA_NFCE, ');
  Consulta.SQL.Add('USA_ENVIO_NOVO_NFE, OPCAO_ESCOLHER_PRECO_COR, ');
  Consulta.SQL.Add('CONTROLAR_ESTOQUE_SAIDA, SENHA_LIBERA_ESTOQUE,');
  Consulta.SQL.Add('OPCAO_REL_PED_AGRUPADO, GERAR_NUM_AUT_CONTRATO, USA_ANO_CONTRATO, ');
  Consulta.SQL.Add('USA_COPIA_PEDIDO_ITEM, USA_COPIA_OS_NFSE, USA_COPIA_PEDIDO, ');
  Consulta.SQL.Add('SOMAR_SISCOMEX_IMP, SOMAR_IPI_IMP, SOMAR_II_IMP, SOMAR_SEGURO_IMP, ');
  Consulta.SQL.Add('SOMAR_ADUANEIRA_IMP, CONTRATO_CONSUMO, USA_SERVICO_MOTOR, ');
  Consulta.SQL.Add('CONTROLAR_MENSAL_CSRF, GRAVAR_CONSUMO_NOTA, ID_ATELIER_ADEFINIR, ');
  Consulta.SQL.Add('INFORMAR_COR_MATERIAL_RZ, GRAVAR_FINANCEIRO_ATELIER, ');
  Consulta.SQL.Add('ID_CONTA_ORC_ATELIER, USA_ICMSOPERACAO_CST51, USA_PRODUTO_FORNECEDOR, ');
  Consulta.SQL.Add('USA_PRODUTO_LOCALIZACAO, MOSTRAR_TOTAL_ACUMULADO_DUP, ');
  Consulta.SQL.Add('ID_CONTA_ORC_DESCONTADA, REPETIR_ULTIMO_ITEM_PED, UNIDADE_PECA, ');
  Consulta.SQL.Add('DECISAO, EMPRESA_LIVRARIA, USA_LOCAL_ESTOQUE, FUSOHORARIO, ');
  Consulta.SQL.Add('FUSOHORARIO_VERAO, USA_APROVACAO_PED, USA_ROTULO2, ');
  Consulta.SQL.Add('USA_LOTE_CONTROLE, USA_PERC_ORGAO_PUBLICO, USA_PERC_ORGAO_PUBLICO_IMP, ');
  Consulta.SQL.Add('USA_APROVACAO_OC_FORN, ID_LOCAL_ESTOQUE_NTE, USA_ADIANTAMENTO_PEDIDO, ');
  Consulta.SQL.Add('ID_CONTA_PADRAO_ADI, ID_TIPO_COBRANCA_PADRAO_ADI, ');
  Consulta.SQL.Add('SOMAR_BASE_ICMS_SISCOMEX, CONTROLAR_SERIE_OPERACAO, ');
  Consulta.SQL.Add('MOSTRAR_END_ENTREGA_DADOS_ADI, MSG_PADRAO_NOTA, ALERTA_FRETE_DEST, ');
  Consulta.SQL.Add('USA_OBS_PEDIDO_NOTA, ID_LOCAL_ESTOQUE_PROD, EMPRESA_CAMABOX ');
  Consulta.SQL.Add('from PARAMETROS WHERE 0=0');
  for i := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
      Consulta.SQL.Add(' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
  end;

  Consulta.Open;
  Result := Consulta;
end;

function TDMPrincipal.Abrir_Tabela_Produto(Conexao: TEnumConexao): TFDQuery;
var
  Consulta: TFDQuery;
  Condicao: String;
  i: Integer;
begin
  Condicao := '';
  Consulta := TFDQuery.Create(Self);
  case Conexao of
    tpLocal:
      Consulta.Connection := FDLocal;
    tpServer:
      Consulta.Connection := FDServer;
  end;
  Consulta.Close;
  Consulta.SQL.Clear;
  Consulta.SQL.Add('SELECT P.ID, P.NOME, P.REFERENCIA, ');
  Consulta.SQL.Add('P.PRECO_VENDA, P.TIPO_REG, P.ESTOQUE, P.INATIVO, ');
  Consulta.SQL.Add('P.COMPLEMENTO, P.ID_NCM, P.ORIGEM_PROD, ');
  Consulta.SQL.Add('P.PERC_REDUCAOICMS, P.TIPO_VENDA, P.PERC_MARGEMLUCRO, ');
  Consulta.SQL.Add('P.UNIDADE, P.ID_GRUPO, P.ID_MARCA, ');
  Consulta.SQL.Add('P.ID_FORNECEDOR, P.COD_BARRA, P.USA_GRADE, ');
  Consulta.SQL.Add('P.PERC_PIS, P.PERC_COFINS, P.NCM_EX, P.FOTO, ');
  Consulta.SQL.Add('P.ID_CFOP_NFCE, P.USA_PRECO_COR, P.USA_COR, ');
  Consulta.SQL.Add('P.PRECO_CUSTO_TOTAL, P.PERC_COMISSAO, P.LANCA_LOTE_CONTROLE, ');
  Consulta.SQL.Add('P.COD_CEST, P.FILIAL, P.QTD_EMBALAGEM, ');
  Consulta.SQL.Add('P.USA_NA_BALANCA, P.PERC_DESC_MAX, ');
  Consulta.SQL.Add('P.ID_CSTICMS_BRED, P.PRECO_LIQ, P.QTD_PECA_EMB, ');
  Consulta.SQL.Add('P.COD_BARRA2, P.ID_CSTICMS, P.PERC_ICMS_NFCE, ');
  Consulta.SQL.Add('P.PRECO_CUSTO_ANT, P.COD_BENEF, P.ID_PRODUTO_EST, ');
  Consulta.SQL.Add('P.PRECO_VAREJO, P.TIPO_BALANCA, P.CODIGO_BALANCA, ');
  Consulta.SQL.Add('P.PERC_ICMS, P.UNIDADE_TRIB, P.ID_CSTPIS, ');
  Consulta.SQL.Add('P.ID_CSTCOFINS, P.COD_NATUREZA, P.CONFERIDO, ');
  Consulta.SQL.Add('P.PERC_MARGEMLUCRO_PADRAO, P.VLR_ICMS, ');
  Consulta.SQL.Add('P.ID_CSTPIS_SIMPLES, P.ID_CSTCOFINS_SIMPLES');
  Consulta.SQL.Add(' FROM PRODUTO P WHERE 0=0 ');
  for i := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
      Consulta.SQL.Add(' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
  end;

  Consulta.Open;
  Result := Consulta;
end;

procedure TDMPrincipal.AdicionaDados(aValue, aCampo: String; Clear: boolean = True);
var
  i: Integer;
begin
  if Clear then
    ListaDados.Clear;
  ListaDados.Add(TCampos.Create);
  i := ListaDados.Count - 1;
  ListaDados[i].Campo := aValue;
  ListaDados[i].Valor := aCampo;
end;

function TDMPrincipal.Abrir_Tabela(Conexao: TEnumConexao): TFDQuery;
var
  Consulta: TFDQuery;
  Condicao: String;
  i: Integer;
begin
  Condicao := '';
  Consulta := TFDQuery.Create(Self);
  case Conexao of
    tpLocal:
      Consulta.Connection := FDLocal;
    tpServer:
      Consulta.Connection := FDServer;
  end;
  Consulta.Close;
  Consulta.SQL.Clear;
  Consulta.SQL.Add('SELECT * FROM ' + vTabela + ' WHERE 0=0 ');
  for i := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
      Consulta.SQL.Add(' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
  end;
  Consulta.Open;
  Result := Consulta;
end;

function TDMPrincipal.conectar: boolean;
begin
  FDLocal.Connected := False;
  try
    FDLocal.Connected := True;
    Result := True;
  except
    FDLocal.Connected := False;
    Result := False;
  end;

  FDServer.Connected := False;
  try
    FDServer.Connected := True;
    Result := True;
  except
    FDServer.Connected := False;
    Result := False;
  end;
end;

procedure TDMPrincipal.DataModuleCreate(Sender: TObject);
begin
  ListaTipo := TStringList.Create;
  ListaDados := TObjectList<TCampos>.Create;
end;

procedure TDMPrincipal.DataModuleDestroy(Sender: TObject);
begin
  ListaTipo.Free;
  ListaDados.Free;
end;

function TDMPrincipal.desconectar: boolean;
begin
  FDLocal.Connected := False;
  FDServer.Connected := False;
end;

end.
