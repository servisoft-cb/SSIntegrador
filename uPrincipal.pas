unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  JvComponentBase, JvThreadTimer, Vcl.AppEvnts, IniFiles, IdCoderMIME,
  uDMPrincipal, TrataException,
  Vcl.Buttons, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

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
    procedure JvThreadTimerTimer(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    vTempoCiclo : integer;
    fDMPrincipal : TDMPrincipal;
    QryDados_Log : TFDQuery;
    QryDadosLocal : TFDQuery;
    QryDadosServer : TFDQuery;
    function ImportaServidorTabelaProduto: boolean;
    function ApagaRegistrosExcluidosNoServidor: boolean;
    function ExportaMovimentosPDV: boolean;
    function ExcluirRegistroServidor : boolean;
    procedure AtualizaStatus (aValue : String);
    procedure Apaga_Registro(Conexao : TFDConnection; Tabela : String; TestaTerminal : Boolean; Condicao : String = '0=1');
    procedure GravaLogErro(Erro : String);
    procedure Inicia_Processso;
    procedure Finaliza_Processo;
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

function TfrmPrincipal.ApagaRegistrosExcluidosNoServidor: boolean;
var
  vTabela, vCondicao : String;
begin
  {$region 'Clientes'}
  AtualizaStatus('Verificando Exclusões de Clientes!');
  try
    QryDados_Log.Close;
    fDMPrincipal.vTabela := 'PESSOA_LOG';
    fDMPrincipal.ListaTipo.Clear;
    fDMPrincipal.ListaTipo.Add('2');
    QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
    with QryDados_Log do
    begin
      if not (IsEmpty) then
      while not Eof do
      begin
        AtualizaStatus('Excluindo Cliente => ' + FieldByName('ID').AsString);
        vCondicao := 'codigo = ' + FieldByName('ID').AsString;
        vTabela := 'PESSOA';
        Apaga_Registro(fDMPrincipal.FDLocal, vTabela, false, vCondicao);
        vTabela := 'PESSOA_LOG';
        vCondicao := ' and ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer,vTabela, true, vCondicao);
        Next;
      end;
    end;
    AtualizaStatus('');
  finally
    QryDados_Log.Free;
  end;
  {$endregion}

  {$region 'Lista Preço'}
  QryDados_Log := TFDQuery.Create(nil);
  try
    AtualizaStatus('Verificando Exclusões de Lista de Preço!');
    fDMPrincipal.ListaTipo.Clear;
    fDMPrincipal.ListaTipo.Add('2');
    fDMPrincipal.vTabela := 'TAB_PRECO_LOG';
    QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
    with QryDados_Log do
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
  finally
    QryDados_Log.Free;
  end;
  {$endregion}

  {$region 'Produtos'}
  QryDados_Log := TFDQuery.Create(nil);
  try
    AtualizaStatus('Verificando Exclusões de Produtos!');
    fDMPrincipal.vTabela := 'PRODUTO_LOG';
    fDMPrincipal.ListaTipo.Clear;
    fDMPrincipal.ListaTipo.Add('2');
    QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
    with QryDados_Log do
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
  finally
    QryDados_Log.Free;
  end;
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
    qry.SQL.Add('delete from ' + Tabela + ' where 0=0' );
    if TestaTerminal then
       qry.SQL.Add(' and ID_TERMINAL = ' + fDMPrincipal.vTerminal);
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

function TfrmPrincipal.ExcluirRegistroServidor: boolean;
var
  vCondicao : String;
  vNumCupom, vFilial : integer;
  vTipo : String;
begin
  {$Region 'Exclui CupomFiscal'}
  AtualizaStatus('Excluindo Cupom Fiscal');
  fDMPrincipal.vTabela := 'CUPOMFISCAL_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('2');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpLocal);
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      vNumCupom := FieldByName('NumCupom').AsInteger;
      vFilial := FieldByName('Filial').AsInteger;
      vTipo := FieldByName('Tipo_Cupom').AsString;

      vCondicao := ' where Numcupom = ' + IntToStr(vNumCupom);
      vCondicao := vCondicao + ' and filial = ' + IntToStr(vFilial);
      vCondicao := vCondicao + ' and Terminal_ID = ' + fDMPrincipal.vTerminal;
      vCondicao := vCondicao + ' and Tipo = ' + QuotedStr(vTipo);

      try
        fDMPrincipal.FDServer.ExecSQL('DELETE FROM CUPOMFISCAL ' + vCondicao);
      except
        on E : Exception do
        begin
          GravaLogErro('Erro Excluindo Cupom Fiscal nº: ' + IntToStr(vNumCupom));
        end;
      end;
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDLocal, fDMPrincipal.vTabela, False, vCondicao);
      Next;
    end;
  end;
  {$endRegion}
end;

function TfrmPrincipal.ExportaMovimentosPDV: boolean;
var
  vCondicao, vTabela, Prazo : string;
  i, vIDNovo, Cont : integer;
  erro : Boolean;
begin
  {$region 'Cupom Fiscal'}
  try
    AtualizaStatus('Verificando Cupom Fiscal');
    Cont := 0;
    if Assigned(QryDados_Log) then
    begin
      FreeAndNil(QryDados_Log);
      QryDados_Log := TFDQuery.Create(nil);
    end;

    if Assigned(QryDadosLocal) then
    begin
      FreeAndNil(QryDadosLocal);
      QryDadosLocal := TFDQuery.Create(nil);
      QryDadosLocal.Connection := fDMPrincipal.FDLocal;
    end;

    if Assigned(QryDadosServer) then
    begin
      FreeAndNil(QryDadosServer);
      QryDadosServer := TFDQuery.Create(nil);
      QryDadosServer.Connection := fDMPrincipal.FDServer;
    end;

    with fDMPrincipal do
    begin
      vTabela := 'CUPOMFISCAL_LOG';
      ListaTipo.Clear;
      ListaTipo.Add('0');
      ListaTipo.Add('1');
      QryDados_Log := Abrir_Tabela_Log(tpLocal);
    end;
    with QryDados_Log do
    begin
      if not (IsEmpty) then
      while not Eof do
      begin
        AtualizaStatus('Recebendo Cupom Fiscal => ' + FieldByName('ID').AsString);
        Inc(Cont);
        with fDMPrincipal do
        begin
          vTabela := 'CUPOMFISCAL';
          AdicionaDados('ID',FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);

          vTabela := 'CUPOMFISCAL';
          vCondicao := 'and NUMCUPOM = ' + QryDadosLocal.FieldByName('NUMCUPOM').AsString;
          vCondicao := vCondicao + ' and FILIAL = ' + QryDadosLocal.FieldByName('FILIAL').AsString;
          vCondicao := vCondicao + ' and TIPO = ' + QuotedStr(QryDadosLocal.FieldByName('TIPO').AsString);
          vCondicao := vCondicao + ' and SERIE = ' + QuotedStr(QryDadosLocal.FieldByName('SERIE').AsString);
          Apaga_Registro(fDMPrincipal.FDServer, vTabela, False, vCondicao);

          AdicionaDados('ID',QuotedStr('-1'));
          QryDadosServer := Abrir_Tabela(tpServer);
        end;
        if QryDadosServer.IsEmpty then
        begin
          QryDadosServer.Insert;
          vIDNovo := 0;
          end
        else
        begin
          QryDadosServer.Edit;
          vIDNovo := QryDadosServer.FieldByName('ID').AsInteger;
        end;

        for I := 0 to QryDadosLocal.FieldCount - 1 do
        begin
          try
            QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
               QryDadosLocal.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          if vIDNovo = 0 then
            vIDNovo := fDMPrincipal.FDServer.ExecSQLScalar('select gen_id(GEN_CUPOMFISCAL,1) from rdb$database');

          QryDadosServer.FieldByName('id').AsInteger := vIDNovo;
          QryDadosServer.Post;

          if Cont = 5 then
          begin
            Application.ProcessMessages;
            Cont := 0;
          end;
          QryDadosServer.CachedUpdates := True;
          QryDadosServer.ApplyUpdates(0);
          erro := False;
        except
          QryDadosServer.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;

        //Gravar itens
        with fDMPrincipal do
        begin
          vTabela := 'CUPOMFISCAL_ITENS';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        while not QryDadosLocal.Eof do
        begin
          AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_ITENS';
            AdicionaDados('ID', IntToStr(vIDNovo));
            AdicionaDados('ITEM',QryDadosLocal.FieldByName('ITEM').AsString,False);
            QryDadosServer := Abrir_Tabela(tpServer);
          end;
          if QryDadosServer.IsEmpty then
            QryDadosServer.Insert
          else
            QryDadosServer.Edit;

          for I := 0 to QryDadosLocal.FieldCount - 1 do
          begin
            try
              QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                 QryDadosLocal.Fields[i].AsVariant;
            except
              Application.ProcessMessages;
            end;
          end;
          try
            QryDadosServer.FieldByName('id').AsInteger := vIDNovo;
            QryDadosServer.FieldByName('id_movimento').Clear;
            QryDadosServer.CachedUpdates := True;
            QryDadosServer.Post;
            QryDadosServer.ApplyUpdates(0);
            erro := False;
          except
            GravaLogErro('Erro Gravando Item Cupom: ' +  QryDadosLocal.FieldByName('NUM_CUPOM').AsString + '/'+QryDadosLocal.FieldByName('ITEM').AsString);
            QryDadosServer.Cancel;
            erro := True;
            Application.ProcessMessages;
          end;
          QryDadosLocal.Next;
        end;

        //Gravar itens sem
        with fDMPrincipal do
        begin
          vTabela := 'CUPOMFISCAL_ITENS_SEM';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        while not QryDadosLocal.Eof do
        begin
          AtualizaStatus('Recebendo Itens do Cupom => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_ITENS_SEM';
            AdicionaDados('ID', IntToStr(vIDNovo));
            AdicionaDados('ITEM',QryDadosLocal.FieldByName('ITEM').AsString,False);
            QryDadosServer := Abrir_Tabela(tpServer);
          end;
          if QryDadosServer.IsEmpty then
            QryDadosServer.Insert
          else
            QryDadosServer.Edit;

          for I := 0 to QryDadosLocal.FieldCount - 1 do
          begin
            try
              QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                 QryDadosLocal.Fields[i].AsVariant;
            except
              Application.ProcessMessages;
            end;
          end;
          try
            QryDadosServer.FieldByName('id').AsInteger := vIDNovo;
            QryDadosServer.CachedUpdates := True;
            QryDadosServer.Post;
            QryDadosServer.ApplyUpdates(0);
            erro := False;
          except
            QryDadosServer.Cancel;
            erro := True;
            Application.ProcessMessages;
          end;
          QryDadosLocal.Next;
        end;

        //Gravar cupom parc
        with fDMPrincipal do
        begin
          vTabela := 'CUPOMFISCAL_PARC';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        while not QryDadosLocal.Eof do
        begin
          AtualizaStatus('Recebendo Parcelas do Cupom => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_PARC';
            AdicionaDados('ID', IntToStr(vIDNovo));
            AdicionaDados('PARCELA',QryDadosLocal.FieldByName('PARCELA').AsString,False);
            QryDadosServer := Abrir_Tabela(tpServer);
          end;
          if QryDadosServer.IsEmpty then
            QryDadosServer.Insert
          else
            QryDadosServer.Edit;

          for I := 0 to QryDadosLocal.FieldCount - 1 do
          begin
            try
              QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                 QryDadosLocal.Fields[i].AsVariant;
            except
              Application.ProcessMessages;
            end;
          end;
          try
            QryDadosServer.FieldByName('id').AsInteger := vIDNovo;
            QryDadosServer.FieldByName('id_duplicata').Clear;
            QryDadosServer.CachedUpdates := True;
            QryDadosServer.Post;
            QryDadosServer.ApplyUpdates(0);
            erro := False;
          except
            QryDadosServer.Cancel;
            erro := True;
            Application.ProcessMessages;
          end;
          QryDadosLocal.Next;
        end;

        //Gravar cupom troca
        with fDMPrincipal do
        begin
          vTabela := 'CUPOMFISCAL_TROCA';
          AdicionaDados('ID_CUPOM', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        while not QryDadosLocal.Eof do
        begin
          AtualizaStatus('Recebendo Troca do Cupom => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_TROCA';
            AdicionaDados('ID_CUPOM', IntToStr(vIDNovo));
            AdicionaDados('ITEM',QryDadosLocal.FieldByName('ITEM').AsString,False);
            QryDadosServer := Abrir_Tabela(tpServer);
          end;
          if QryDadosServer.IsEmpty then
            QryDadosServer.Insert
          else
            QryDadosServer.Edit;

          for I := 0 to QryDadosLocal.FieldCount - 1 do
          begin
            try
              QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                 QryDadosLocal.Fields[i].AsVariant;
            except
              Application.ProcessMessages;
            end;
          end;
          try
            QryDadosServer.FieldByName('ID').AsInteger := fDMPrincipal.FDServer.ExecSQLScalar('select gen_id(GEN_CUPOMFISCAL_TROCA,1) from rdb$database');
            QryDadosServer.FieldByName('ID_CUPOM').AsInteger := vIDNovo;
            QryDadosServer.FieldByName('ID_MOVESTOQUE').Clear;
            QryDadosServer.CachedUpdates := True;
            QryDadosServer.Post;
            QryDadosServer.ApplyUpdates(0);
            erro := False;
          except
            QryDadosServer.Cancel;
            erro := True;
            Application.ProcessMessages;
          end;
          QryDadosLocal.Next;
        end;

        //Gravar Cupom Fiscal FormaPagto
        with fDMPrincipal do
        begin
          vTabela := 'CUPOMFISCAL_FORMAPGTO';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        while not QryDadosLocal.Eof do
        begin
          AtualizaStatus('Recebendo Troca do Cupom => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_FORMAPGTO';
            AdicionaDados('ID', IntToStr(vIDNovo));
            AdicionaDados('ITEM',QryDadosLocal.FieldByName('ITEM').AsString,False);
            QryDadosServer := Abrir_Tabela(tpServer);
          end;
          if QryDadosServer.IsEmpty then
            QryDadosServer.Insert
          else
            QryDadosServer.Edit;

          for I := 0 to QryDadosLocal.FieldCount - 1 do
          begin
            try
              QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                 QryDadosLocal.Fields[i].AsVariant;
            except
              Application.ProcessMessages;
            end;
          end;
          try
            QryDadosServer.FieldByName('id').AsInteger := vIDNovo;
            QryDadosServer.CachedUpdates := True;
            QryDadosServer.Post;
            QryDadosServer.ApplyUpdates(0);
            erro := False;
          except
            QryDadosServer.Cancel;
            erro := True;
            Application.ProcessMessages;
          end;
          QryDadosLocal.Next;
        end;

        //Gravar Estoque
        repeat
          try
            fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_ESTOQUE('+ IntToStr(vIDNovo) + ', ''CFI'')');
            erro := False;
          except
            on E : Exception do
            begin
              GravaLogErro('Erro Gravando Movimento estoque nº: ' + IntToStr(vIDNovo));
              fDMPrincipal.FDServer.Rollback;
              erro := True;
            end;
          end;

        until not erro;

        //Gravar Estoque Troca

        repeat
          try
            fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_ESTOQUE('+ IntToStr(vIDNovo) + ', ''TRO'')');
            erro := False
          except
            on E : Exception do
            begin
              GravaLogErro('Erro Gravando Movimento estoque nº: ' + IntToStr(vIDNovo));
              fDMPrincipal.FDServer.Rollback;
              erro := True;
            end;
          end;
        until not erro;

        //Gravar Duplicata - Histórico - Comissão - Financeiro
        try
          fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_DUPLICATA_CUPOM('+
                                         QuotedStr('')+ ', ' + IntToStr(vIDNovo) + ', ' +
                                         fDMPrincipal.vTerminal + ')');
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
  finally
    QryDados_Log.Free;
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
  QryDados_Log.Close;
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  fDMPrincipal.vTabela := 'PESSOA_LOG';
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Cliente => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        AdicionaDados('CODIGO',FieldByName('ID').AsString);
        vTabela := 'PESSOA';
        QryDadosLocal := Abrir_Tabela(tpLocal);
      end;
      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      vTabela := 'PESSOA_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,vTabela, True, vCondicao);
      Next;
    end;
  end;
  QryDados_Log.Close;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera NCM'}
  AtualizaStatus('Verificando Alterações em NCM');
  fDMPrincipal.vTabela := 'TAB_NCM_LOG';
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo NCM => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        AdicionaDados('ID',FieldByName('ID').AsString);
        vTabela := 'TAB_NCM';
        QryDadosLocal := Abrir_Tabela(tpLocal);
      end;
      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;
      QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      fDMPrincipal.vTabela := 'TAB_NCM_LOG';
      vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer,fDMPrincipal.vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Unidade'}
  AtualizaStatus('Verificando Alterações em Unidades');
  fDMPrincipal.vTabela := 'UNIDADE';
  fDMPrincipal.AdicionaDados('','');
  QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
  with QryDadosServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Unidade => ' + FieldByName('UNIDADE').AsString);

      with fDMPrincipal do
      begin
        AdicionaDados('UNIDADE',QuotedStr(FieldByName('UNIDADE').AsString));
        QryDadosLocal := Abrir_Tabela(tpLocal);
      end;

      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      Next;
    end;
  end;
  AtualizaStatus('');
  QryDadosLocal.Close;
  QryDadosServer.Close;
  {$endregion}

  {$region 'Inclui/Altera Grupo'}
  AtualizaStatus('Verificando Alterações em Grupos');
  fDMPrincipal.vTabela := 'GRUPO';
  fDMPrincipal.AdicionaDados('','');
  QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
  with QryDadosServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Grupos => ' + FieldByName('ID').AsString);

      with fDMPrincipal do
      begin
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosLocal := Abrir_Tabela(tpLocal);
      end;
      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      Next;
    end;
  end;
  AtualizaStatus('');
  QryDadosLocal.Close;
  QryDadosServer.Close;
  {$endregion}

  {$Region 'Inclui/Altera Marca'}
  AtualizaStatus('Verificando Alterações em Marcas');
  fDMPrincipal.vTabela := 'MARCA';
  fDMPrincipal.AdicionaDados('','');
  QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
  with QryDadosServer do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Marcas => ' + FieldByName('ID').AsString);

      with fDMPrincipal do
      begin
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosLocal := Abrir_Tabela(tpLocal);
      end;
      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      Next;
    end;
  end;
  AtualizaStatus('');
  QryDadosLocal.Close;
  QryDadosServer.Close;
  {$endregion}

  {$region 'Inclui/Altera Produto'}
  AtualizaStatus('Verificando Alterações em Produtos');
  fDMPrincipal.vTabela := 'PRODUTO_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Produtos => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        vTabela := 'PRODUTO';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosLocal := Abrir_Tabela(tpLocal);
      end;

      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;
      QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;
      fDMPrincipal.vTabela := 'PRODUTO_LOG';
      vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer, fDMPrincipal.vTabela, True, vCondicao);
      Next;
    end;
  end;
  AtualizaStatus('');
  {$endregion}

  {$region 'Inclui/Altera Tabela de Preço'}
  AtualizaStatus('Verificando Alterações em Tabela de Preço');
  fDMPrincipal.vTabela := 'TAB_PRECO_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Tabela de Preço => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        vTabela := 'TAB_PRECO';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosLocal  := Abrir_Tabela(tpLocal);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;

      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

     //   Gravar itens
      with fDMPrincipal do
      begin
        vTabela := 'TAB_PRECO_ITENS';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;
      while not QryDadosServer.Eof do
      begin
        AtualizaStatus('Recebendo Itens Tabela de Preço => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'TAB_PRECO_ITENS';
          AdicionaDados('ID',FieldByName('ID').AsString);
          AdicionaDados('ITEM',QryDadosServer.FieldByName('ITEM').AsString,False);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;
        for I := 0 to QryDadosServer.FieldCount - 1 do
        begin
          try
            QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
               QryDadosServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          QryDadosLocal.Post;
          QryDadosLocal.CachedUpdates := True;
          QryDadosLocal.ApplyUpdates(0);
          erro := False;
        except
          QryDadosLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        QryDadosServer.Next;
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
  fDMPrincipal.vTabela := 'CONDPGTO_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Condições de Pagto => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        vTabela := 'CONDPGTO';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosLocal  := Abrir_Tabela(tpLocal);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;
      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;
      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar itens
      with fDMPrincipal do
      begin
        vTabela := 'CONDPGTO_DIA';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;
      while not QryDadosServer.Eof do
      begin
        AtualizaStatus('Recebendo Itens Condições de Pagto => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'CONDPGTO_DIA';
          AdicionaDados('ID',FieldByName('ID').AsString);
          AdicionaDados('ITEM',QryDadosServer.FieldByName('ITEM').AsString,False);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for I := 0 to QryDadosServer.FieldCount - 1 do
        begin
          try
            QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
               QryDadosServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          QryDadosLocal.Post;
          QryDadosLocal.CachedUpdates := True;
          QryDadosLocal.ApplyUpdates(0);
          erro := False;
        except
          QryDadosLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        QryDadosServer.Next;
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
  with fDMPrincipal do
  begin
    vTabela := 'PARAMETROS_LOG';
    ListaTipo.Add('0');
    ListaTipo.Add('1');
    QryDados_Log := Abrir_Tabela_Log(tpServer);
  end;
  with QryDados_Log do
  begin
    if not (IsEmpty) then
    while not Eof do
    begin
      AtualizaStatus('Recebendo Parâmetros => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        vTabela := 'PARAMETROS';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosLocal  := Abrir_Tabela(tpLocal);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;
      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      for I := 0 to QryDadosServer.FieldCount - 1 do
      begin
        try
          QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
             QryDadosServer.Fields[i].AsVariant;
        except
          Application.ProcessMessages;
        end;
      end;
      try
        QryDadosLocal.Post;
        QryDadosLocal.CachedUpdates := True;
        QryDadosLocal.ApplyUpdates(0);
        erro := False;
      except
        QryDadosLocal.Cancel;
        erro := True;
        Application.ProcessMessages;
      end;

      //Gravar Parametros Financeiro

      with fDMPrincipal do
      begin
        vTabela := 'PARAMETROS_FIN';
        AdicionaDados('ID',FieldByName('ID').AsString);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;
      while not QryDadosServer.Eof do
      begin
        AtualizaStatus('Recebendo Parâmetros Financeiro => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'PARAMETROS_FIN';
          AdicionaDados('ID',FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for I := 0 to QryDadosServer.FieldCount - 1 do
        begin
          try
            QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
               QryDadosServer.Fields[i].AsVariant;
          except
            Application.ProcessMessages;
          end;
        end;
        try
          QryDadosLocal.Post;
          QryDadosLocal.CachedUpdates := True;
          QryDadosLocal.ApplyUpdates(0);
          erro := False;
        except
          QryDadosLocal.Cancel;
          erro := True;
          Application.ProcessMessages;
        end;
        QryDadosServer.Next;
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

procedure TfrmPrincipal.Finaliza_Processo;
begin
  if Assigned(QryDados_Log) then
    QryDados_Log.Free;

  if Assigned(QryDadosLocal) then
    QryDadosLocal.Free;

  if Assigned(QryDadosServer) then
    QryDadosServer.Free;

  fDMPrincipal.desconectar;

  if Assigned(fDMPrincipal) then
    fDMPrincipal.Free;

end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  top := Screen.Height - Height - 50;
  left := Screen.Width - Width;
end;

procedure TfrmPrincipal.Inicia_Processso;
var
  ArquivoIni : String;
  ImpressoraIni : String;
  BaseLocal, DriverName, UserName, PassWord : String;
  BaseServer, DriverNameServer, UserNameServer, PassWordServer, IP : String;
  Local, Posicao : Integer;
  Configuracoes : TIniFile;
  ConfigImpressora : TIniFile;
  Decoder64: TIdDecoderMIME;
  Encoder64: TIdEncoderMIME;
begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  fDMPrincipal := TDMPrincipal.Create(nil);
  lblUltimaAtualizacao.Caption := 'Aguardando configurações';
  Decoder64 := TIdDecoderMIME.Create(nil);
  ArquivoIni := ExtractFilePath(Application.ExeName) + '\Config.ini';
  ImpressoraIni := 'C:\$Servisoft\Impressora.ini';
  if not FileExists(ArquivoIni) then
  begin
    MessageDlg('Arquivo config.ini não encontrado!', mtInformation,[mbOK],0);
    Exit;
  end;
  if not FileExists(ImpressoraIni) then
  begin
    MessageDlg('Arquivo Impressora.ini não encontrado!', mtInformation,[mbOK],0);
    Exit;
  end;

  ConfigImpressora := TIniFile.Create(ImpressoraIni);
  try
    fDMPrincipal.vTerminal := ConfigImpressora.ReadString('IMPRESSORA', 'Terminal', '');
  finally
    ConfigImpressora.Free;
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
    Posicao := Pos(':',BaseServer);
    IP := Copy(BaseServer,1,Posicao - 1);
    BaseServer := Copy(BaseServer,Posicao + 1,Length(BaseServer));
//    IP := Configuracoes.ReadString('SSFacil_Servidor','IP','');
    PassWordServer   := Decoder64.DecodeString(Configuracoes.ReadString('SSFacil_Servidor', 'PASSWORD', ''));
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
  fDMPrincipal.FDServer.Params.Values['Database'] := BaseServer;
  fDMPrincipal.FDServer.Params.Values['Server'] := IP;
  fDMPrincipal.FDServer.Params.Values['User_Name'] := UserNameServer;
  fDMPrincipal.FDServer.Params.Values['Password'] := PassWordServer;

  JvThreadTimer.Interval := vTempoCiclo;
  lblTerminal.Caption := 'Terminal: ' + fDMPrincipal.vTerminal;
  lblLocal.caption := BaseLocal;
  lblLocal.Update;
  lblServidor.caption := BaseServer;
  lblServidor.Update;
  QryDados_Log := TFDQuery.Create(nil);

  QryDadosLocal := TFDQuery.Create(nil);
  QryDadosLocal.Connection := fDMPrincipal.FDLocal;

  QryDadosServer := TFDQuery.Create(nil);
  QryDadosServer.Connection := fDMPrincipal.FDServer;

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
  Application.Title := 'Estabelecendo conexões...';
  lblStatus.Caption := 'Estabelecendo conexões...';
  lblStatus.Update;
  Application.ProcessMessages;

  Inicia_Processso;

  if fDMPrincipal.conectar then
  begin
    shpLocal.Brush.Color := clLime;
    shpServidor.Brush.Color := clLime;
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

    try
      ExcluirRegistroServidor;
    except
      Application.ProcessMessages;
    end;

  end
  else
  begin
    Application.Title := 'Falha na Conexão...';
    lblStatus.Caption := 'Falha na Conexão...';
    lblStatus.Update;
    Application.ProcessMessages;
    shpLocal.Brush.Color := clRed;
    shpServidor.Brush.Color := clRed;
    Finaliza_Processo;
    exit;
  end;
  Finaliza_Processo;
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
