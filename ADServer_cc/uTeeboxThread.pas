unit uTeeboxThread;

interface

uses
  System.Classes, System.SysUtils;

type
  TTeeboxThread = class(TThread)
  private
    Cnt: Integer;
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

      Synchronize(Global.SeatThreadTimeCheck);

      //Ÿ���� ��������
      Synchronize(Global.Teebox.TeeboxReserveChkAD);

      //Ÿ�� ��������
      Synchronize(Global.Teebox.TeeboxStatusChkAD);

      inc(Cnt);
      //if Cnt > 15 then
      if Cnt > 4 then
      begin
        //Ÿ���� ����Ȯ�ο�-> ERP ����
        Synchronize(Global.Teebox.SendADStatusToErp);

        //���� ����Ȯ��
        Synchronize(Global.Teebox.ReserveNextChk);

        Cnt := 0;
      end;

      //Sleep(1000);
      Sleep(4000);
    except
      on e: Exception do
      begin
        sLogMsg := 'TeeboxThread Error : ' + e.Message;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
