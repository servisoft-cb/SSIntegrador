unit Classe.Thread;

interface

uses
  System.SysUtils;

type
  TProcedureExcept = reference to procedure(const AException: String);

  TCustomThread = class
  private
  public
    constructor Create;
    destructor Destroy; override;
    procedure CustomThread(
              AOnStart,
              AOnProcess,
              AOnComplete: TProc;
              AOnError: TProcedureExcept;
              Const ADoCompleteWithError: Boolean);
  end;

implementation

uses
  System.Classes;

{ TCustomThread }

constructor TCustomThread.Create;
begin

end;

procedure TCustomThread.CustomThread(AOnStart, AOnProcess, AOnComplete: TProc;
  AOnError: TProcedureExcept; const ADoCompleteWithError: Boolean);
var
  LThread : TThread;
begin
  LThread :=
    TThread.CreateAnonymousThread(
      procedure ()
      var
        LDoComplete : Boolean;
      begin
         try
           try
           {$Region 'Processo Completo'}
             LDoComplete := True;
             {$Region 'OnStart'}
               if Assigned(AOnStart) then
               begin
                 TThread.Synchronize(
                   TThread.CurrentThread,
                   procedure()
                   begin
                     AOnStart;
                   end);
               end;
             {$EndRegion}

             {$Region 'OnProcess'}
               if Assigned(AOnProcess) then
                 AOnProcess;
             {$EndRegion}

           {$EndRegion}

           except on E:Exception do
             begin
               {$Region 'onError'}
               LDoComplete := ADoCompleteWithError;
               if Assigned(AOnError) then
               begin
                 TThread.Synchronize(
                   TThread.CurrentThread,
                   procedure()
                   begin
                     AOnError(e.Message);
                   end
                 );
               end;
               {$EndRegion}
             end;
           end;
         finally
           {$Region 'onComplete'}
           if Assigned(AOnComplete) then
           begin
             TThread.Synchronize(
               TThread.CurrentThread,
               procedure()
               begin
                 AOnComplete;
               end);
           end;
           {$EndRegion}
         end;
      end);
//    LThread.OnTerminate :=
    LThread.Start;
end;

destructor TCustomThread.Destroy;
begin

  inherited;
end;

end.
