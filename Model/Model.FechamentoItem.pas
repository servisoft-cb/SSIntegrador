unit Model.FechamentoItem;

interface

function GetFechamentoItem : String;

implementation

uses
  System.Classes;

function GetFechamentoItem : String;
var
  FSQL : TStringList;
begin
  FSQL := TStringList.Create;
  try
    FSQL.Clear;
    FSQL.Add('select ID, ITEM, ID_TIPOCOBRANCA, VLR_ENTRADA, VLR_SAIDA, ');
    FSQL.Add('VLR_SALDO, VLR_INFORMADO, NOME_TIPOCOBRANCA, VLR_CONFERENCIA, ');
    FSQL.Add('VLR_DIF_INFORMADO, VLR_DIF_CONFERIDO, VLR_NAO_FATURADO, VLR_RECEBIMENTO ');
    FSQL.Add('from FECHAMENTO_ITENS');
    FSQL.Add('WHERE 0 = 0 ');
    Result := FSQL.Text;
  finally
    FSQL.Free;
  end;
end;

end.
