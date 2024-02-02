unit uComConveyor;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

type

  TComConveyorMonThread = class(TThread)
  private
    FComPort: TComPort;

    FRecvData: AnsiString;
    FSendData: AnsiString;

    FReTry: Integer;
    FReceived: Boolean;

  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm;

{ TControlComPortHeatMonThread }

constructor TComConveyorMonThread.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.Port);
  FComPort.BaudRate := br19200;
  FComPort.Open;

  FReTry := 0;
  FReceived := True;

  FRecvData := '';

  Global.Log.LogWrite('TComConveyorMonThread Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComConveyorMonThread.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComConveyorMonThread.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sBuffer, sRecvData: AnsiString;
  nStx, nEtx: Integer;
  sState, sBin: AnsiString;
begin
  //00RSB010A00220000000800000000
  //06 30 30 52 53 42 30 31 30 41 30 30 32 32 30 30 30 30 30 30 30 38 30 30 30 30 30 30 30 30 03

  SetLength(sBuffer, Count);
  FComPort.Read(sBuffer[1], Count);

  FRecvData := FRecvData + sBuffer;

  if Length(FRecvData) < 31 then
    Exit;

  if Pos(COM_ACK, FRecvData) = 0 then
    Exit;

  if Pos(COM_ETX, FRecvData) = 0 then
    Exit;

  nStx := Pos(COM_ACK, FRecvData);
  nEtx := Pos(COM_ETX, FRecvData);

  sRecvData := Copy(FRecvData, nStx, nEtx);
  FRecvData := '';

  if (Length(sRecvData) <> 31) then
  begin
    Global.Log.LogWrite('RecvData fail : ' + sRecvData);
    Exit;
  end;

  //sState := Copy(sRecvData, 21, 1);
  //sBin := DecToBinStr(StrToInt(sState));

  //0010 - 1¬˜∏∑»˚
  //0100 - 2¬˜∏∑»˚
  //1000 - 3¬˜∏∑»˚
  Global.SetConveyor(sRecvData);

  //Global.DebugLogViewWrite(sRecvData);
  Global.Log.LogWrite('RecvData : ' + sRecvData);

  FRecvData := '';
  FReceived := True;
end;

procedure TComConveyorMonThread.Execute;
var
  sLogMsg: String;
begin
  inherited;

  while not Terminated do
  begin
    try
      //Synchronize(Global.SeatControlTimeCheck);

      if FReceived = False then
      begin

        inc(FReTry);
        if FReTry > 5 then
        begin
          FReTry := 0;

          sLogMsg := 'Retry 5 / Received Fail / ' + FSendData;
          Global.Log.LogWrite(sLogMsg);

          Global.Log.LogWrite('ReOpen');
          FComPort.Close;
          FComPort.Open;
          FComPort.ClearBuffer(True, True);

          Global.SetConveyorError('1');
          FRecvData := '';
        end;
      end
      else
        FReTry := 0;

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';

      //W: 00RSB06%MW00005
      //W: 05 30 30 52 53 42 30 36 25 4D 57 30 30 30 30 35 04

      FSendData := COM_ENQ + '00RSB06%MW00005' + COM_EOT;
      FComPort.Write(FSendData[1], Length(FSendData));

      FReceived := False;
      Sleep(10000); //10√ 

    except
      on e: Exception do
      begin
        sLogMsg := 'TComConveyorMonThread Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWrite(sLogMsg);
      end;
    end;

  end;

end;

end.
