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

      //Agent 9004 ����
      if Global.ADConfig.AgentSendUse = True then
      begin
        Synchronize(Global.TcpAgentServer.SendTeeboxStatus);
        Synchronize(Global.TcpAgentServer.SendAgentSetting);
      end;

      //agent ������� ��õ�1ȸ
      //Synchronize(Global.Teebox.TeeboxAgentChk);

      //Ÿ���� ��������
      Synchronize(Global.Teebox.TeeboxReserveChk);

      //Ÿ�� ��������
      Synchronize(Global.Teebox.TeeboxStatusChk);

      inc(Cnt);
      inc(Cnt1);
      //inc(FCheckCnt);
      if Cnt > 15 then
      begin

        if Global.ADConfig.Emergency = False then
        begin
          //Ÿ���� ����Ȯ�ο�-> ERP ����
          Synchronize(Global.Teebox.SendADStatusToErp);
        end;

        //���� ����Ȯ��
        Synchronize(Global.Teebox.TeeboxReserveNextChk);

        if Global.ADConfig.Emergency = False then
        begin
          //Kiosk ����Ȯ��
          if global.Store.ACS = 'Y' then
            Synchronize(Global.KioskTimeCheck);
        end;
        {
        //tapo ���� ��õ� - 2022-10-07
        if Global.Tapo <> nil then
          Synchronize(Global.Tapo.SetDeviceOnOffErrorRetry);
        }
        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //��������Ʈ ���� ����
          Synchronize(Global.Teebox.SendBeamEnd);

          //��������Ʈ ������ 30���� ������
          Synchronize(Global.Teebox.SendBeamStartReCtl);
        end;

        Cnt := 0;
      end;

      //ī��Ʈ���� ���� - 2023-02-10
      if Cnt1 > 90 then
      begin
        //tapo ���� ��õ� - 2022-10-07
        if Global.Tapo <> nil then
          Synchronize(Global.Tapo.SetDeviceOnOffErrorRetry);

        Cnt1 := 0;
      end;

      { // 2022-10-06 tapo ����üũ ����-���������� ��û
      if Global.ADConfig.TapoStatus = True then
      begin
        if Global.ADConfig.XGM_TapoUse <> 'Y' then
        begin
          if Cnt1 > 60 then
          begin
            //tapo on/off ���� Ȯ��/ GetDeviceInfo
            Synchronize(Global.Teebox.TeeboxTapoOnOffCheck);

            //tapo on/off Ȯ��/ SetDeviceOnOff
            Synchronize(Global.Teebox.TeeboxTapoOnOff);

            Cnt1 := 0;
          end;
        end;
      end;
      }
      {
      if FCheckCnt > 300 then
      begin
        //tapo on/off ���� Ȯ��
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
