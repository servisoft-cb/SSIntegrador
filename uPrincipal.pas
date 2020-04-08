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
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet;

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
    FDLocal: TFDConnection;
    FDServer: TFDConnection;
    shpLocal: TShape;
    shpServidor: TShape;
    TrayIcon: TTrayIcon;
    qryConsultaLocal: TFDQuery;
    qryConsultaServidor: TFDQuery;
    qryLocalUpdate: TFDQuery;
    qryServerUpdate: TFDQuery;
    qryApagaLocal: TFDQuery;
    qryApagaServer: TFDQuery;
    qryConsultaTabelaServer: TFDQuery;
    qryConsultaTabelaLocal: TFDQuery;
    procedure FormCreate(Sender: TObject);
    procedure JvThreadTimerTimer(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private
    { Private declarations }
    vTerminal : String;
    vTempoCiclo : integer;
    function conectar : boolean;
    function desconectar : boolean;
    function ImportaServidorTabelaProduto: boolean;
    function ApagaRegistrosExcluidosNoServidor: boolean;
    function ExportaMovimentosPDV: boolean;
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
  qryConsultaLocal.Close;
  qryConsultaLocal.SQL.Clear;
  qryConsultaLocal.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  qryConsultaLocal.Open;
  qryConsultaLocal.First;
end;

procedure TfrmPrincipal.Abrir_Consulta_Servidor(Tabela : String; Condicao : String = '0=1');
begin
  qryConsultaServidor.Close;
  qryConsultaServidor.SQL.Clear;
  qryConsultaServidor.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  qryConsultaServidor.Open;
  qryConsultaServidor.First;
end;

procedure TfrmPrincipal.Abrir_Tabela_Local(Tabela, Condicao: String);
begin
  qryConsultaTabelaLocal.Close;
  qryConsultaTabelaLocal.SQL.Clear;
  qryConsultaTabelaLocal.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  qryConsultaTabelaLocal.Open;
end;

procedure TfrmPrincipal.Abrir_Tabela_Servidor(Tabela, Condicao: String);
begin
  qryConsultaTabelaServer.Close;
  qryConsultaTabelaServer.SQL.Clear;
  qryConsultaTabelaServer.SQL.Add('SELECT * FROM ' + Tabela + ' WHERE ' + Condicao);
  qryConsultaTabelaServer.Open;
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
  with qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Excluindo Cliente => ' + FieldByName('ID_PESSOA').AsString);
      vCondicao := 'codigo = ' + FieldByName('ID_PESSOA').AsString; 
      vTabela := 'PESSOA';
      Apaga_Registro(FDLocal, vTabela, false, vCondicao);
      vTabela := 'PESSOA_LOG';
      vCondicao := ' and id_pessoa = ' + FieldByName('ID_PESSOA').AsString;
      Apaga_Registro(FDServer,vTabela, true, vCondicao);
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
  with qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Excluindo Lista de Preço => ' + FieldByName('ID_TABPRECO').AsString);

      vCondicao := 'ID = ' + FieldByName('ID_TABPRECO').AsString; 
      vTabela := 'TAB_PRECO_ITENS';
      Apaga_Registro(FDLocal, vTabela, False, vCondicao);

      vCondicao := 'ID = ' + FieldByName('ID_TABPRECO').AsString; 
      vTabela := 'TAB_PRECO';
      Apaga_Registro(FDLocal,vTabela,False, vCondicao);
      
      vTabela := 'TAB_PRECO_LOG';
      vCondicao := ' and ID_TABPRECO = ' + FieldByName('ID_TABPRECO').AsString;
      Apaga_Registro(FDServer, vTabela, True, vCondicao);
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
  with qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Excluindo Produto => ' + FieldByName('ID_PRODUTO').AsString);
      vCondicao := 'ID = ' + FieldByName('ID_PRODUTO').AsString; 
      vTabela := 'PRODUTO';
      Apaga_Registro(FDLocal,vTabela, False, vCondicao);
      vTabela := 'PRODUTO_LOG';
      vCondicao := ' and ID_PRODUTO = ' + FieldByName('ID_PRODUTO').AsString;
      Apaga_Registro(FDServer,vTabela, True, vCondicao);
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
  FDLocal.Connected := False;
  try
    Application.Title := 'Conectando no Banco Local...';
    lblStatus.Caption := 'Conectando no Banco Local...';
    lblStatus.Update;
    FDLocal.Connected := True;
    Application.ProcessMessages;
    Result := True;
    shpLocal.Brush.Color := clLime;
  except
    Application.Title := 'Falha de Conexão Banco Local...';
    lblStatus.Caption := 'Falha de Conexão Banco Local...';
    lblStatus.Update;
    FDLocal.Connected := False;
    Application.ProcessMessages;
    Result := False;
    shpLocal.Brush.Color := clRed;
  end;
  FDServer.Connected := False;
  try
    Application.Title := 'Conectando no Banco Servidor...';
    lblStatus.Caption := 'Conectando no Banco Servidor...';
    lblStatus.Update;
    FDServer.Connected := True;
    Application.ProcessMessages;
    Result := True;
    shpServidor.Brush.Color := clLime;
  except
    Application.Title := 'Falha de Conexão Banco Servidor...';
    lblStatus.Caption := 'Falha de Conexão Banco Servidor...';
    lblStatus.Update;
    FDServer.Connected := False;
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

    FDLocal.Connected := False;
    FDServer.Connected := False;
    Application.ProcessMessages;
  except
    Application.ProcessMessages;
  end;
end;

function TfrmPrincipal.ExportaMovimentosPDV: boolean;
var
  vCondicao, vTabela : string;
  i : integer;
  erro : Boolean;
  vIDNovo : Integer;
begin
  {$region 'Cupom Fiscal'}
  AtualizaStatus('Verificando Cupom Fiscal');
  vTabela := 'CUPOMFISCAL_LOG';
  vCondicao := 'Tipo = ''0'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Local(vTabela, vCondicao);
  with qryConsultaLocal do
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
      if qryConsultaServidor.IsEmpty then
        qryConsultaServidor.Insert
      else
        qryConsultaServidor.Edit;

      for I := 0 to qryConsultaTabelaLocal.FieldCount - 1 do
      begin
        try
          qryConsultaServidor.FindField(qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaLocal.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        vIDNovo := FDServer.ExecSQLScalar('select gen_id(GEN_CUPOMFISCAL,1) from rdb$database');
        qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
        qryConsultaServidor.Post;
        qryConsultaServidor.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaServidor.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar itens
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_ITENS';
      Abrir_Tabela_Local(vTabela, vCondicao);
      qryConsultaTabelaLocal.First;
      while not qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
//        vCondicao := 'ID = ' + qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vCondicao := '0 = 1 ';
        vTabela := 'CUPOMFISCAL_ITENS';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if qryConsultaServidor.IsEmpty then
          qryConsultaServidor.Insert
        else
          qryConsultaServidor.Edit;

        for I := 0 to qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            qryConsultaServidor.FindField(qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          qryConsultaServidor.FieldByName('id_movimento').Clear;
          qryConsultaServidor.Post;
          qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        qryConsultaTabelaLocal.Next;
      end;

      //Gravar itens sem
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_ITENS_SEM';
      Abrir_Tabela_Local(vTabela, vCondicao);
      qryConsultaTabelaLocal.First;
      while not qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vTabela := 'CUPOMFISCAL_ITENS_SEM';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if qryConsultaServidor.IsEmpty then
          qryConsultaServidor.Insert
        else
          qryConsultaServidor.Edit;

        for I := 0 to qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            qryConsultaServidor.FindField(qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          qryConsultaServidor.Post;
          qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        qryConsultaTabelaLocal.Next;
      end;

      //Gravar cupom parc
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_PARC';
      Abrir_Tabela_Local(vTabela, vCondicao);
      qryConsultaTabelaLocal.First;
      while not qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND PARCELA = ' + qryConsultaTabelaLocal.FieldByName('PARCELA').AsString;
        vTabela := 'CUPOMFISCAL_PARC';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if qryConsultaServidor.IsEmpty then
          qryConsultaServidor.Insert
        else
          qryConsultaServidor.Edit;

        for I := 0 to qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            qryConsultaServidor.FindField(qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          qryConsultaServidor.Post;
          qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        qryConsultaTabelaLocal.Next;
      end;

      //Gravar cupom troca
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_TROCA';
      Abrir_Tabela_Local(vTabela, vCondicao);
      qryConsultaTabelaLocal.First;
      while not qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vTabela := 'CUPOMFISCAL_TROCA';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if qryConsultaServidor.IsEmpty then
          qryConsultaServidor.Insert
        else
          qryConsultaServidor.Edit;

        for I := 0 to qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            qryConsultaServidor.FindField(qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          qryConsultaServidor.Post;
          qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        qryConsultaTabelaLocal.Next;
      end;


      //Gravar Cupom Fiscal FormaPagto
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'CUPOMFISCAL_FORMAPGTO';
      Abrir_Tabela_Local(vTabela, vCondicao);
      qryConsultaTabelaLocal.First;
      while not qryConsultaTabelaLocal.Eof do
      begin
        AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + qryConsultaTabelaLocal.FieldByName('ID').AsString + 'AND ITEM = ' + qryConsultaTabelaLocal.FieldByName('ITEM').AsString;
        vTabela := 'CUPOMFISCAL_FORMAPGTO';
        Abrir_Consulta_Servidor(vTabela, vCondicao);
        if qryConsultaServidor.IsEmpty then
          qryConsultaServidor.Insert
        else
          qryConsultaServidor.Edit;

        for I := 0 to qryConsultaTabelaLocal.FieldCount - 1 do
        begin
          try
            qryConsultaServidor.FindField(qryConsultaTabelaLocal.Fields[i].FieldName).AsVariant :=
               qryConsultaTabelaLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          qryConsultaServidor.FieldByName('id').AsInteger := vIDNovo;
          qryConsultaServidor.Post;
          qryConsultaServidor.ApplyUpdates(0);
          erro := False;
        except
          qryConsultaServidor.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        qryConsultaTabelaLocal.Next;
      end;

      //Gravar Movimento
      try
        FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_ESTOQUE('+ IntToStr(vIDNovo) + ', ''CFI'')');
      except
        GravaLogErro('Erro Gravando Movimento estoque nº: ' + IntToStr(vIDNovo));
      end;



      vTabela := 'CUPOMFISCAL_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(FDLocal,vTabela, True, vCondicao);
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
  vCondicao := 'Tipo = ''1'' and ID_TERMINAL = ' + vTerminal + ' order by ID_TERMINAL';
  Abrir_Consulta_Servidor(vTabela, vCondicao);
  with qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Cliente => ' + FieldByName('ID_PESSOA').AsString);
      vCondicao := 'codigo = ' + FieldByName('ID').AsString;
      vTabela := 'PESSOA';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if qryConsultaLocal.IsEmpty then
        qryConsultaLocal.Insert
      else
        qryConsultaLocal.Edit;

      vCondicao := 'codigo = ' + FieldByName('ID').AsString;
      vTabela := 'PESSOA';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        qryConsultaLocal.Post;
        qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      vTabela := 'PESSOA_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(FDServer,vTabela, True, vCondicao);
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
  with qryConsultaServidor do 
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo NCM => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_NCM';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if qryConsultaLocal.IsEmpty then
        qryConsultaLocal.Insert
      else
        qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_NCM';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        qryConsultaLocal.Post;
        qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      vTabela := 'TAB_NCM_LOG';
      vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(FDServer,vTabela, True, vCondicao);
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
  with qryConsultaTabelaServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Unidade => ' + FieldByName('UNIDADE').AsString);
      vCondicao := 'UNIDADE = ' + QuotedStr(FieldByName('UNIDADE').AsString); 
      vTabela := 'UNIDADE';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if qryConsultaLocal.IsEmpty then
        qryConsultaLocal.Insert
      else
        qryConsultaLocal.Edit;

      for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        qryConsultaLocal.Post;
        qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaLocal.Cancel;
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
  with qryConsultaTabelaServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Grupos => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + QuotedStr(FieldByName('ID').AsString);
      vTabela := 'GRUPO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if qryConsultaLocal.IsEmpty then
        qryConsultaLocal.Insert
      else
        qryConsultaLocal.Edit;

      for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        qryConsultaLocal.Post;
        qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaLocal.Cancel;
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
  with qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Produtos => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + QuotedStr(FieldByName('ID').AsString);
      vTabela := 'PRODUTO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if qryConsultaLocal.IsEmpty then
        qryConsultaLocal.Insert
      else
        qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'PRODUTO';
      Abrir_Tabela_Servidor(vTabela, vCondicao);

      for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        qryConsultaLocal.Post;
        qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      vTabela := 'PRODUTO_LOG';
      vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(FDServer,vTabela, True, vCondicao);
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
  with qryConsultaServidor do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Tabela de Preço => ' + FieldByName('ID').AsString);
      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_PRECO';
      Abrir_Consulta_Local(vTabela, vCondicao);
      if qryConsultaLocal.IsEmpty then
        qryConsultaLocal.Insert
      else
        qryConsultaLocal.Edit;

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_PRECO';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
      begin
        try
          qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
             qryConsultaTabelaServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        qryConsultaLocal.Post;
        qryConsultaLocal.ApplyUpdates(0);
        erro := False;
      except
        qryConsultaLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar itens

      vCondicao := 'ID = ' + FieldByName('ID').AsString;
      vTabela := 'TAB_PRECO_ITENS';
      Abrir_Tabela_Servidor(vTabela, vCondicao);
      qryConsultaTabelaServer.First;
      while not qryConsultaTabelaServer.Eof do
      begin
        AtualizaStatus('Recebendo Itens Tabela de Preço => ' + FieldByName('ID').AsString);
        vCondicao := 'ID = ' + qryConsultaTabelaServer.FieldByName('ID').AsString + 'AND ITEM = ' + qryConsultaTabelaServer.FieldByName('ITEM').AsString;
        vTabela := 'TAB_PRECO_ITENS';
        Abrir_Consulta_Local(vTabela, vCondicao);
        if qryConsultaLocal.IsEmpty then
          qryConsultaLocal.Insert
        else
          qryConsultaLocal.Edit;

        for I := 0 to qryConsultaTabelaServer.FieldCount - 1 do
        begin
          try
            qryConsultaLocal.FindField(qryConsultaTabelaServer.Fields[i].FieldName).AsVariant :=
               qryConsultaTabelaServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          qryConsultaLocal.Post;
          qryConsultaLocal.ApplyUpdates(0);
          erro := False;
        except
          qryConsultaLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        qryConsultaTabelaServer.Next;
      end;

      vTabela := 'TAB_PRECO_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

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

  FDLocal.Connected := False;
  FDLocal.Params.Clear;
  FDLocal.DriverName := 'FB';
  FDLocal.Params.Values['DriveId'] := 'FB';
  FDLocal.Params.Values['DataBase'] := BaseLocal;
  FDLocal.Params.Values['User_Name'] := UserName;
  FDLocal.Params.Values['Password'] := PassWord;

  FDServer.Connected := False;
  FDServer.Params.Clear;
  FDServer.DriverName := 'FB';
  FDServer.Params.Values['DriveId'] := 'FB';
  FDServer.Params.Values['DataBase'] := BaseServer;
  FDServer.Params.Values['Server'] := IP;
  FDServer.Params.Values['User_Name'] := UserNameServer;
  FDServer.Params.Values['Password'] := PassWordServer;

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
