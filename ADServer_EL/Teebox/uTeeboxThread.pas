unit uTeeboxThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TTeeboxThread = class(TThread)
  private
    Cnt: Integer;
    Cnt1: Integer;
    FCheckTime: String;
    FCloseSend: String;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    property CheckTime: String read FCheckTime write FCheckTime;
  end;

implementation

uses
  uGlobal;

constructor TTeeboxThread.Create;
begin
  Cnt := 0;
  FCheckTime := '';
  FCloseSend := 'N';

  Global.Log.LogWrite('TTeeboxThread Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TTeeboxThread.Destroy;
begin

  inherited;
end;

procedure TTeeboxThread.Execute;
var
  sLogMsg: String;
begin
  inherited;

  while not Terminated do
  begin
    try

      Synchronize(Global.TeeboxThreadTimeCheck);

      //Agent 9004 전송
      if Global.ADConfig.AgentSendUse = 'Y' then
      begin
        Synchronize(Global.TcpAgentServer.SendTeeboxStatus);
      end;

      //agent 미응답시 재시도1회
      if Global.ADConfig.AgentSendUse <> 'Y' then
        Synchronize(Global.Teebox.TeeboxAgentChk);

      //타석기 배정제어
      Synchronize(Global.Teebox.TeeboxReserveChk);

      //타석 상태저장
      Synchronize(Global.Teebox.TeeboxStatusChk);

      inc(Cnt);
      inc(Cnt1);
      if Cnt > 15 then
      begin
        //다음 예약확인
        Synchronize(Global.Teebox.TeeboxReserveNextChk);

        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //빔프로젝트 종료 제어
          Synchronize(Global.Teebox.SendBeamEnd);

          //빔프로젝트 시작후 30초후 재제어
          Synchronize(Global.Teebox.SendBeamStartReCtl);
        end;

        Cnt := 0;
      end;

      if Global.ADConfig.XGMTapoUse = 'Y' then
      begin
        if Cnt1 > 60 then
        begin

          //XGM Tapo 상태 확인
          //Synchronize(Global.Teebox.TeeboxTapoXGMSTatus);

          Cnt1 := 0;
        end;
      end
      else
      begin
        if Cnt1 > 30 then
        begin

          //tapo on/off 확인
          Synchronize(Global.Teebox.TeeboxTapoOnOff);

          Cnt1 := 0;
        end;
      end;

      Sleep(1000);
    except
      on e: Exception do
      begin
        sLogMsg := 'TTeeboxThread Error : ' + e.Message;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
