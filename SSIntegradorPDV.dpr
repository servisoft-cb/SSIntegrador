program SSIntegradorPDV;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  Vcl.Themes,
  Vcl.Styles,
  uDMPrincipal in 'uDMPrincipal.pas' {DMPrincipal: TDataModule},
  Classe.Campos in 'Classe.Campos.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
