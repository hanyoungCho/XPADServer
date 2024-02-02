unit uTeeboxThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TTeeboxThread = class(TThread)
  private
    Cnt: Integer;
    Cnt_1: Integer;
    FCheckTime: String;
    //FCloseSend: String;
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
  Cnt_1 := 5;
  FCheckTime := '';
  //FCloseSend := 'N';

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
  sStr: string;
begin
  inherited;

  while not Terminated do
  begin
    try

      Synchronize(Global.TeeboxThreadTimeCheck);

      //Agent 9004 전송
      if Global.ADConfig.AgentSendUse = True then
      begin
        Synchronize(Global.TcpAgentServer.SendTeeboxStatus);
        Synchronize(Global.TcpAgentServer.SendAgentSetting);
      end;

      inc(Cnt_1);
      if Cnt_1 > 4 then
      begin
        //DNS Ping
        if Global.ADConfig.NetCheck = True then
          Synchronize(Global.DNSPingCheck);

        //타석기 배정제어
        sStr := 'TeeboxReserveChkAD';
        Synchronize(Global.Teebox.TeeboxReserveChkAD);

        //타석 상태저장
        sStr := 'TeeboxStatusChkAD';
        Synchronize(Global.Teebox.TeeboxStatusChkAD);

        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //빔프로젝트 종료 제어
          Synchronize(Global.Teebox.SendBeamEnd);

          //빔프로젝트 시작후 20/40초후 재제어
          Synchronize(Global.Teebox.SendBeamStartReCtl);
        end;

        Cnt_1 := 0;
      end;

      inc(Cnt);
      if Cnt > 15 then
      begin

        if Global.ADConfig.Emergency = False then
        begin
          //타석기 구동확인용-> ERP 전송
          Synchronize(Global.Teebox.SendADStatusToErp);
        end;

        //다음 예약확인
        sStr := 'TeeboxReserveNextChkAD';
        Synchronize(Global.Teebox.TeeboxReserveNextChkAD);

        if Global.ADConfig.Emergency = False then
        begin
          //Kiosk 상태확인
          if global.Store.ACS = 'Y' then
            Synchronize(Global.KioskTimeCheck);
        end;

        //전송실패 재시도
        if Global.ADConfig.Emergency = False then
          Synchronize(Global.Teebox.SendApiErrorRetry);
        {
        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //빔프로젝트 종료 제어
          Synchronize(Global.Teebox.SendBeamEnd);

          //빔프로젝트 시작후 20/40초후 재제어
          Synchronize(Global.Teebox.SendBeamStartReCtl);
        end;
        }
        Cnt := 0;
      end;

      Sleep(1000);
    except
      on e: Exception do
      begin
        sLogMsg := 'TTeeboxThread Error : ' + sStr + ' / ' + e.Message;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
