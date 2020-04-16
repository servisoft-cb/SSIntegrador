unit TrataException;

interface

uses
  System.SysUtils, System.Classes;

type
  TException = class
    private
      FLogFile : String;
    public
      constructor Create;
      procedure TrataException(Sender : TObject; E : Exception);
      procedure GravarLog(Value : String);
  end;

implementation

uses
  Forms;

{ TException }

constructor TException.Create;
begin
  FLogFile := ChangeFileExt(ParamStr(0),'.log');
  Application.OnException := TrataException;
end;

procedure TException.GravarLog(Value: String);
var
  txtLog : TextFile;
begin
  AssignFile(txtLog, FLogFile);
  if FileExists(FLogFile) then
    Append(txtLog)
  else
    Rewrite(txtLog);
  Writeln(txtLog, FormatDateTime('dd/mm/YY hh:nn:ss - ',Now) + Value);
  CloseFile(txtLog);
end;

procedure TException.TrataException(Sender: TObject; E: Exception);
begin
  if TComponent(Sender) is TForm then
  begin
    GravarLog('Formulário: ' + TForm(Sender).Name);
    GravarLog('Caption: ' + TForm(Sender).Caption);
    GravarLog('Erro: ' + e.ClassName);
    GravarLog('Erro: ' + e.Message);
  end
  else
  begin
    GravarLog('Formulário: ' + TForm(TComponent(Sender).Owner).Name);
    GravarLog('Caption: ' + TForm(TComponent(Sender).Owner).Caption);
    GravarLog('Erro: ' + e.ClassName);
    GravarLog('Erro: ' + e.Message);
  end;
  GravarLog('================================');
end;

var
  Excessoes : TException;
initialization
  Excessoes := TException.Create;
finalization
  Excessoes.Free;
end.
