unit uAgentThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TAgentThread = class(TThread)
  private
    FCheckTime: String;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  uGlobal;

constructor TAgentThread.Create;
begin
  FCheckTime := '';

  Global.Log.LogWrite('TAgentThread Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TAgentThread.Destroy;
begin

  inherited;
end;

procedure TAgentThread.Execute;
var
  sLogMsg: String;
begin
  inherited;

  while not Terminated do
  begin
    try

      Synchronize(Global.TcpAgentServer.SendTeeboxStatus);

      Sleep(200);
    except
      on e: Exception do
      begin
        sLogMsg := 'TAgentThread Error : ' + e.Message;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
