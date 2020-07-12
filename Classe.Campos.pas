unit Classe.Campos;

interface

uses
  Data.DB, System.Generics.Collections, Dialogs;

type
  TCampos = class
  private
    FField: TFieldType;
    FValor : string;
    FCampo: string;
  public
    constructor Create;
    destructor Destroy; Override;
    property Campo : string read FCampo write Fcampo;
    property Valor : string read FValor write FValor;
    property Field : TFieldType read FField write FField;
  end;

implementation

{ TCampos }

constructor TCampos.Create;
begin
end;

destructor TCampos.Destroy;
begin
  inherited;

end;

end.

