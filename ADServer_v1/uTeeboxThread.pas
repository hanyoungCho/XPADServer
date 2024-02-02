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
        //Ÿ�� ��������
        Synchronize(Global.Teebox.TeeboxStatusChkJMS);

        //Ÿ���� ��������
        Synchronize(Global.Teebox.TeeboxReserveChkJMS);
      end
      else
      begin
        //Ÿ�� ��������
        Synchronize(Global.Teebox.TeeboxStatusChk);

        //Ÿ���� ��������
        Synchronize(Global.Teebox.TeeboxReserveChk);
      end;

      if Global.ADConfig.StoreCode = 'A7001' then //���ڵ�
      begin
        //Ÿ�� ��������
        Synchronize(Global.Teebox.TeeboxStatusChkVictoria);

        //Ÿ���� ��������
        Synchronize(Global.Teebox.TeeboxReserveChkVictoria);
      end;

      inc(Cnt);
      if Cnt > 15 then
      begin
        //Ÿ���� Ȧ�帮��
        //Synchronize(Global.Seat.SeatHoldReset);

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

        //���۽��� ��õ�
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
