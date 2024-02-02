unit uTeeboxThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TTeeboxThread = class(TThread)
  private
    Cnt: Integer;
    Cnt1: Integer;
    //FCheckCnt: Integer;
    //FCheckTime: String;
    //FCloseSend: String;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    //property CheckTime: String read FCheckTime write FCheckTime;
  end;

implementation

uses
  uGlobal;

constructor TTeeboxThread.Create;
begin
  Cnt := 0;
  Cnt1 := 0;
  //FCheckCnt := 0;
  //FCheckTime := '';
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

      //agent 미응답시 재시도1회
      //Synchronize(Global.Teebox.TeeboxAgentChk);

      //타석기 배정제어
      Synchronize(Global.Teebox.TeeboxReserveChk);

      //타석 상태저장
      Synchronize(Global.Teebox.TeeboxStatusChk);

      inc(Cnt);
      inc(Cnt1);
      //inc(FCheckCnt);
      if Cnt > 15 then
      begin

        if Global.ADConfig.Emergency = False then
        begin
          //타석기 구동확인용-> ERP 전송
          Synchronize(Global.Teebox.SendADStatusToErp);
        end;

        //다음 예약확인
        Synchronize(Global.Teebox.TeeboxReserveNextChk);

        if Global.ADConfig.Emergency = False then
        begin
          //Kiosk 상태확인
          if global.Store.ACS = 'Y' then
            Synchronize(Global.KioskTimeCheck);
        end;
        {
        //tapo 제어 재시도 - 2022-10-07
        if Global.Tapo <> nil then
          Synchronize(Global.Tapo.SetDeviceOnOffErrorRetry);
        }
        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //빔프로젝트 종료 제어
          Synchronize(Global.Teebox.SendBeamEnd);

          //빔프로젝트 시작후 30초후 재제어
          Synchronize(Global.Teebox.SendBeamStartReCtl);
        end;

        Cnt := 0;
      end;

      //카운트숫자 변경 - 2023-02-10
      if Cnt1 > 90 then
      begin
        //tapo 제어 재시도 - 2022-10-07
        if Global.Tapo <> nil then
          Synchronize(Global.Tapo.SetDeviceOnOffErrorRetry);

        Cnt1 := 0;
      end;

      { // 2022-10-06 tapo 상태체크 제외-이종섭차장 요청
      if Global.ADConfig.TapoStatus = True then
      begin
        if Global.ADConfig.XGM_TapoUse <> 'Y' then
        begin
          if Cnt1 > 60 then
          begin
            //tapo on/off 상태 확인/ GetDeviceInfo
            Synchronize(Global.Teebox.TeeboxTapoOnOffCheck);

            //tapo on/off 확인/ SetDeviceOnOff
            Synchronize(Global.Teebox.TeeboxTapoOnOff);

            Cnt1 := 0;
          end;
        end;
      end;
      }
      {
      if FCheckCnt > 300 then
      begin
        //tapo on/off 상태 확인
        Synchronize(Global.Teebox.TeeboxTapoOnOffCheck);

        FCheckCnt := 0;
      end;
      }

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
