unit uTeeboxThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TTeeboxThread = class(TThread)
  private
    Cnt: Integer;
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

      if (Global.ADConfig.ProtocolType = 'JMS') or (Global.ADConfig.ProtocolType = 'MODENYJ') then
      //if (Global.ADConfig.ProtocolType = 'JMS') then
      begin
        //타석 상태저장
        Synchronize(Global.Teebox.TeeboxStatusChkJMS);

        //타석기 배정제어
        Synchronize(Global.Teebox.TeeboxReserveChkJMS);
      end
      else
      begin
        //타석 상태저장
        Synchronize(Global.Teebox.TeeboxStatusChk);

        //타석기 배정제어
        Synchronize(Global.Teebox.TeeboxReserveChk);
      end;

      if Global.ADConfig.StoreCode = 'A7001' then //반자동
      begin
        //타석 상태저장
        Synchronize(Global.Teebox.TeeboxStatusChkVictoria);

        //타석기 배정제어
        Synchronize(Global.Teebox.TeeboxReserveChkVictoria);
      end;

      inc(Cnt);
      if Cnt > 15 then
      begin
        //타석기 홀드리렛
        //Synchronize(Global.Seat.SeatHoldReset);

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

        //전송실패 재시도
        if Global.ADConfig.Emergency = False then
          Synchronize(Global.Teebox.SendApiErrorRetry);

        Cnt := 0;
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
