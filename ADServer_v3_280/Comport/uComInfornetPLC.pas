unit uComInfornetPLC;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

type

  TComThreadInfornetPLC = class(TThread)
  private
    FComPort: TComPort;
    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FRecvData: AnsiString;
    FSendData: AnsiString;
    FReceived: Boolean;
    FReTry: Integer;

    FTeeboxNmTemp: array of String;
    FTeeboxNmList: array of TInfoPLCInfo;

    FIndex: Integer; //로그용
    FFloorCd: String; //층

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호
    FLastCtlSeatNo: Integer; //최종 제어타석기

    procedure DevicNoTempSetting;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ComPortSetting(AFloorCd: String; AIndex, APort, ABaudRate: Integer);

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer;
    procedure SetTeeboxUse(ATeeboxNm, AType: String);
    function GetTeeboxUse: String;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadInfornetPLC }

constructor TComThreadInfornetPLC.Create;
begin
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FReceived := True;
  FRecvData := '';
  FReTry := 0;

  DevicNoTempSetting;

  Global.Log.LogWrite('TComThreadInfornetPLC Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadInfornetPLC.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadInfornetPLC.ComPortSetting(AFloorCd: String; AIndex, APort, ABaudRate: Integer);
begin
  FIndex := AIndex;
  FFloorCd := AFloorCd;

  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(APort);
  FComPort.BaudRate := GetBaudrate(ABaudRate);
  FComPort.Open;

  Global.Log.LogWrite('TComThreadInfornetPLC ComPortSetting : ' + FFloorCd);
end;

procedure TComThreadInfornetPLC.DevicNoTempSetting;
var
  nCnt, nIndex, nNo: Integer;
begin

  FTeeboxNmTemp := [ '60','59','58','57','56','55','54','53',
                     '67','66','65','65','64','63','62','61'];

  nCnt := Length(FTeeboxNmTemp);
  SetLength(FTeeboxNmList, nCnt + 1);
  for nIndex := 0 to nCnt - 1 do
  begin
    nNo := nIndex + 1;
    FTeeboxNmList[nIndex].PLCNo := nIndex;
    FTeeboxNmList[nIndex].TeeboxNm := FTeeboxNmTemp[nIndex];
    FTeeboxNmList[nIndex].UseStatus := '0';
  end;
end;

procedure TComThreadInfornetPLC.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sRecvData: AnsiString;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := '';
  FReceived := True;
end;

procedure TComThreadInfornetPLC.SetCmdSendBuffer;
var
  nIndex, nChk: Integer;
  sSendData, sBcc: AnsiString;
begin

  sSendData := '';
  for nIndex := 0 to Length(FTeeboxNmTemp) - 1 do
  begin
    sSendData := sSendData + FTeeboxNmList[nIndex].UseStatus;
  end;
  Global.Log.LogReadMulti(FIndex, 'SendData : ' + sSendData);

  nChk := Bin2Dec(sSendData);
  sSendData := INFOR_STX + inttohex(nChk, 4) + '000000000000000000000000000000000000' + INFOR_ETX;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > BUFFER_SIZE then
    FLastCmdDataIdx := 0;
end;

procedure TComThreadInfornetPLC.SetTeeboxUse(ATeeboxNm, AType: String);
var
  nIndex, nNo: Integer;
  sStr: String;
begin
  nNo := -1;
  for nIndex := 0 to Length(FTeeboxNmTemp) - 1 do
  begin
    if FTeeboxNmList[nIndex].TeeboxNm = ATeeboxNm then
    begin
      FTeeboxNmList[nIndex].UseStatus := AType;
      nNo := nIndex;
      //Break;
    end;
  end;

  if nNo = -1 then
  begin
    sStr := 'TeeboxNm ' + ATeeboxNm + ' No Device ';
    Global.Log.LogReadMulti(FIndex, sStr);
    Exit;
  end;

  //FTeeboxNmList[nNo].UseStatus := AType;
  sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AType;

  Global.Log.LogReadMulti(FIndex, sStr);
end;

function TComThreadInfornetPLC.GetTeeboxUse: String;
var
  nIndex: Integer;
  sSendData: String;
begin
  result := '';
  sSendData := '';
  for nIndex := 0 to Length(FTeeboxNmTemp) - 1 do
  begin
    sSendData := sSendData + FTeeboxNmList[nIndex].UseStatus;
  end;
  result := sSendData;
end;

procedure TComThreadInfornetPLC.Execute;
var
  //bControlMode: Boolean;
  //sBcc: AnsiString;
  sLogMsg: String;
  //nSeatNo: Integer;
begin
  inherited;

  while not Terminated do
  begin
    try
      Synchronize(Global.PLCThreadTimeCheck);

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';
      //bControlMode := False;
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면
        //bControlMode := True;
        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Global.Log.LogWriteMulti(FIndex, 'SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        inc(FReTry);
        if FReTry > 1 then
        begin
          FReTry := 0;
          if FLastCmdDataIdx <> FCurCmdDataIdx then
          begin
            inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
            if FCurCmdDataIdx > BUFFER_SIZE then
              FCurCmdDataIdx := 0;
          end;
        end;
      end;

      Sleep(500);

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadInfornetPLC Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogWriteMulti(FIndex, sLogMsg);
      end;
    end;
  end;

end;

end.
