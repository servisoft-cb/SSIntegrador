unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  JvComponentBase, JvThreadTimer, Vcl.AppEvnts, IniFiles, IdCoderMIME,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
  FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, uDMPrincipal, TrataException,
  Vcl.Buttons;

type
  TfrmPrincipal = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    JvThreadTimer: TJvThreadTimer;
    PopupMenu1: TPopupMenu;
    pnlPrincipal: TPanel;
    lblTerminal: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lblStatus: TLabel;
    lblLocal: TLabel;
    lblServidor: TLabel;
    lblUltimaAtualizacao: TLabel;
    shpLocal: TShape;
    shpServidor: TShape;
    TrayIcon: TTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure JvThreadTimerTimer(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    vTerminal : String;
    vTempoCiclo : integer;
    fDMPrincipal : TDMPrincipal;
    function conectar : boolean;
    function desconectar : boolean;
    function ImportaServidorTabelaProduto: boolean;
    function ApagaRegistrosExcluidosNoServidor: boolean;
    function ExportaMovimentosPDV: boolean;
    function ExcluirRegistroServidor : boolean;
    procedure AtualizaStatus (aValue : String);
    procedure Abrir_Consulta_Local(Tabela : String; Condicao : String = '0=1');
    procedure Abrir_Consulta_Servidor(Tabela : String; Condicao : String = '0=1');
    procedure Abrir_Tabela_Servidor(Tabela : String; Condicao : String = '0=1');
    procedure Abrir_Tabela_Local(Tabela : String; Condicao : String = '0=1');
    procedure Apaga_Registro(Conexao : TFDConnection; Tabela : String; TestaTerminal : Boolean; Condicao : String = '0=1');
    procedure GravaLogErro(Erro : String);
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

procedure TfrmPrincipal.Abrir_Consulta_Local(Tabela : String; Condicao : String= '0=1');
begin
  fDMPrincipal.qryConsultaLocal.Close;
  fDMPrincipal.qryConsultaLocal.SQL.Clear;
  fDMPrincipal.qryConsultaLocal.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  fDMPrincipal.qryConsultaLocal.Open;
  fDMPrincipal.qryConsultaLocal.First;
end;

procedure TfrmPrincipal.Abrir_Consulta_Servidor(Tabela : String; Condicao : String = '0=1');
begin
  fDMPrincipal.qryConsultaServidor.Close;
  fDMPrincipal.qryConsultaServidor.SQL.Clear;
  fDMPrincipal.qryConsultaServidor.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  fDMPrincipal.qryConsultaServidor.Open;
  fDMPrincipal.qryConsultaServidor.First;
end;

procedure TfrmPrincipal.Abrir_Tabela_Local(Tabela, Condicao: String);
begin
  fDMPrincipal.qryConsultaTabelaLocal.Close;
  fDMPrincipal.qryConsultaTabelaLocal.SQL.Clear;
  fDMPrincipal.qryConsultaTabelaLocal.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  fDMPrincipal.qryConsultaTabelaLocal.Open;
end;

procedure TfrmPrincipal.Abrir_Tabela_Servidor(Tabela, Condicao: String);
begin
  fDMPrincipal.qryConsultaTabelaServer.Close;
  fDMPrincipal.qryConsultaTabelaServer.SQL.Clear;
  fDMPrincipal.qryConsultaTabelaServer.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  fDMPrincipal.qryConsultaTabelaServer.Open;
end;

function TfrmPrincipal.ApagaRegistrosExcluidosNoServidor: boolean;
var
  vTabela, vCondicao : String;
begin
  {$region 'Clientes'}
  AtualizaStatus('Verificando Exclusões de Clientes!');
  vTabela := 'PESSOA_LOG';
  vCondicao := 'Tipo = ''2'' and ID_TERMINAL = ' + vTerminal;
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Excluindo Cliente => ' + FieldByName('ID_PESSOA').AsString);
      vCondicao := 'codigo = ' + FieldByName('ID_PESSOA').AsString;
      vTabela := 'PESSOA';
      Apaga_Registro(fDMPrincipal.FDLocal, vTabela, false, vCondicao);
      vTabela := 'PESSOA_LOG';
      vCondicao := ' and id_pessoa = ' + FieldByName('ID_PESSOA').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, true, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Lista Preço'}
  AtualizaStatus('Verificando Exclusões de Lista de Preço!');
  vTabela := 'TAB_PRECO_LOG';
  vCondicao := 'Tipo = ''2'' and ID_TERMINAL = ' + vTerminal;
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Excluindo Lista de Preço => ' + FieldByName('ID_TABPRECO').AsString);

      vCondicao := 'ID = ' + FieldByName('ID_TABPRECO').AsString; 
      vTabela := 'TAB_PRECO_ITENS';
      Apaga_Registro(fDMPrincipal.FDLocal, vTabela, False, vCondicao);

      vCondicao := 'ID = ' + FieldByName('ID_TABPRECO').AsString; 
      vTabela := 'TAB_PRECO';
      Apaga_Registro(fDMPrincipal.FDLocal,vTabela,False, vCondicao);
      
      vTabela := 'TAB_PRECO_LOG';
      vCondicao := ' and ID_TABPRECO = ' + FieldByName('ID_TABPRECO').AsString;
      Apaga_Registro(fDMPrincipal.FDServer, vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Produtos'}
  AtualizaStatus('Verificando Exclusões de Produtos!');
  vTabela := 'PRODUTO_LOG';
  vCondicao := 'TIPO = ''2'' and ID_TERMINAL = ' + vTerminal;
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Excluindo Produto => ' + FieldByName('ID_PRODUTO').AsString);
      vCondicao := 'ID = ' + FieldByName('ID_PRODUTO').AsString; 
      vTabela := 'PRODUTO';
      Apaga_Registro(fDMPrincipal.FDLocal,vTabela, False, vCondicao);
      vTabela := 'PRODUTO_LOG';
      vCondicao := ' and ID_PRODUTO = ' + FieldByName('ID_PRODUTO').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

end;

procedure TfrmPrincipal.Apaga_Registro(conexao : TFDConnection; Tabela : String; TestaTerminal : Boolean; Condicao : String = '0=1');
var
  qry : TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  try
    qry.Connection := Conexao;
    qry.Close;
    qry.SQL.Clear;
    qry.SQL.Add('delete from ' + Tabela + ' where' );
    if TestaTerminal then
       qry.SQL.Add(' ID_TERMINAL = ' + vTerminal);
    qry.SQL.Add(' ' + Condicao);
    try
      qry.ExecSQL;
    except
      on E : Exception do
      begin
        GravaLogErro(e.Message + ' - ' + qry.SQL.Text);
      end;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmPrincipal.ApplicationEvents1Minimize(Sender: TObject);
begin
  Self.Hide();
  Self.WindowState := wsMinimized;
  TrayIcon.Visible := True;
  TrayIcon.Animate := True;
  TrayIcon.ShowBalloonHint;
end;

procedure TfrmPrincipal.AtualizaStatus(aValue: String);
begin
  Application.Title := aValue;
  lblStatus.Caption := Application.Title;
  lblStatus.Update;
end;

function TfrmPrincipal.conectar: boolean;
begin
  fDMPrincipal.FDLocal.Connected := False;
  try
    Application.Title := 'Conectando no Banco Local...';
    lblStatus.Caption := 'Conectando no Banco Local...';
    lblStatus.Update;
    fDMPrincipal.FDLocal.Connected := True;
    Application.ProcessMessages;
    Result := True;
    shpLocal.Brush.Color := clLime;
  except
    Application.Title := 'Falha de Conexão Banco Local...';
    lblStatus.Caption := 'Falha de Conexão Banco Local...';
    lblStatus.Update;
    fDMPrincipal.FDLocal.Connected := False;
    Application.ProcessMessages;
    Result := False;
    shpLocal.Brush.Color := clRed;
  end;
  fDMPrincipal.FDServer.Connected := False;
  try
    Application.Title := 'Conectando no Banco Servidor...';
    lblStatus.Caption := 'Conectando no Banco Servidor...';
    lblStatus.Update;
    fDMPrincipal.FDServer.Connected := True;
    Application.ProcessMessages;
    Result := True;
    shpServidor.Brush.Color := clLime;
  except
    Application.Title := 'Falha de Conexão Banco Servidor...';
    lblStatus.Caption := 'Falha de Conexão Banco Servidor...';
    lblStatus.Update;
    fDMPrincipal.FDServer.Connected := False;
    Application.ProcessMessages;
    Result := False;
    shpServidor.Brush.Color := clRed;
  end;
end;

function TfrmPrincipal.desconectar: boolean;
begin
  try
    Application.Title := 'Desconectando do Servidor...';
    lblStatus.Caption := 'Desconectando do Servidor...';
    lblStatus.Update;
    fDMPrincipal.FDLocal.Connected := False;
    fDMPrincipal.FDServer.Connected := False;
    Application.ProcessMessages;
  except
    Application.ProcessMessages;
  end;
end;

function TfrmPrincipal.ExcluirRegistroServidor: boolean;
var
  vCondicao, vTabela : String;
  vNumCupom, vFilial : integer;
  vTipo : String;
begin
  {$Region 'Exclui CupomFiscal'}
  AtualizaStatus('Excluindo Cupom Fiscal');
  vTabela := 'CUPOMFISCAL_LOG';
  vCondicao := 'Tipo = ''2'' and ID_TERMINAL = ' + vTerminal;
  vCondicao := vCondicao + ' order by ID_TERMINAL';
  Abrir_Consulta_Local(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaLocal do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      vNumCupom := FieldByName('NumCupom').AsInteger;
      vFilial := FieldByName('Filial').AsInteger;
      vTipo := FieldByName('Tipo').AsString;

      vCondicao := ' where Numcupom = ' + IntToStr(vNumCupom);
      vCondicao := vCondicao + ' and filial = ' + IntToStr(vFilial);
      vCondicao := vCondicao + ' and Terminal_ID = ' + vTerminal;
      vCondicao := vCondicao + ' and Tipo = ' + vTipo;

      try
        fDMPrincipal.FDServer.ExecSQL('DELETE FROM CUPOMFISCAL ' + vCondicao);
      except
        on E : Exception do
        begin
          GravaLogErro('Erro Excluindo Cupom Fiscal nº: ' + IntToStr(vNumCupom));
        end;
      end;

    end;
  end;
  {$endRegion}
end;

function TfrmPrincipal.ExportaMovimentosPDV: boolean;
var
  vCondicao, vTabela : string;
  i : integer;
  erro : Boolean;
  vIDNovo : Integer;
  Prazo : String;
begin
  {$region 'Cupom Fiscal'}
  AtualizaStatus('Verificando Cupom Fiscal');
  vTabela := 'CUPOMFISCAL_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal;
  vCondicao := vCondicao + ' order by ID_TERMINAL';
  Abrir_Consulta_Local(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaLocal do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Cupom Fiscal => ' + FieldByName('ID').AsString);

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL';
      Abrir_Tabela_Local(vTabela, vCondicao);

      vCondicao := 'ID = -1 '; //+ FieldByName('ID_CUPOM').AsString;
      vTabela := 'CUPOMFISCAL';
      Abrir_Consulta_Servidor(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaServidor.IsEmpty then
        fDMPrincipal.qryConsultaServidor.Insert
      else
        fDMPrincipal.qryConsultaServidor.Edit;

      for I := 0 to fDMPrincipal.qryConsultaTabelaLocal.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaServidor.FindField(fDMPrincipal.qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaLocal.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        vIDNovo := fDMPrincipal.FDServer.ExecSQLScalar('select gen_id(GEN_CUPOMFISCAL,1) from rdb$database');
        fDMPrincipal.qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
        fDMPrincipal.qryConsultaServidor.Post;
        fDMPrincipal.qryConsultaServidor.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaServidor.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar itens
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_ITENS';
      Abrir_Tabela_Local(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaLocal.First;
      while not fDMPrincipal.qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
//        vCondicao := 'ID = ' + qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vCondicao := '0 = 1 ';
        vTabela := 'CUPOMFISCAL_ITENS';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaServidor.IsEmpty then
          fDMPrincipal.qryConsultaServidor.Insert
        else
          fDMPrincipal.qryConsultaServidor.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaServidor.FindField(fDMPrincipal.qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          fDMPrincipal.qryConsultaServidor.FieldByName('id_movimento').Clear;
          fDMPrincipal.qryConsultaServidor.Post;
          fDMPrincipal.qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaLocal.Next;
      end;

      //Gravar itens sem
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_ITENS_SEM';
      Abrir_Tabela_Local(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaLocal.First;
      while not fDMPrincipal.qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vTabela := 'CUPOMFISCAL_ITENS_SEM';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaServidor.IsEmpty then
          fDMPrincipal.qryConsultaServidor.Insert
        else
          fDMPrincipal.qryConsultaServidor.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaServidor.FindField(fDMPrincipal.qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          fDMPrincipal.qryConsultaServidor.Post;
          fDMPrincipal.qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaLocal.Next;
      end;

      //Gravar cupom parc
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_PARC';
      Abrir_Tabela_Local(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaLocal.First;
      while not fDMPrincipal.qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND PARCELA = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('PARCELA').AsString;
        vTabela := 'CUPOMFISCAL_PARC';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaServidor.IsEmpty then
          fDMPrincipal.qryConsultaServidor.Insert
        else
          fDMPrincipal.qryConsultaServidor.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaServidor.FindField(fDMPrincipal.qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          fDMPrincipal.qryConsultaServidor.FieldByName('id_duplicata').Clear;
          fDMPrincipal.qryConsultaServidor.Post;
          fDMPrincipal.qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaLocal.Next;
      end;

      //Gravar cupom troca
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_TROCA';
      Abrir_Tabela_Local(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaLocal.First;
      while not fDMPrincipal.qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vTabela := 'CUPOMFISCAL_TROCA';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaServidor.IsEmpty then
          fDMPrincipal.qryConsultaServidor.Insert
        else
          fDMPrincipal.qryConsultaServidor.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaServidor.FindField(fDMPrincipal.qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          fDMPrincipal.qryConsultaServidor.Post;
          fDMPrincipal.qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaLocal.Next;
      end;


      //Gravar Cupom Fiscal FormaPagto
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_FORMAPGTO';
      Abrir_Tabela_Local(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaLocal.First;
      while not fDMPrincipal.qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + fDMPrincipal.qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vTabela := 'CUPOMFISCAL_FORMAPGTO';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaServidor.IsEmpty then
          fDMPrincipal.qryConsultaServidor.Insert
        else
          fDMPrincipal.qryConsultaServidor.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaServidor.FindField(fDMPrincipal.qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          fDMPrincipal.qryConsultaServidor.Post;
          fDMPrincipal.qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaLocal.Next;
      end;

      //Gravar Estoque
      try
        fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_ESTOQUE('+ IntToStr(vIDNovo) + ', ''CFI'')');
      except
        GravaLogErro('Erro Gravando Movimento estoque nº: ' + IntToStr(vIDNovo));
      end;

      //Gravar Duplicata - Histórico - Comissão - Financeiro
      try
        fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_DUPLICATA_CUPOM('+ QuotedStr('')+ ', ' + IntToStr(vIDNovo) + ', ' + vTerminal + ')');
      except
        on E : Exception do
        begin
        GravaLogErro('Erro Gravando Duplicata estoque nº: ' + IntToStr(vIDNovo));
        end;
      end;


      vTabela := 'CUPOMFISCAL_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDLocal,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

end;

function TfrmPrincipal.ImportaServidorTabelaProduto: boolean;
var
  erro, gravou : boolean;
  vCondicao, vTabela : String;
  i : integer;
begin

  {$region 'Inclui/Altera Clientes'}
  AtualizaStatus('Verificando Alterações em Clientes');
  vTabela := 'PESSOA_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Cliente => ' + FieldByName('ID').AsString);
      vCondicao := 'codigo = ' + FieldByName('ID').AsString;
      vTabela := 'PESSOA';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      vCondicao := 'codigo = ' + FieldByName('ID').AsString;
      vTabela := 'PESSOA';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      vTabela := 'PESSOA_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera NCM'} 
  AtualizaStatus('Verificando Alterações em NCM');
  vTabela := 'TAB_NCM_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo NCM => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_NCM';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_NCM';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      vTabela := 'TAB_NCM_LOG';
      vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Unidade'}
  AtualizaStatus('Verificando Alterações em Unidades');

  vTabela := 'UNIDADE';
  vCondicao := ' 0=0 order by UNIDADE';
  Abrir_Tabela_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaTabelaServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Unidade => ' + FieldByName('UNIDADE').AsString);
      vCondicao := 'UNIDADE = ' + QuotedStr(FieldByName('UNIDADE').AsString); 
      vTabela := 'UNIDADE';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Grupo'}
  AtualizaStatus('Verificando Alterações em Grupos');
  vTabela := 'GRUPO';
  vCondicao := ' 0=0 order by ID';
  Abrir_Tabela_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaTabelaServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Grupos => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + QuotedStr(FieldByName('ID').AsString);
      vTabela := 'GRUPO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Produto'} 
  AtualizaStatus('Verificando Alterações em Produtos');
  vTabela := 'PRODUTO_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Produtos => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + QuotedStr(FieldByName('ID').AsString);
      vTabela := 'PRODUTO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'PRODUTO';
      Abrir_Tabela_Servidor(vTabela, vCondicao);

      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      vTabela := 'PRODUTO_LOG';
      vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Tabela de Preço'}
  AtualizaStatus('Verificando Alterações em Tabela de Preço');
  vTabela := 'TAB_PRECO_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Tabela de Preço => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_PRECO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_PRECO';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar itens

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_PRECO_ITENS';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaServer.First;
      while not fDMPrincipal.qryConsultaTabelaServer.Eof do
      begin
        AtualizaStatus('Recebendo Itens Tabela de Preço => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaServer.FieldByName('ID').AsString + 'AND ITEM = ' + fDMPrincipal.qryConsultaTabelaServer.FieldByName('ITEM').AsString;
        vTabela := 'TAB_PRECO_ITENS';
        Abrir_Consulta_Local(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaLocal.IsEmpty then
          fDMPrincipal.qryConsultaLocal.Insert
        else
          fDMPrincipal.qryConsultaLocal.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaLocal.Post;
          fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaServer.Next;
      end;

      vTabela := 'TAB_PRECO_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Condição de Pagamento'}
  AtualizaStatus('Verificando Alterações em Condição de Pagamento');
  vTabela := 'CONDPGTO_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Condições de Pagto => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CONDPGTO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CONDPGTO';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar itens

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CONDPGTO_DIA';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaServer.First;
      while not fDMPrincipal.qryConsultaTabelaServer.Eof do
      begin
        AtualizaStatus('Recebendo Itens Condições de Pagto => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaServer.FieldByName('ID').AsString + 'AND ITEM = ' + fDMPrincipal.qryConsultaTabelaServer.FieldByName('ITEM').AsString;
        vTabela := 'CONDPGTO_DIA';
        Abrir_Consulta_Local(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaLocal.IsEmpty then
          fDMPrincipal.qryConsultaLocal.Insert
        else
          fDMPrincipal.qryConsultaLocal.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaLocal.Post;
          fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaServer.Next;
      end;

      vTabela := 'CONDPGTO_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Parametros'}
  AtualizaStatus('Verificando Alterações Parâmetros');
  vTabela := 'PARAMETROS_LOG';
  vCondicao := 'Tipo <> ''2'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with fDMPrincipal.qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Parâmetros => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'PARAMETROS';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if fDMPrincipal.qryConsultaLocal.IsEmpty then
        fDMPrincipal.qryConsultaLocal.Insert
      else
        fDMPrincipal.qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'PARAMETROS';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        fDMPrincipal.qryConsultaLocal.Post;
        fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        fDMPrincipal.qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar Parametros Financeiro

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'PARAMETROS_FIN';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      fDMPrincipal.qryConsultaTabelaServer.First;
      while not fDMPrincipal.qryConsultaTabelaServer.Eof do
      begin
        AtualizaStatus('Recebendo Parâmetros Financeiro => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + fDMPrincipal.qryConsultaTabelaServer.FieldByName('ID').AsString;
        vTabela := 'PARAMETROS_FIN';
        Abrir_Consulta_Local(vTabela, vCondicao);
        if fDMPrincipal.qryConsultaLocal.IsEmpty then
          fDMPrincipal.qryConsultaLocal.Insert
        else
          fDMPrincipal.qryConsultaLocal.Edit;

        for I := 0 to fDMPrincipal.qryConsultaTabelaServer.FieldCount - 1 do
        begin
          try
            fDMPrincipal.qryConsultaLocal.FindField(fDMPrincipal.qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
               fDMPrincipal.qryConsultaTabelaServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          fDMPrincipal.qryConsultaLocal.Post;
          fDMPrincipal.qryConsultaLocal.ApplyUpdates(0);
          erro := False;
        except
          fDMPrincipal.qryConsultaLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        fDMPrincipal.qryConsultaTabelaServer.Next;
      end;

      vTabela := 'PARAMETROS_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  fDMPrincipal.Free;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
var
  ArquivoIni : String;
  BaseLocal, DriverName, UserName, PassWord : String;
  BaseServer, DriverNameServer, UserNameServer, PassWordServer, IP : String;
  Local : Integer;
  Configuracoes : TIniFile;
  Decoder64: TIdDecoderMIME;
  Encoder64: TIdEncoderMIME;
begin
  fDMPrincipal := TDMPrincipal.Create(nil);
  lblUltimaAtualizacao.Caption := 'Aguardando configurações';
  top := Screen.Height - Height - 50;
  left := Screen.Width - Width;
  Decoder64 := TIdDecoderMIME.Create(nil);
  ArquivoIni := ExtractFilePath(Application.ExeName) + '\Config.ini';
  if not FileExists(ArquivoIni) then
  begin
    MessageDlg('Arquivo config.ini não encontrado!', mtInformation,[mbOK],0);
    Exit;
  end;
  Configuracoes := TIniFile.Create(ArquivoINI);
  try
    BaseLocal := Configuracoes.ReadString('SSFacil', 'DATABASE', '');
    DriverName := Configuracoes.ReadString('SSFacil', 'DriverName', '');
    UserName   := Configuracoes.ReadString('SSFacil', 'UserName',   '');
    PassWord   := Decoder64.DecodeString(Configuracoes.ReadString('SSFacil', 'PASSWORD', ''));

    BaseServer := Configuracoes.ReadString('SSFacil_Servidor', 'DATABASE', '');
    DriverNameServer := Configuracoes.ReadString('SSFacil_Servidor', 'DriverName', '');
    UserNameServer   := Configuracoes.ReadString('SSFacil_Servidor', 'UserName', '');
    IP := Configuracoes.ReadString('SSFacil_Servidor','IP','');
    PassWordServer   := Decoder64.DecodeString(Configuracoes.ReadString('SSFacil_Servidor', 'PASSWORD', ''));
    vTerminal := Configuracoes.ReadString('SSFacil_Servidor', 'Terminal', '');
    vTempoCiclo := StrToInt(Configuracoes.ReadString('SSFacil_Servidor', 'TempoCiclo', '20000'));
  finally
    Configuracoes.Free;
    Decoder64.Free;
  end;

  fDMPrincipal.FDLocal.Connected := False;
  fDMPrincipal.FDLocal.Params.Clear;
  fDMPrincipal.FDLocal.DriverName := 'FB';
  fDMPrincipal.FDLocal.Params.Values['DriveId'] := 'FB';
  fDMPrincipal.FDLocal.Params.Values['DataBase'] := BaseLocal;
  fDMPrincipal.FDLocal.Params.Values['User_Name'] := UserName;
  fDMPrincipal.FDLocal.Params.Values['Password'] := PassWord;

  fDMPrincipal.FDServer.Connected := False;
  fDMPrincipal.FDServer.Params.Clear;
  fDMPrincipal.FDServer.DriverName := 'FB';
  fDMPrincipal.FDServer.Params.Values['DriveId'] := 'FB';
  fDMPrincipal.FDServer.Params.Values['DataBase'] := BaseServer;
  fDMPrincipal.FDServer.Params.Values['Server'] := IP;
  fDMPrincipal.FDServer.Params.Values['User_Name'] := UserNameServer;
  fDMPrincipal.FDServer.Params.Values['Password'] := PassWordServer;

  JvThreadTimer.Interval := vTempoCiclo;
  lblTerminal.Caption := 'Terminal: ' + vTerminal;
  lblLocal.caption := BaseLocal;
  lblLocal.Update;
  lblServidor.caption := IP + ':' + BaseServer;
  lblServidor.Update;
end;

procedure TfrmPrincipal.GravaLogErro(Erro: String);
const
  Arquivo = 'c:\$Servisoft\Log_Integracao.txt';
var
  vLog: TextFile;
begin
  try
    AssignFile(vLog,Arquivo);
    if not FileExists(Arquivo) then
      Rewrite(vLog,Arquivo);
    Append(vLog);
    Writeln(vLog, DateTimeToStr(Now));
    Writeln(vLog, Erro);
    Writeln(vLog, '=======================================');
  finally
    CloseFile(vLog);
  end;
end;

procedure TfrmPrincipal.JvThreadTimerTimer(Sender: TObject);
begin
  TrayIcon.Animate := True;
  JvThreadTimer.Enabled := False;
  if conectar then
  begin
    try
      ApagaRegistrosExcluidosNoServidor;
    except
      Application.ProcessMessages;
    end;

    try
      ImportaServidorTabelaProduto;
    except
      Application.ProcessMessages;
    end;

    try
      ExportaMovimentosPDV;
    except
      Application.ProcessMessages;
    end;

    Desconectar;
  end;
  Application.Title := 'Aguardando Proximo Ciclo';
  lblStatus.Caption := 'Aguardando Proximo Ciclo';
  lblStatus.Update;
  lblUltimaAtualizacao.Caption := FormatDateTime('dd/mm/yyyy - hh:mm:ss ',Now);
  Application.ProcessMessages;
  TrayIcon.Animate := False;
  JvThreadTimer.Enabled := True;
end;

procedure TfrmPrincipal.TrayIconDblClick(Sender: TObject);
begin
  TrayIcon.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

end.
