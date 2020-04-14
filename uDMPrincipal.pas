unit uDMPrincipal;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
  FireDAC.Comp.DataSet;

type
  TDMPrincipal = class(TDataModule)
    qryConsultaTabelaLocal: TFDQuery;
    qryConsultaTabelaServer: TFDQuery;
    qryApagaLocal: TFDQuery;
    qryConsultaLocal: TFDQuery;
    qryLocalUpdate: TFDQuery;
    FDLocal: TFDConnection;
    FDServer: TFDConnection;
    qryApagaServer: TFDQuery;
    qryServerUpdate: TFDQuery;
    qryConsultaServidor: TFDQuery;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DMPrincipal: TDMPrincipal;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
