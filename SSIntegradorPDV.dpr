program SSIntegradorPDV;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  Vcl.Themes,
  Vcl.Styles,
  Windows,
  System.Variants,
  uDMPrincipal in 'uDMPrincipal.pas' {DMPrincipal: TDataModule},
  Classe.Campos in 'Classe.Campos.pas',
  System.SysUtils,
  SmartPoint in 'SmartPoint.pas';

{$R *.res}
var
  hMapping: hwnd;
begin
  Application.Initialize;
  hMapping := CreateFileMapping(HWND($FFFFFFFF), nil, PAGE_READONLY, 0, 32, PChar(ExtractFileName(Application.ExeName)));
  if (hMapping <> Null) and (GetLastError <> 0) then
  begin
    Application.MessageBox('Aplicativo já se encontra em execução !','Atenção',MB_OK);
    Halt;
  end;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
