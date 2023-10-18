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
