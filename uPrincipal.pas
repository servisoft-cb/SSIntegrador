unit uPrincipal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.SyncObjs,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Menus,
  Vcl.AppEvnts,
  IniFiles,
  IdCoderMIME,
  uDMPrincipal,
  TrataException,
  Vcl.Buttons,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  Data.DB,
  GravarLog,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Classe.Versao;

type

  TfrmPrincipal = class(TForm)
    ApplicationEvents1: TApplicationEvents;
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
    Timer: TTimer;
    TimerMinimize: TTimer;
    procedure JvThreadTimerTimer(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerMinimizeTimer(Sender: TObject);
  private
    { Private declarations }
    vTempoCiclo: integer;
    fDMPrincipal: TDMPrincipal;
    QryDados_Log: TFDQuery;
    QryDadosLocal: TFDQuery;
    QryDadosServer: TFDQuery;
    FTerminate: Boolean;
    LThread: TThread;
    function ImportaServidorTabelaProduto: Boolean;
    function ApagaRegistrosExcluidosNoServidor: Boolean;
    function ExportaMovimentosPDV: Boolean;
    function ExcluirRegistroServidor: Boolean;
    procedure AtualizaStatus(aValue: String);
    procedure Apaga_Registro(Conexao: TFDConnection; Tabela: String; TestaTerminal: Boolean;
      Condicao: String = '0=1');
    procedure GravaLogErro(Erro: String);
    procedure Inicia_Processso;
    procedure LongRunningTask(TerminatingEvent: TEvent);
    procedure Finaliza_Processo;
    procedure FinalizaThread(Sender: TObject);
    procedure AtualizaLabel(aValue: String);

  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

function TfrmPrincipal.ApagaRegistrosExcluidosNoServidor: Boolean;
var
  vTabela, vCondicao: String;
begin
{$REGION 'Clientes'}
  AtualizaStatus('Verificando Exclusões de Clientes!');
  try
//    QryDados_Log.Close;
    fDMPrincipal.vTabela := 'PESSOA_LOG';
    fDMPrincipal.ListaTipo.Clear;
    fDMPrincipal.ListaTipo.Add('2');
    QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
    with QryDados_Log do
    begin
      if not(IsEmpty) then
        while not Eof do
        begin
//          AtualizaStatus('Excluindo Cliente => ' + FieldByName('ID').AsString);
          vCondicao := ' and codigo = ' + FieldByName('ID').AsString;
          vTabela := 'PESSOA';
          Apaga_Registro(fDMPrincipal.FDLocal, vTabela, false, vCondicao);
          vTabela := 'PESSOA_LOG';
          vCondicao := ' and ID = ' + FieldByName('ID').AsString;
          Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
          Next;
        end;
    end;
    AtualizaStatus('');
  finally
    FreeAndNil(QryDados_Log);
  end;
{$ENDREGION}
{$REGION 'Lista Preço'}
//  QryDados_Log := TFDQuery.Create(nil);
  try
    AtualizaStatus('Verificando Exclusões de Lista de Preço!');
    fDMPrincipal.ListaTipo.Clear;
    fDMPrincipal.ListaTipo.Add('2');
    fDMPrincipal.vTabela := 'TAB_PRECO_LOG';
    QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
    with QryDados_Log do
    begin
      if not(IsEmpty) then
        while not Eof do
        begin
//          AtualizaStatus('Excluindo Lista de Preço => ' + FieldByName('ID_TABPRECO').AsString);

          vCondicao := ' and ID = ' + FieldByName('ID_TABPRECO').AsString;
          vTabela := 'TAB_PRECO_ITENS';
          Apaga_Registro(fDMPrincipal.FDLocal, vTabela, false, vCondicao);

          vCondicao := ' and ID = ' + FieldByName('ID_TABPRECO').AsString;
          vTabela := 'TAB_PRECO';
          Apaga_Registro(fDMPrincipal.FDLocal, vTabela, false, vCondicao);

          vTabela := 'TAB_PRECO_LOG';
          vCondicao := ' and ID_TABPRECO = ' + FieldByName('ID_TABPRECO').AsString;
          Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
          Next;
        end;
    end;
    AtualizaStatus('');
  finally
    FreeAndNil(QryDados_Log);
  end;
{$ENDREGION}
{$REGION 'Produtos'}
//  QryDados_Log := TFDQuery.Create(nil);
  try
    AtualizaStatus('Verificando Exclusões de Produtos!');
    fDMPrincipal.vTabela := 'PRODUTO_LOG';
    fDMPrincipal.ListaTipo.Clear;
    fDMPrincipal.ListaTipo.Add('2');
    QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
    with QryDados_Log do
    begin
      if not(IsEmpty) then
        while not Eof do
        begin
//          AtualizaStatus('Excluindo Produto => ' + FieldByName('ID').AsString);
          vCondicao := ' and ID = ' + FieldByName('ID').AsString;
          vTabela := 'PRODUTO';
          Apaga_Registro(fDMPrincipal.FDLocal, vTabela, false, vCondicao);
          vTabela := 'PRODUTO_LOG';
          vCondicao := ' and ID = ' + FieldByName('ID').AsString;
          Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
          Next;
        end;
    end;
    AtualizaStatus('');
  finally
    FreeAndNil(QryDados_Log);
  end;
{$ENDREGION}
end;

procedure TfrmPrincipal.Apaga_Registro(Conexao: TFDConnection; Tabela: String;
  TestaTerminal: Boolean; Condicao: String = '0=1');
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  try
    qry.Connection := Conexao;
    qry.CachedUpdates := true;
    qry.Close;
    qry.SQL.Clear;
    qry.SQL.Add('delete from ' + Tabela + ' where 0=0');
    if TestaTerminal then
      qry.SQL.Add(' and ID_TERMINAL = ' + fDMPrincipal.vTerminal);
    qry.SQL.Add(' ' + Condicao);
    try
      qry.ExecSQL;
      Conexao.Commit;
    except
      on E: Exception do
      begin
        GravaLogErro(E.Message + ' - ' + qry.SQL.Text);
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
  TrayIcon.Visible := true;
  TrayIcon.Animate := true;
  TrayIcon.ShowBalloonHint;
end;

procedure TfrmPrincipal.AtualizaLabel(aValue: String);
begin
  lblStatus.Caption := aValue;
  lblStatus.Update;
end;

procedure TfrmPrincipal.AtualizaStatus(aValue: String);
begin
  Application.Title := aValue;
  lblStatus.Caption := Application.Title;
  lblStatus.Update;
end;

function TfrmPrincipal.ExcluirRegistroServidor: Boolean;
var
  vCondicao: String;
  vNumCupom, vFilial: integer;
  vTipo: String;
begin
{$REGION 'Exclui CupomFiscal'}
  AtualizaStatus('Excluindo Cupom Fiscal');
  fDMPrincipal.vTabela := 'CUPOMFISCAL_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('2');

  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpLocal);
  TGravarLog.New.doSaveLog(QryDados_Log.RecordCount.ToString);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
        vNumCupom := FieldByName('NumCupom').AsInteger;
        vFilial := FieldByName('Filial').AsInteger;
        vTipo := FieldByName('Tipo_Cupom').AsString;

        vCondicao := ' where Numcupom = ' + IntToStr(vNumCupom);
        vCondicao := vCondicao + ' and filial = ' + IntToStr(vFilial);
        vCondicao := vCondicao + ' and Terminal_ID = ' + fDMPrincipal.vTerminal;
        vCondicao := vCondicao + ' and Tipo = ' + QuotedStr(vTipo);
        TGravarLog.New.doSaveLog(vCondicao);

        try
          fDMPrincipal.FDServer.ExecSQL('DELETE FROM CUPOMFISCAL ' + vCondicao);
        except
          on E: Exception do
          begin
            TGravarLog.New.doSaveLog('Erro Excluindo cupom: ' +e.Message);
            GravaLogErro('Erro Excluindo Cupom Fiscal nº: ' + IntToStr(vNumCupom));
          end;
        end;
        vCondicao := ' and ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDLocal, fDMPrincipal.vTabela, false, vCondicao);
        Next;
      end;
  end;
{$ENDREGION}
end;

function TfrmPrincipal.ExportaMovimentosPDV: Boolean;
var
  vCondicao, vTabela, Prazo: string;
  i, vIDNovo, Cont: integer;
  Erro, erroProcedure, CupomExiste: Boolean;
  FField : TField;
  FHoraIni, FHoraFin : TTime;
begin
{$REGION 'Pessoa'}
  AtualizaStatus('Verificando Clientes');
  Cont := 0;
  if Assigned(QryDados_Log) then
  begin
    FreeAndNil(QryDados_Log);
//    QryDados_Log := TFDQuery.Create(nil);
  end;
  if Assigned(QryDadosLocal) then
  begin
    FreeAndNil(QryDadosLocal);
//    QryDadosLocal := TFDQuery.Create(nil);
//    QryDadosLocal.Connection := fDMPrincipal.FDLocal;
  end;
  if Assigned(QryDadosServer) then
  begin
    FreeAndNil(QryDadosServer);
//    QryDadosServer := TFDQuery.Create(nil);
//    QryDadosServer.Connection := fDMPrincipal.FDServer;
  end;

  with fDMPrincipal do
  begin
    vTabela := 'PESSOA_LOG';
    ListaTipo.Clear;
    ListaTipo.Add('0');
    ListaTipo.Add('1');
    QryDados_Log := Abrir_Tabela_Log(tpLocal);
  end;

  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Enviando Pessoa => ' + FieldByName('ID').AsString);
        Inc(Cont);
        with fDMPrincipal do
        begin
          vTabela := 'PESSOA';
          AdicionaDados('CODIGO', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);

          vTabela := 'PESSOA';
          AdicionaDados('CODIGO', FieldByName('ID').AsString);
          QryDadosServer := Abrir_Tabela(tpServer);
        end;

        if QryDadosServer.IsEmpty then
          QryDadosServer.Insert
        else
          QryDadosServer.Edit;

        for i := 0 to QryDadosLocal.FieldCount - 1 do
        begin
          try
            QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
              QryDadosLocal.Fields[i].AsVariant;
          except
            on E: Exception do
            begin
              GravaLogErro('Erro campo Cliente: ' + E.Message);
              Application.ProcessMessages;
            end;
          end;
        end;

        try
          QryDadosServer.Post;

          if Cont = 5 then
          begin
            Application.ProcessMessages;
            Cont := 0;
          end;
          QryDadosServer.CachedUpdates := true;
          QryDadosServer.ApplyUpdates(0);
          Erro := false;
        except
          on E: Exception do
          begin
            QryDadosServer.Cancel;
            Erro := true;
            Application.ProcessMessages;
            GravaLogErro('Erro Gravando Cliente: ' + E.Message);
          end;
        end;
        if not Erro then
        begin
          vTabela := 'PESSOA_LOG';
          vCondicao := ' and ID = ' + FieldByName('ID').AsString;
          Apaga_Registro(fDMPrincipal.FDLocal, vTabela, true, vCondicao);
        end;
        Next;
      end;
  end;

{$ENDREGION}
{$REGION 'Cupom Fiscal'}
  try
    AtualizaStatus('Verificando Cupom Fiscal');
    Cont := 0;
    if Assigned(QryDados_Log) then
    begin
      FreeAndNil(QryDados_Log);
//      QryDados_Log := TFDQuery.Create(nil);
    end;

//    if Assigned(QryDadosLocal) then
//    begin
//      FreeAndNil(QryDadosLocal);
//      QryDadosLocal := TFDQuery.Create(nil);
//      QryDadosLocal.Connection := fDMPrincipal.FDLocal;
//    end;

    if Assigned(QryDadosServer) then
    begin
      FreeAndNil(QryDadosServer);
//      QryDadosServer := TFDQuery.Create(nil);
//      QryDadosServer.Connection := fDMPrincipal.FDServer;
    end;

    with fDMPrincipal do
    begin
      vTabela := 'CUPOMFISCAL_LOG';
      ListaTipo.Clear;
      ListaTipo.Add('0');
      ListaTipo.Add('1');
      NumReg := 5;
      QryDados_Log := Abrir_Tabela_Log(tpLocal);
      NumReg := 0;
    end;
    with QryDados_Log do
    begin
      if not(IsEmpty) then
        while not Eof do
        begin
//          AtualizaStatus('Enviado Cupom Fiscal => ' + FieldByName('ID').AsString);
          Inc(Cont);
          CupomExiste := False;
          with fDMPrincipal do
          begin
            FHoraIni := Now;
            vTabela := 'CUPOMFISCAL';
            AdicionaDados('ID', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela(tpLocal);
            if QryDadosLocal.IsEmpty then
            begin
              next;
              Continue;
            end;

            vTabela := 'CUPOMFISCAL';
            AdicionaDados('NUMCUPOM', QryDadosLocal.FieldByName('NUMCUPOM').AsString);
            AdicionaDados('FILIAL', QryDadosLocal.FieldByName('FILIAL').AsString, False);
            AdicionaDados('TIPO', QuotedStr(QryDadosLocal.FieldByName('TIPO').AsString), False);
            AdicionaDados('SERIE', QuotedStr(QryDadosLocal.FieldByName('SERIE').AsString), False);
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
            CupomExiste := True;
          end;

          for i := 0 to QryDadosLocal.FieldCount - 1 do
          begin
            try
              QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                QryDadosLocal.Fields[i].AsVariant;
            except
              on E: Exception do
                TGravarLog.New.doSaveLog('Erro campos cupom: ' + e.Message);
            end;
          end;
          try
            if vIDNovo = 0 then
              vIDNovo := fDMPrincipal.FDServer.ExecSQLScalar
                ('select gen_id(GEN_CUPOMFISCAL,1) from rdb$database');

            QryDadosServer.FieldByName('id').AsInteger := vIDNovo;
            QryDadosServer.FieldByName('id_fechamento').Clear;
            QryDadosServer.Post;

            if Cont = 5 then
            begin
              Application.ProcessMessages;
              Cont := 0;
            end;
            QryDadosServer.CachedUpdates := true;
            QryDadosServer.ApplyUpdates(0);
            Erro := false;
          except
            on E: Exception do
            begin
              TGravarLog.New.doSaveLog(e.Message);
              GravaLogErro('Erro Gravando CupomFiscal: ' + E.Message);
              QryDadosServer.Cancel;
              Erro := true;
              Application.ProcessMessages;
            end;
          end;

          // Gravar itens
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_ITENS';
            AdicionaDados('ID', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela_CupomItem(tpLocal);
          end;
          AtualizaStatus('Enviado Itens do Cupom');

          while not QryDadosLocal.Eof do
          begin
//            AtualizaStatus('Enviado Itens do Cupom => ' + FieldByName('ID').AsString);
            with fDMPrincipal do
            begin
              vTabela := 'CUPOMFISCAL_ITENS';
              AdicionaDados('ID', IntToStr(vIDNovo));
              AdicionaDados('ITEM', QryDadosLocal.FieldByName('ITEM').AsString, false);
              QryDadosServer := Abrir_Tabela_CupomItem(tpServer);
            end;
            if QryDadosServer.IsEmpty then
              QryDadosServer.Insert
            else
              QryDadosServer.Edit;

            for i := 0 to QryDadosLocal.FieldCount - 1 do
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
              QryDadosServer.CachedUpdates := true;
              QryDadosServer.Post;
              QryDadosServer.ApplyUpdates(0);
            except
              on E: Exception do
              begin
                GravaLogErro('Erro Gravando Cupom Fiscal Item: ' + E.Message);
                QryDadosServer.Cancel;
                Erro := true;
                Application.ProcessMessages;
              end;
            end;
            QryDadosLocal.Next;
          end;

          // Gravar itens sem
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_ITENS_SEM';
            AdicionaDados('ID', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela(tpLocal);
          end;
          AtualizaStatus('Enviado Itens do Cupom Sem');

          while not QryDadosLocal.Eof do
          begin
//            AtualizaStatus('Enviado Itens do Cupom Sem => ' + FieldByName('ID').AsString);
            with fDMPrincipal do
            begin
              vTabela := 'CUPOMFISCAL_ITENS_SEM';
              AdicionaDados('ID', IntToStr(vIDNovo));
              AdicionaDados('ITEM', QryDadosLocal.FieldByName('ITEM').AsString, false);
              QryDadosServer := Abrir_Tabela(tpServer);
            end;
            if QryDadosServer.IsEmpty then
              QryDadosServer.Insert
            else
              QryDadosServer.Edit;

            for i := 0 to QryDadosLocal.FieldCount - 1 do
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
              QryDadosServer.CachedUpdates := true;
              QryDadosServer.Post;
              QryDadosServer.ApplyUpdates(0);
            except
              on E: Exception do
              begin
                GravaLogErro('Erro Gravando Cupom Fiscal Item Sem: ' + E.Message);
                QryDadosServer.Cancel;
                Erro := true;
                Application.ProcessMessages;
              end;
            end;
            QryDadosLocal.Next;
          end;

          // Gravar cupom parc
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_PARC';
            AdicionaDados('ID', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela_CupomParc(tpLocal);
          end;
          AtualizaStatus('Enviado Parcelas do Cupom');

          while not QryDadosLocal.Eof do
          begin
//            AtualizaStatus('Enviado Parcelas do Cupom => ' + FieldByName('ID').AsString);
            with fDMPrincipal do
            begin
              vTabela := 'CUPOMFISCAL_PARC';
              AdicionaDados('ID', IntToStr(vIDNovo));
              AdicionaDados('PARCELA', QryDadosLocal.FieldByName('PARCELA').AsString, false);
              QryDadosServer := Abrir_Tabela_CupomParc(tpServer);
            end;
            if QryDadosServer.IsEmpty then
              QryDadosServer.Insert
            else
              QryDadosServer.Edit;

            for i := 0 to QryDadosLocal.FieldCount - 1 do
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
              QryDadosServer.CachedUpdates := true;
              QryDadosServer.Post;
              QryDadosServer.ApplyUpdates(0);
            except
              on E: Exception do
              begin
                GravaLogErro('Erro Gravando Cupom Fiscal Parc: ' + E.Message);
                QryDadosServer.Cancel;
                Erro := true;
                Application.ProcessMessages;
              end;
            end;
            QryDadosLocal.Next;
          end;

          // Gravar cupom troca
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_TROCA';
            AdicionaDados('ID_CUPOM', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela(tpLocal);
          end;

          AtualizaStatus('Enviado Troca do Cupom');
          while not QryDadosLocal.Eof do
          begin
//            AtualizaStatus('Enviado Troca do Cupom => ' + FieldByName('ID').AsString);
            with fDMPrincipal do
            begin
              vTabela := 'CUPOMFISCAL_TROCA';
              AdicionaDados('ID_CUPOM', IntToStr(vIDNovo));
              AdicionaDados('ITEM', QryDadosLocal.FieldByName('ITEM').AsString, false);
              QryDadosServer := Abrir_Tabela(tpServer);
            end;
            if QryDadosServer.IsEmpty then
              QryDadosServer.Insert
            else
              QryDadosServer.Edit;

            for i := 0 to QryDadosLocal.FieldCount - 1 do
            begin
              try
                QryDadosServer.FindField(QryDadosLocal.Fields[i].FieldName).AsVariant :=
                  QryDadosLocal.Fields[i].AsVariant;
              except
                Application.ProcessMessages;
              end;
            end;
            try
              QryDadosServer.FieldByName('ID').AsInteger := fDMPrincipal.FDServer.ExecSQLScalar
                ('select gen_id(GEN_CUPOMFISCAL_TROCA,1) from rdb$database');
              QryDadosServer.FieldByName('ID_CUPOM').AsInteger := vIDNovo;
              if not CupomExiste then
                QryDadosServer.FieldByName('ID_MOVESTOQUE').Clear;
              QryDadosServer.CachedUpdates := true;
              QryDadosServer.Post;
              QryDadosServer.ApplyUpdates(0);
            except
              on E: Exception do
              begin
                GravaLogErro('Erro Gravando Cupom Fiscal Troca: ' + E.Message);
                QryDadosServer.Cancel;
                Erro := true;
                Application.ProcessMessages;
              end;
            end;
            QryDadosLocal.Next;
          end;

          // Gravar Cupom Fiscal FormaPagto
          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_FORMAPGTO';
            AdicionaDados('ID', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela(tpLocal);
          end;

          AtualizaStatus('Enviado Forma Pagto do Cupom');
          while not QryDadosLocal.Eof do
          begin
//            AtualizaStatus('Enviado Forma Pagto do Cupom => ' + FieldByName('ID').AsString);
            with fDMPrincipal do
            begin
              vTabela := 'CUPOMFISCAL_FORMAPGTO';
              AdicionaDados('ID', IntToStr(vIDNovo));
              AdicionaDados('ITEM', QryDadosLocal.FieldByName('ITEM').AsString, false);
              QryDadosServer := Abrir_Tabela(tpServer);
            end;
            if QryDadosServer.IsEmpty then
              QryDadosServer.Insert
            else
              QryDadosServer.Edit;

            for i := 0 to QryDadosLocal.FieldCount - 1 do
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
              QryDadosServer.CachedUpdates := true;
              QryDadosServer.Post;
              QryDadosServer.ApplyUpdates(0);
            except
              on E: Exception do
              begin
                GravaLogErro('Erro Gravando Cupom Fiscal Troca: ' + E.Message);
                QryDadosServer.Cancel;
                Erro := true;
                Application.ProcessMessages;
              end;
            end;
            QryDadosLocal.Next;
          end;

          with fDMPrincipal do
          begin
            vTabela := 'CUPOMFISCAL_PENDENTE';

//            FField := TIntegerField.Create(QryDadosServer);
//            FField.FieldName := 'ID';
//            FField.FieldKind := fkCalculated;
//            FField.ProviderFlags := [pfInUpdate, pfInWhere, pfInKey, pfHidden];
//
//            QryDadosServer.FieldDefs.Add(FField.FieldName, ftInteger);
            AdicionaDados('ID', 'NULL');
            QryDadosServer := Abrir_Tabela_CupomPendente(tpServer);
            QryDadosServer.Insert;
            QryDadosServer.FieldByName('ID_CUPOM').AsInteger := vIDNovo;
            QryDadosServer.FieldByName('ID_TERMINAL').AsString := fDMPrincipal.vTerminal;
            QryDadosServer.CachedUpdates := true;
            QryDadosServer.Post;
            QryDadosServer.ApplyUpdates(0);
          end;

          // Gravar Estoque
//          repeat
//            try
//              AtualizaStatus('Gravando Estoque => ' + FieldByName('ID').AsString);
//              fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_ESTOQUE(' +
//                IntToStr(vIDNovo) + ', ''CFI'')');
//              erroProcedure := false;
//            except
//              on E: Exception do

//              begin
//                GravaLogErro('Erro Gravando Movimento estoque nº: ' + IntToStr(vIDNovo));
//                fDMPrincipal.FDServer.Rollback;
//                erroProcedure := true;
//              end;
//            end;
//
//          until not erroProcedure;

          // Gravar Estoque Troca

//          repeat
//            try
//              AtualizaStatus('Gravando Estoque Troca  => ' + FieldByName('ID').AsString);
//              fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_ESTOQUE(' +
//                IntToStr(vIDNovo) + ', ''TRO'')');
//              erroProcedure := false
//            except
//              on E: Exception do
//              begin
//                GravaLogErro('Erro Gravando Movimento estoque nº: ' + IntToStr(vIDNovo));
//                fDMPrincipal.FDServer.Rollback;
//                erroProcedure := true;
//              end;
//            end;
//          until not erroProcedure;

          // Gravar Duplicata - Histórico - Comissão - Financeiro
//          try
//            AtualizaStatus('Gravando Duplicata => ' + FieldByName('ID').AsString);
//            fDMPrincipal.FDServer.ExecSQL('EXECUTE PROCEDURE PRC_GRAVAR_DUPLICATA_CUPOM(' +
//              QuotedStr('') + ', ' + IntToStr(vIDNovo) + ', ' + fDMPrincipal.vTerminal + ')');
//          except
//            on E: Exception do
//            begin
//              GravaLogErro('Erro Gravando Duplicata estoque nº: ' + IntToStr(vIDNovo));
//            end;
//          end;
          if not Erro then
          begin
            vTabela := 'CUPOMFISCAL_LOG';
            vCondicao := 'and ID = ' + FieldByName('ID').AsString + ' AND TIPO IN (0,1)' ;
            Apaga_Registro(fDMPrincipal.FDLocal, vTabela, true, vCondicao);
          end;
          FHoraFin := Now;
          GravaLogErro('Diferença: ' + TimeToStr(FHoraFin - FHoraIni));
          Next;
        end;
    end;
  finally
    FreeAndNil(QryDados_Log);
  end;
  AtualizaStatus('');
{$ENDREGION}
end;

function TfrmPrincipal.ImportaServidorTabelaProduto: Boolean;
var
  Erro, gravou: Boolean;
  vCondicao, vTabela: String;
  i: integer;
begin
try

{$REGION 'Inclui/Altera Clientes'}
  AtualizaStatus('Verificando Alterações em Clientes');
//  QryDados_Log.Close;
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  fDMPrincipal.vTabela := 'PESSOA_LOG';
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Cliente => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          AdicionaDados('CODIGO', FieldByName('ID').AsString);
          vTabela := 'PESSOA';
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;

        vTabela := 'PESSOA_LOG';
        vCondicao := 'and ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
        Next;
      end;
  end;
  QryDados_Log.Close;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera CST ICMS'}
  AtualizaStatus('Verificando Alterações em CST ICMS');
  fDMPrincipal.vTabela := 'TAB_CSTICMS_LOG';
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
        with fDMPrincipal do
        begin
          AdicionaDados('ID', FieldByName('ID').AsString);
          vTabela := 'TAB_CSTICMS';
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;
        QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;
        fDMPrincipal.vTabela := 'TAB_CSTICMS_LOG';
        vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, fDMPrincipal.vTabela, true, vCondicao);
        Next;
      end;
  end;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera NCM'}
  AtualizaStatus('Verificando Alterações em NCM');
  fDMPrincipal.vTabela := 'TAB_NCM_LOG';
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo NCM => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          AdicionaDados('ID', FieldByName('ID').AsString);
          vTabela := 'TAB_NCM';
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;
        QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;
        fDMPrincipal.vTabela := 'TAB_NCM_LOG';
        vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, fDMPrincipal.vTabela, true, vCondicao);
        Next;
      end;
  end;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera Unidade'}
  AtualizaStatus('Verificando Alterações em Unidades');
  fDMPrincipal.vTabela := 'UNIDADE';
  fDMPrincipal.AdicionaDados('', '');
  QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
  with QryDadosServer do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Unidade => ' + FieldByName('UNIDADE').AsString);

        with fDMPrincipal do
        begin
          AdicionaDados('UNIDADE', QuotedStr(FieldByName('UNIDADE').AsString));
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;

        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;
        Next;
      end;
  end;
  AtualizaStatus('');
  QryDadosLocal.Close;
  QryDadosServer.Close;
{$ENDREGION}
{$REGION 'Inclui/Altera Grupo'}
  AtualizaStatus('Verificando Alterações em Grupos');
  fDMPrincipal.vTabela := 'GRUPO';
  fDMPrincipal.AdicionaDados('', '');
  QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
  with QryDadosServer do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Grupos => ' + FieldByName('ID').AsString);

        with fDMPrincipal do
        begin
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;
        Next;
      end;
  end;
  AtualizaStatus('');
  QryDadosLocal.Close;
  QryDadosServer.Close;
{$ENDREGION}
{$REGION 'Inclui/Altera Marca'}
  AtualizaStatus('Verificando Alterações em Marcas');
  fDMPrincipal.vTabela := 'MARCA';
  fDMPrincipal.AdicionaDados('', '');
  QryDadosServer := fDMPrincipal.Abrir_Tabela(tpServer);
  with QryDadosServer do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Marcas => ' + FieldByName('ID').AsString);

        with fDMPrincipal do
        begin
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;
        Next;
      end;
  end;
  AtualizaStatus('');
  QryDadosLocal.Close;
  QryDadosServer.Close;
{$ENDREGION}
{$REGION 'Inclui/Altera Produto'}
  AtualizaStatus('Verificando Alterações em Produtos');
  fDMPrincipal.vTabela := 'PRODUTO_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log.Close;
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Produtos => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'PRODUTO';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal.Close;
          QryDadosLocal := Abrir_Tabela_Produto(tpLocal);
        end;

        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;
        QryDadosServer.Close;
//        QryDadosServer.FetchOptions.RowsetSize := 10;
        QryDadosServer := fDMPrincipal.Abrir_Tabela_Produto(tpServer);
        for i := 0 to QryDadosServer.FieldCount - 1 do
        begin
          try
            QryDadosLocal.FindField(QryDadosServer.Fields[i].FieldName).AsVariant :=
              QryDadosServer.Fields[i].AsVariant;
          except
            on E : Exception do
              TGravarLog.New.doSaveLog('Erro Produto: ' + e.Message);
          end;
        end;
        try
          QryDadosLocal.CachedUpdates := True;
          QryDadosLocal.Post;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          on E : Exception do
          begin
            QryDadosLocal.Cancel;
            Erro := true;
            Application.ProcessMessages;
            TGravarLog.New.doSaveLog('Erro Produto: ' + e.Message);
          end;
        end;
        fDMPrincipal.vTabela := 'PRODUTO_LOG';
        vCondicao := 'AND ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, fDMPrincipal.vTabela, true, vCondicao);
        Next;
      end;
  end;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera Tabela de Preço'}
  AtualizaStatus('Verificando Alterações em Tabela de Preço');
  fDMPrincipal.vTabela := 'TAB_PRECO_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Tabela de Preço => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'TAB_PRECO';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
          QryDadosServer := Abrir_Tabela(tpServer);
        end;

        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;

        // Gravar itens
        with fDMPrincipal do
        begin
          vTabela := 'TAB_PRECO_ITENS';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosServer := Abrir_Tabela(tpServer);
        end;
        while not QryDadosServer.Eof do
        begin
          AtualizaStatus('Recebendo Itens Tabela de Preço => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'TAB_PRECO_ITENS';
            AdicionaDados('ID', FieldByName('ID').AsString);
            AdicionaDados('ITEM', QryDadosServer.FieldByName('ITEM').AsString, false);
            QryDadosLocal := Abrir_Tabela(tpLocal);
          end;
          if QryDadosLocal.IsEmpty then
            QryDadosLocal.Insert
          else
            QryDadosLocal.Edit;
          for i := 0 to QryDadosServer.FieldCount - 1 do
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
            QryDadosLocal.CachedUpdates := true;
            QryDadosLocal.ApplyUpdates(0);
            Erro := false;
          except
            QryDadosLocal.Cancel;
            Erro := true;
            Application.ProcessMessages;
          end;
          QryDadosServer.Next;
        end;

        vTabela := 'TAB_PRECO_LOG';
        vCondicao := 'and ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
        Next;
      end;
  end;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera Condição de Pagamento'}
  AtualizaStatus('Verificando Alterações em Condição de Pagamento');
  fDMPrincipal.vTabela := 'CONDPGTO_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);
  with QryDados_Log do
  begin
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Condições de Pagto => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'CONDPGTO';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela(tpLocal);
          QryDadosServer := Abrir_Tabela(tpServer);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;
        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;

        // Gravar itens
        with fDMPrincipal do
        begin
          vTabela := 'CONDPGTO_DIA';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosServer := Abrir_Tabela(tpServer);
        end;
        while not QryDadosServer.Eof do
        begin
//          AtualizaStatus('Recebendo Itens Condições de Pagto => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'CONDPGTO_DIA';
            AdicionaDados('ID', FieldByName('ID').AsString);
            AdicionaDados('ITEM', QryDadosServer.FieldByName('ITEM').AsString, false);
            QryDadosLocal := Abrir_Tabela(tpLocal);
          end;
          if QryDadosLocal.IsEmpty then
            QryDadosLocal.Insert
          else
            QryDadosLocal.Edit;

          for i := 0 to QryDadosServer.FieldCount - 1 do
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
            QryDadosLocal.CachedUpdates := true;
            QryDadosLocal.ApplyUpdates(0);
            Erro := false;
          except
            QryDadosLocal.Cancel;
            Erro := true;
            Application.ProcessMessages;
          end;
          QryDadosServer.Next;
        end;
        vTabela := 'CONDPGTO_LOG';
        vCondicao := 'and ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
        Next;
      end;
  end;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera Parametros'}
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
    if not(IsEmpty) then
      while not Eof do
      begin
//        AtualizaStatus('Recebendo Parâmetros => ' + FieldByName('ID').AsString);
        with fDMPrincipal do
        begin
          vTabela := 'PARAMETROS';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosLocal := Abrir_Tabela_Parametro(tpLocal);
          QryDadosServer := Abrir_Tabela_Parametro(tpServer);
        end;
        if QryDadosLocal.IsEmpty then
          QryDadosLocal.Insert
        else
          QryDadosLocal.Edit;

        for i := 0 to QryDadosServer.FieldCount - 1 do
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
          QryDadosLocal.CachedUpdates := true;
          QryDadosLocal.ApplyUpdates(0);
          Erro := false;
        except
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;

        // Gravar Parametros Financeiro

        with fDMPrincipal do
        begin
          vTabela := 'PARAMETROS_FIN';
          AdicionaDados('ID', FieldByName('ID').AsString);
          QryDadosServer := Abrir_Tabela(tpServer);
        end;
        while not QryDadosServer.Eof do
        begin
//          AtualizaStatus('Recebendo Parâmetros Financeiro => ' + FieldByName('ID').AsString);
          with fDMPrincipal do
          begin
            vTabela := 'PARAMETROS_FIN';
            AdicionaDados('ID', FieldByName('ID').AsString);
            QryDadosLocal := Abrir_Tabela(tpLocal);
          end;

          if QryDadosLocal.IsEmpty then
            QryDadosLocal.Insert
          else
            QryDadosLocal.Edit;

          for i := 0 to QryDadosServer.FieldCount - 1 do
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
            QryDadosLocal.CachedUpdates := true;
            QryDadosLocal.ApplyUpdates(0);
            Erro := false;
          except
            QryDadosLocal.Cancel;
            Erro := true;
            Application.ProcessMessages;
          end;
          QryDadosServer.Next;
        end;

        vTabela := 'PARAMETROS_LOG';
        vCondicao := 'and ID = ' + FieldByName('ID').AsString;
        Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
        Next;
      end;
  end;
  AtualizaStatus('');
{$ENDREGION}
{$REGION 'Inclui/Altera Tipo Cobrança'}

  AtualizaStatus('Verificando Alterações em Tipo Cobrança');
  fDMPrincipal.vTabela := 'TIPOCOBRANCA_LOG';
  fDMPrincipal.ListaTipo.Clear;
  fDMPrincipal.ListaTipo.Add('0');
  fDMPrincipal.ListaTipo.Add('1');
  QryDados_Log := fDMPrincipal.Abrir_Tabela_Log(tpServer);

  with QryDados_Log do
  begin
    if not(IsEmpty) then
    while not Eof do
    begin
//      AtualizaStatus('Recebendo Tipo Cobranca => ' + FieldByName('ID').AsString);
      with fDMPrincipal do
      begin
        vTabela := 'TIPOCOBRANCA';
        AdicionaDados('ID', FieldByName('ID').AsString);
        QryDadosLocal := Abrir_Tabela(tpLocal);
        QryDadosServer := Abrir_Tabela(tpServer);
      end;

      if QryDadosLocal.IsEmpty then
        QryDadosLocal.Insert
      else
        QryDadosLocal.Edit;

      for i := 0 to QryDadosServer.FieldCount - 1 do
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
        QryDadosLocal.CachedUpdates := true;
        QryDadosLocal.ApplyUpdates(0);
        Erro := false;
      except
        on E: Exception do
        begin
          GravaLogErro('Erro gravando tipo cobranca ' + e.Message);
          QryDadosLocal.Cancel;
          Erro := true;
          Application.ProcessMessages;
        end;
      end;
      vTabela := 'TIPOCOBRANCA_LOG';
      vCondicao := 'and ID = ' + FieldByName('ID').AsString;
      Apaga_Registro(fDMPrincipal.FDServer, vTabela, true, vCondicao);
      Next;
    end;
    AtualizaStatus('');
    QryDadosLocal.Close;
    QryDadosServer.Close;
  end;
{$ENDREGION}
except
  on E: Exception do
    begin
//      Finaliza_Processo;
    end;
end;
end;

procedure TfrmPrincipal.Finaliza_Processo;
begin
  try
  if Assigned(QryDados_Log) then
    FreeAndNil(QryDados_Log);
  except

  end;

  if Assigned(QryDadosLocal) then
    QryDadosLocal.Free;

  if Assigned(QryDadosServer) then
    QryDadosServer.Free;

  fDMPrincipal.desconectar;

  if Assigned(fDMPrincipal) then
    FreeAndNil(fDMPrincipal);

end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//  FTerminate := True;
  Application.Minimize;
  Action := caNone;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  top := Screen.Height - Height - 50;
  left := Screen.Width - Width;
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
var
  aVersao: TVersao;
begin
  aVersao := TVersao.Create;
  try
    Self.Caption := 'SSIntegradorPDV v.' + aVersao.GetBuildInfo(Application.ExeName);
  finally
    aVersao.Free;
  end;
end;

procedure TfrmPrincipal.Inicia_Processso;
var
  ArquivoIni: String;
  ImpressoraIni: String;
  BaseLocal, DriverName, UserName, PassWord: String;
  BaseServer, DriverNameServer, UserNameServer, PassWordServer, IP: String;
  Local, Posicao: integer;
  Configuracoes: TIniFile;
  ConfigImpressora: TIniFile;
  Decoder64: TIdDecoderMIME;
  Encoder64: TIdEncoderMIME;
begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  fDMPrincipal := TDMPrincipal.Create(nil);
  AtualizaStatus('Aguardando configurações');
  Decoder64 := TIdDecoderMIME.Create(nil);
  ArquivoIni := ExtractFilePath(Application.ExeName) + '\Config.ini';
  ImpressoraIni := 'C:\$Servisoft\Impressora.ini';
  if not FileExists(ArquivoIni) then
  begin
    TGravarLog.New.doSaveLog('Arquivo config.ini não encontrado!');
    Exit;
  end;
  if not FileExists(ImpressoraIni) then
  begin
    TGravarLog.New.doSaveLog('Arquivo Impressora.ini não encontrado!');
    Exit;
  end;

  ConfigImpressora := TIniFile.Create(ImpressoraIni);
  try
    fDMPrincipal.vTerminal := ConfigImpressora.ReadString('IMPRESSORA', 'Terminal', '');
  finally
    ConfigImpressora.Free;
  end;

  Configuracoes := TIniFile.Create(ArquivoIni);
  try
    BaseLocal := Configuracoes.ReadString('SSFacil', 'DATABASE', '');
    DriverName := Configuracoes.ReadString('SSFacil', 'DriverName', '');
    UserName := Configuracoes.ReadString('SSFacil', 'UserName', '');
    PassWord := Decoder64.DecodeString(Configuracoes.ReadString('SSFacil', 'PASSWORD', ''));

    BaseServer := Configuracoes.ReadString('SSFacil_Servidor', 'DATABASE', '');
    DriverNameServer := Configuracoes.ReadString('SSFacil_Servidor', 'DriverName', '');
    UserNameServer := Configuracoes.ReadString('SSFacil_Servidor', 'UserName', '');
    Posicao := Pos(':', BaseServer);
    IP := Copy(BaseServer, 1, Posicao - 1);
    BaseServer := Copy(BaseServer, Posicao + 1, Length(BaseServer));
    // IP := Configuracoes.ReadString('SSFacil_Servidor','IP','');
    PassWordServer := Decoder64.DecodeString(Configuracoes.ReadString('SSFacil_Servidor',
      'PASSWORD', ''));
    vTempoCiclo := StrToInt(Configuracoes.ReadString('SSFacil_Servidor', 'TempoCiclo', '20000'));
  finally
    Configuracoes.Free;
    Decoder64.Free;
  end;

  fDMPrincipal.FDLocal.Connected := false;
  fDMPrincipal.FDLocal.Params.Clear;
  fDMPrincipal.FDLocal.DriverName := 'FB';
  fDMPrincipal.FDLocal.Params.Values['DriveId'] := 'FB';
  fDMPrincipal.FDLocal.Params.Values['DataBase'] := BaseLocal;
  fDMPrincipal.FDLocal.Params.Values['User_Name'] := UserName;
  fDMPrincipal.FDLocal.Params.Values['Password'] := PassWord;

  fDMPrincipal.FDServer.Connected := false;
  fDMPrincipal.FDServer.Params.Clear;
  fDMPrincipal.FDServer.DriverName := 'FB';
  fDMPrincipal.FDServer.Params.Values['DriveId'] := 'FB';
  fDMPrincipal.FDServer.Params.Values['Database'] := BaseServer;
  fDMPrincipal.FDServer.Params.Values['Server'] := IP;
  fDMPrincipal.FDServer.Params.Values['User_Name'] := UserNameServer;
  fDMPrincipal.FDServer.Params.Values['Password'] := PassWordServer;

  Timer.Interval := vTempoCiclo;
  lblTerminal.Caption := 'Terminal: ' + fDMPrincipal.vTerminal;
  lblLocal.Caption := BaseLocal;
  lblLocal.Update;
  lblServidor.Caption := BaseServer;
  lblServidor.Update;
//  QryDados_Log := TFDQuery.Create(nil);

//  QryDadosLocal := TFDQuery.Create(nil);
//  QryDadosLocal.Connection := fDMPrincipal.FDLocal;

//  QryDadosServer := TFDQuery.Create(nil);
//  QryDadosServer.Connection := fDMPrincipal.FDServer;

end;

procedure TfrmPrincipal.GravaLogErro(Erro: String);
const
  Arquivo = 'c:\$Servisoft\Log_Integracao.txt';
var
  vLog: TextFile;
begin
  try
    AssignFile(vLog, Arquivo);
    if not FileExists(Arquivo) then
      Rewrite(vLog, Arquivo);
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
  TrayIcon.Animate := true;
  Timer.Enabled := false;
  try
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
      lblUltimaAtualizacao.Caption := FormatDateTime('dd/mm/yyyy - hh:mm:ss ', Now);
      Application.ProcessMessages;
      TrayIcon.Animate := false;
      Timer.Enabled := true;
      Finaliza_Processo;
      Exit;
    end;
  finally
    Finaliza_Processo;
    Application.Title := 'Aguardando Proximo Ciclo';
    lblStatus.Caption := 'Aguardando Proximo Ciclo';
    lblStatus.Update;
    lblUltimaAtualizacao.Caption := FormatDateTime('dd/mm/yyyy - hh:mm:ss ', Now);
    Application.ProcessMessages;
    TrayIcon.Animate := false;
    Timer.Enabled := true;
  end;
end;

procedure TfrmPrincipal.LongRunningTask(TerminatingEvent: TEvent);
begin
  try
    Inicia_Processso;
    // Verifica se o evento de término foi sinalizado
    if TerminatingEvent.WaitFor(0) = wrSignaled then
      Exit; // Se foi sinalizado, sai da thread antes de completar o trabalho
  finally
    TerminatingEvent.Free;
  end;
end;

procedure TfrmPrincipal.TimerMinimizeTimer(Sender: TObject);
begin
  TimerMinimize.Enabled := False;
  ApplicationEvents1Minimize(Sender);
end;

procedure TfrmPrincipal.TimerTimer(Sender: TObject);
begin
  FTerminate := False;
  var TerminatingEvent := TEvent.Create;
  LThread := TThread.CreateAnonymousThread(
    procedure
    begin
      TrayIcon.Animate := true;
      Timer.Enabled := false;
      TThread.Synchronize(TThread.CurrentThread,
        procedure()
        begin
          AtualizaStatus('Estabelecendo conexões...');
          LongRunningTask(TerminatingEvent);
//          Inicia_Processso;
          if not fDMPrincipal.conectar then
          begin
            AtualizaStatus('Falha na Conexão...');
            shpLocal.Brush.Color := clRed;
            shpServidor.Brush.Color := clRed;
          end
          else
          begin
            shpLocal.Brush.Color := clLime;
            shpServidor.Brush.Color := clLime;

          end;
        end);
      ApagaRegistrosExcluidosNoServidor;
      ImportaServidorTabelaProduto;
      ExportaMovimentosPDV;
      ExcluirRegistroServidor;
    end);
  LThread.OnTerminate := FinalizaThread;
  LThread.Start;
end;

procedure TfrmPrincipal.TrayIconDblClick(Sender: TObject);
begin
  TrayIcon.Visible := false;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

procedure TfrmPrincipal.FinalizaThread(Sender: TObject);
begin
  if Assigned(TThread(Sender).FatalException) then
    TGravarLog.New.doSaveLog(Exception(TThread(Sender).FatalException).Message);
  Finaliza_Processo;
  AtualizaStatus('Aguardando Proximo Ciclo');
  lblUltimaAtualizacao.Caption := FormatDateTime('dd/mm/yyyy - hh:mm:ss ', Now);
  TrayIcon.Animate := false;
  FTerminate := true;
  Timer.Enabled := true;
end;

end.
