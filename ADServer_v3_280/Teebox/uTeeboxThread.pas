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

      //Agent 9004 ����
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

        //Ÿ���� ��������
        sStr := 'TeeboxReserveChkAD';
        Synchronize(Global.Teebox.TeeboxReserveChkAD);

        //Ÿ�� ��������
        sStr := 'TeeboxStatusChkAD';
        Synchronize(Global.Teebox.TeeboxStatusChkAD);

        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //��������Ʈ ���� ����
          Synchronize(Global.Teebox.SendBeamEnd);

          //��������Ʈ ������ 20/40���� ������
          Synchronize(Global.Teebox.SendBeamStartReCtl);
        end;

        Cnt_1 := 0;
      end;

      inc(Cnt);
      if Cnt > 15 then
      begin

        if Global.ADConfig.Emergency = False then
        begin
          //Ÿ���� ����Ȯ�ο�-> ERP ����
          Synchronize(Global.Teebox.SendADStatusToErp);
        end;

        //���� ����Ȯ��
        sStr := 'TeeboxReserveNextChkAD';
        Synchronize(Global.Teebox.TeeboxReserveNextChkAD);

        if Global.ADConfig.Emergency = False then
        begin
          //Kiosk ����Ȯ��
          if global.Store.ACS = 'Y' then
            Synchronize(Global.KioskTimeCheck);
        end;

        //���۽��� ��õ�
        if Global.ADConfig.Emergency = False then
          Synchronize(Global.Teebox.SendApiErrorRetry);
        {
        if Global.ADConfig.BeamProjectorUse = True then
        begin
          //��������Ʈ ���� ����
          Synchronize(Global.Teebox.SendBeamEnd);

          //��������Ʈ ������ 20/40���� ������
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
