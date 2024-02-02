unit uRoomThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TRoomThread = class(TThread)
  private
    //Cnt: Integer;
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

constructor TRoomThread.Create;
begin
  //Cnt := 0;
  Cnt1 := 0;
  //FCheckCnt := 0;
  //FCheckTime := '';
  //FCloseSend := 'N';

  Global.Log.LogWrite('TRoomThread Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TRoomThread.Destroy;
begin

  inherited;
end;

procedure TRoomThread.Execute;
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
      end;

      inc(Cnt1);

      if Cnt1 > 60 then
      begin
        //룸 배정내역 ERP 요청
        Synchronize(Global.Room.GetRoomReserveApi);

        //배정내역 확인
        Synchronize(Global.Room.RoomReserveApiChk);

        //시간계산
        Synchronize(Global.Room.RoomReserveChk);

        //상태체크
        Synchronize(Global.Room.RoomStatusChk);
        {
        //tapo on/off 상태 확인/ GetDeviceInfo
        Synchronize(Global.Room.RoomTapoOnOffCheck);

        //tapo on/off 확인/ SetDeviceOnOff
        Synchronize(Global.Room.RoomTapoOnOff);
        }
        Cnt1 := 0;
      end;

      Sleep(1000);
    except
      on e: Exception do
      begin
        sLogMsg := 'TRoomThread Error : ' + e.Message;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
