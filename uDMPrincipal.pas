unit uDMPrincipal;

interface

uses
  System.SysUtils, System.Classes, Classe.Campos, System.Generics.Collections,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client;

type
  TEnumConexao = (tpLocal, tpServer);

type
  TDMPrincipal = class(TDataModule)
    FDLocal: TFDConnection;
    FDServer: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    vTabela : String;
    vCondicao : String;
    vTerminal : String;
    ListaTipo : TStringList;
    ListaDados : TObjectList<TCampos>;
    function conectar : boolean;
    function desconectar : boolean;

    function Abrir_Tabela_Log(Conexao : TEnumConexao) : TFDQuery;
    function Abrir_Tabela(Conexao: TEnumConexao) : TFDQuery;
    procedure AdicionaDados(aValue, aCampo : String; Clear : Boolean = True);

    { Public declarations }
  end;

var
  DMPrincipal: TDMPrincipal;

implementation

uses
  Vcl.Dialogs;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TDMPrincipal }

function TDMPrincipal.Abrir_Tabela_Log(Conexao : TEnumConexao) : TFDQuery;
var
  Consulta : TFDQuery;
  i : integer;
  Condicao : String;
begin
  Condicao := '';
  for i := 0 to ListaTipo.Count -1 do
  begin
    if i = 0 then
      Condicao := QuotedStr(ListaTipo.Strings[i])
    else
      Condicao := Condicao + ',' + QuotedStr(ListaTipo.Strings[i]);
  end;
  Consulta := TFDQuery.Create(nil);
  try
    case Conexao of
     tpLocal : Consulta.Connection := FDLocal;
     tpServer : Consulta.Connection := FDServer;
    end;
    Consulta.Close;
    Consulta.SQL.Clear;
    Consulta.SQL.Add('SELECT * FROM ' + vTabela + ' WHERE TIPO in ( '  +  Condicao + ')') ;
    Consulta.SQL.Add(' and id_terminal = ' + vTerminal);
    Consulta.Open;
    Result := Consulta;
  finally

  end;
end;

procedure TDMPrincipal.AdicionaDados(aValue, aCampo: String; Clear : Boolean = True);
var
  i : integer;
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
  Consulta : TFDQuery;
  Condicao : String;
  i : Integer;
begin
  Condicao := '';
  Consulta := TFDQuery.Create(nil);
  case Conexao of
   tpLocal : Consulta.Connection := FDLocal;
   tpServer : Consulta.Connection := FDServer;
  end;
  Consulta.Close;
  Consulta.SQL.Clear;
  Consulta.SQL.Add('SELECT * FROM ' + vTabela + ' WHERE 0=0 ');
  for I := 0 to Pred(ListaDados.Count) do
  begin
    if ListaDados[i].Campo <> EmptyStr then
       Consulta.SQL.Add( ' AND ' + ListaDados[i].Campo + ' = ' + ListaDados[i].Valor);
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
