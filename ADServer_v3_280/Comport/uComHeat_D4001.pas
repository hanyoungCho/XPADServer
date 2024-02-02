unit uComHeat_D4001;

interface

uses
  CPort, Vcl.ExtCtrls, System.SysUtils, System.Classes,
  uConsts, uStruct;

const
  HEAT_MIN = 1;
  HEAT_MAX = 102;

type
  TComThreadHeat_D4001 = class(TThread)
  private
    FComPort: TComPort;
    FRecvData: AnsiString;
    FSendData: AnsiString;

    FHeatInfoList: array of THeatInfo;

    FLastDevice: Integer; //������ ��û ��ȣ

    FCmdSendBufArr: array[0..BUFFER_SIZE] of AnsiString;
    FLastCmdDataIdx: word; //������� ��ɹ�ȣ
    FCurCmdDataIdx: word;  //ó���� ��ɹ�ȣ
    FLastExeCommand: Integer; //���� ��Ŷ ���� ���

    Cnt_1: Integer;

    procedure HeatDevicNoSetting;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure HeatTimeChk;

    procedure ComPortRxChar(Sender: TObject; Count: Integer);
    procedure SetCmdSendBuffer(ATeeboxNm, AType: String);
    procedure SetHeatUse(ATeeboxNm, AType, AAuto, AStartTm: String; ACtrl: Boolean = False);
    procedure SetHeatUseAllOff;

    function GetHeatUseStatus(ATeeboxNm: String): String;
    function HeatCtlDataM(AStart, AEnd: Integer): AnsiString;
    function HeatCtlDataS(AStart: Integer): AnsiString;
    function SetNextMonNo: Boolean;

    property ComPort: TComPort read FComPort write FComPort;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TComThreadHeat_D4001 }

constructor TComThreadHeat_D4001.Create;
begin
  FComPort := TComport.Create(nil);

  FComPort.OnRxChar := ComPortRxChar;
  FComPort.Port := 'COM' + IntToStr(Global.ADConfig.HeatPort);
  FComPort.BaudRate := br9600;
  FComPort.Open;

  FRecvData := '';

  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;
  FLastDevice := 1;
  Cnt_1 := 0;

  HeatDevicNoSetting;

  Global.Log.LogWrite('TComThreadHeat_D4001 Create');

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TComThreadHeat_D4001.Destroy;
begin
  FComPort.Close;
  FComPort.Free;
  inherited;
end;

procedure TComThreadHeat_D4001.HeatDevicNoSetting;
var
  nIndex: Integer;
begin
  SetLength(FHeatInfoList, HEAT_MAX + 1);
  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    FHeatInfoList[nIndex].TeeboxNm := IntToStr(nIndex);
    FHeatInfoList[nIndex].UseStatus := '0';
  end;
end;

procedure TComThreadHeat_D4001.ComPortRxChar(Sender: TObject; Count: Integer);
var
  sRecvData: AnsiString;
  nStx, nEtx: Integer;
  sDeviceId, sHeatNm: String;
begin
  SetLength(sRecvData, Count);
  FComPort.Read(sRecvData[1], Count);

  FRecvData := FRecvData + sRecvData;

  if Pos(#06, FRecvData) = 0 then
    Exit;

  if Pos(#03, FRecvData) = 0 then
    Exit;

  nStx := Pos(#06, FRecvData);
  nEtx := Pos(#03, FRecvData);

  FRecvData := Copy(FRecvData, nStx, nEtx);

  // .   0  1    R        S  S         0  1    0  2              0  0  0  1      .
  //06  30 31   52       53 53        30 31   30 32             30 30 30 31     03		   (0000 0000 0000 0000) ����bit���� ����Ÿ��
  //(1~16�� Ÿ�� ���� ��û).01RSS0107%DW0001. -> (����).01RSS01020013. 			�ؼ�:(0000 0000 0001 0011)    1,2,5�� Ÿ�� ON, ������ OFF.

  //���� �������
  Global.Log.LogHeatCtrlRead(FSendData + ' / ' + FRecvData);

  //���¿�û ���䰪 ��-����
  //Display2(FRecvData);

  FRecvData := '';
end;

procedure TComThreadHeat_D4001.SetHeatUse(ATeeboxNm, AType, AAuto, AStartTm: String; ACtrl: Boolean = False); //Ÿ���� �������
var
  nIndex, nHeatNo: Integer;
  sStr: String;
begin
  nHeatNo := StrToInt(ATeeboxNm);

  FHeatInfoList[nHeatNo].UseStatus := AType;
  FHeatInfoList[nHeatNo].UseAuto := AAuto;
  sStr := 'TeeboxNm: ' + ATeeboxNm + ' / ' + AType;

  if AAuto = '1' then
  begin
    FHeatInfoList[nHeatNo].StartTime := DateStrToDateTime2(AStartTm);
    FHeatInfoList[nHeatNo].EndTime := FHeatInfoList[nHeatNo].StartTime +
                                      (((1/24)/60) * StrToInt(Global.ADConfig.HeatTime));
    sStr := sStr + ' / ' + AStartTm;
  end;

  Global.Log.LogHeatWrite(sStr);

  if ACtrl = True then
    SetCmdSendBuffer(ATeeboxNm, AType);
end;

procedure TComThreadHeat_D4001.HeatTimeChk; //Ÿ���� �ڵ��ð� ���
var
  nHeatNo: Integer;
  sStr: string;
begin

  for nHeatNo := HEAT_MIN to HEAT_MAX do
  begin

    //Auto ����
    if FHeatInfoList[nHeatNo].UseAuto <> '1' then
      Continue;

    //��������
    if FHeatInfoList[nHeatNo].UseStatus <> '1' then
      Continue;

    if FHeatInfoList[nHeatNo].EndTime < Now then
    begin
      Global.SetTeeboxHeatConfig(FHeatInfoList[nHeatNo].TeeboxNm, '', '0', FHeatInfoList[nHeatNo].UseAuto, '');
      SetHeatuse(FHeatInfoList[nHeatNo].TeeboxNm, '0', '0', '', True);

      sStr := '�ڵ��������� : ' + FHeatInfoList[nHeatNo].TeeboxNm + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].StartTime) + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].EndTime);
      Global.Log.LogHeatCtrlWrite(sStr);
    end;

  end;

end;

procedure TComThreadHeat_D4001.SetHeatUseAllOff; //��üOFF
var
  nIndex: Integer;
  sSendData, sDeviceId: AnsiString;
begin
  sSendData := '';

  for nIndex := HEAT_MIN to HEAT_MAX do
  begin
    FHeatInfoList[nIndex].UseStatus := '0';
    Global.SetTeeboxHeatConfig(FHeatInfoList[nIndex].TeeboxNm, '', '0', '0', '');
  end;

  for nIndex := 1 to 12 do
  begin
    sDeviceId := StrZeroAdd(IntToStr(nIndex), 2);
    sSendData := #05 + '01WSS0107%DW00' + sDeviceId + '0000' + #04;

    FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

    inc(FLastCmdDataIdx);
    if FLastCmdDataIdx > COM_CTL_MAX then
      FLastCmdDataIdx := 0;
  end;

end;

function TComThreadHeat_D4001.GetHeatUseStatus(ATeeboxNm: String): String;
var
  nHeatNo: Integer;
begin
  if ATeeboxNm = '33/34' then
    nHeatNo := 33
  else if ATeeboxNm = '65/66' then
    nHeatNo := 65
  else if ATeeboxNm = '101/102' then
    nHeatNo := 101
  else
    nHeatNo := StrToInt(ATeeboxNm);
  Result := FHeatInfoList[nHeatNo].UseStatus;
end;

procedure TComThreadHeat_D4001.SetCmdSendBuffer(ATeeboxNm, AType: String);
var
  sSendData: AnsiString;
  nIndex: Integer;
  sDeviceId: String;
  sCtlData: AnsiString;
begin
  sSendData := '';
  nIndex := StrToInt(ATeeboxNm);

  //		                		 .   0  1    W        S  S         0  1    0  7              %  D  W  0  0  0  7      1  1  1  8      .	   (7�� Data Register ����)
  //.01WSS0107%DW00071118.	05  30 31   57       53 53        30 31   30 37             25 44 57 30 30 30 37     31 31 31 38     04        (0001 0001 0001 8000)    55,56,60,64�� Ÿ�� ON. (����Bit ����Ÿ��)
  // (1~16�� Ÿ�� ���� ��û).01WSS0107%DW00010F01. 			�ؼ�:(0000 1111 0000 0001)    1,9,10,11,12�� Ÿ�� ON, ������ OFF.
  // (17�� Ÿ�� ���� ��û)  .01WSS0107%DW00020001. 			�ؼ�:(0000 0000 0000 0001)    17�� Ÿ�� ON.
  {
  %  D  W  0  0  0  1      X  X  X  X      .	   (1�� Data Register ����)  1~16��
  %  D  W  0  0  0  2      X  X  X  X        .	   (2�� Data Register ����)  17�� Ÿ��
  %  D  W  0  0  0  3      X  X  X  X        .	   (3�� Data Register ����)  18~33�� Ÿ��
  %  D  W  0  0  0  4      X  X  X  X        .	   (4�� Data Register ����)  34�� Ÿ��
  %  D  W  0  0  0  5      X  X  X  X        .	   (5�� Data Register ����)  35~50�� Ÿ��
  %  D  W  0  0  0  6      X  X  X  X        .	   (6�� Data Register ����)  51�� Ÿ��
  %  D  W  0  0  0  7      X  X  X  X        .	   (7�� Data Register ����)  52~67�� Ÿ��
  %  D  W  0  0  0  8      X  X  X  X        .	   (8�� Data Register ����)  68�� Ÿ��
  %  D  W  0  0  0  9      X  X  X  X        .	   (9�� Data Register ����)  69~84�� Ÿ��
  %  D  W  0  0  1  0      X  X  X  X        .	   (10�� Data Register ����) 85�� Ÿ��
  %  D  W  0  0  1  1      X  X  X  X        .	   (11�� Data Register ����) 86~101�� Ÿ��
  %  D  W  0  0  1  2      X  X  X  X        .	   (12�� Data Register ����) 102�� Ÿ��
  }

  // 5, 6 -> ���� �ٲ�, 59, 60 -> ���� �ٲ�
  sDeviceId := '00';
  if (nIndex >= 1) and (nIndex <= 16) then
  begin
    sDeviceId := '01';
    sCtlData := HeatCtlDataM(1, 16);
  end
  else if (nIndex = 17) then
  begin
    sDeviceId := '02';
    sCtlData := HeatCtlDataS(17);
  end
  else if (nIndex >= 18) and (nIndex <= 33) then
  begin
    sDeviceId := '03';
    sCtlData := HeatCtlDataM(18, 33);
  end
  else if (nIndex = 34) then
  begin
    sDeviceId := '04';
    sCtlData := HeatCtlDataS(34);
  end
  else if (nIndex >= 35) and (nIndex <= 50) then
  begin
    sDeviceId := '05';
    sCtlData := HeatCtlDataM(35, 50);
  end
  else if (nIndex = 51) then
  begin
    sDeviceId := '06';
    sCtlData := HeatCtlDataS(51);
  end
  else if (nIndex >= 52) and (nIndex <= 67) then
  begin
    sDeviceId := '07';
    sCtlData := HeatCtlDataM(52, 67);
  end
  else if (nIndex = 68) then
  begin
    sDeviceId := '08';
    sCtlData := HeatCtlDataS(68);
  end
  else if (nIndex >= 69) and (nIndex <= 84) then
  begin
    sDeviceId := '09';
    sCtlData := HeatCtlDataM(69, 84);
  end
  else if (nIndex = 85) then
  begin
    sDeviceId := '10';
    sCtlData := HeatCtlDataS(85);
  end
  else if (nIndex >= 86) and (nIndex <= 101) then
  begin
    sDeviceId := '11';
    sCtlData := HeatCtlDataM(86, 101);
  end
  else if (nIndex = 102) then
  begin
    sDeviceId := '12';
    sCtlData := HeatCtlDataS(102);
  end;
  sCtlData := StrZeroAdd(sCtlData, 4);

  sSendData := #05 + '01WSS0107%DW00' + sDeviceId + sCtlData + #04;
  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  //Global.Log.LogHeatCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + sSendData);


  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > COM_CTL_MAX then
    FLastCmdDataIdx := 0;
end;

function TComThreadHeat_D4001.HeatCtlDataM(AStart, AEnd: Integer): AnsiString;
var
  nTemp1, nTemp2: Byte;
  sTemp: AnsiString;
  i: Integer;
begin
  sTemp := '';
  // 5, 6 -> ���� �ٲ�, 59, 60 -> ���� �ٲ�
  for i := AStart to AEnd do
  begin
    if i = 5 then
      sTemp := FHeatInfoList[6].UseStatus + sTemp
    else if i = 6 then
      sTemp := FHeatInfoList[5].UseStatus + sTemp
    else if i = 59 then
      sTemp := FHeatInfoList[60].UseStatus + sTemp
    else if i = 60 then
      sTemp := FHeatInfoList[59].UseStatus + sTemp
    else
      sTemp := FHeatInfoList[i].UseStatus + sTemp;
  end;
  nTemp1 := Bin2Dec(Copy(sTemp, 1, 8));
  nTemp2 := Bin2Dec(Copy(sTemp, 9, 16));
  Result := IntToHex(nTemp1) + IntToHex(nTemp2);
end;
function TComThreadHeat_D4001.HeatCtlDataS(AStart: Integer): AnsiString;
var
  nTemp: Byte;
  sTemp: AnsiString;
begin
  sTemp := FHeatInfoList[AStart].UseStatus;
  sTemp := StrZeroAdd(sTemp, 16);
  nTemp := Bin2Dec(sTemp);
  Result := IntToHex(nTemp);
end;

function TComThreadHeat_D4001.SetNextMonNo: Boolean;
begin
  inc(FLastDevice);
  if FLastDevice > 12 then
    FLastDevice := 1;
end;

procedure TComThreadHeat_D4001.Execute;
var
  bControlMode: Boolean;
  sLogMsg: String;
  sDevice: AnsiString;
begin
  inherited;

  while not Terminated do
  begin
    try

      if not FComPort.Connected then
      begin
        FComPort.Open;
      end;

      FSendData := '';
      bControlMode := False;
      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //������� �������� ������
        bControlMode := False;
        //FLastExeCommand := COM_CTL;
        FSendData := FCmdSendBufArr[FCurCmdDataIdx];
        FComPort.Write(FSendData[1], Length(FSendData));
        Sleep(200);
        FComPort.Write(FSendData[1], Length(FSendData));
        Sleep(200);
        FComPort.Write(FSendData[1], Length(FSendData));

        Global.Log.LogHeatCtrlWrite('SendData : FCurCmdDataIdx ' + IntToStr(FCurCmdDataIdx) + ' / ' + FSendData);

        if FLastCmdDataIdx <> FCurCmdDataIdx then
        begin
          inc(FCurCmdDataIdx); //���� ���� ����Ÿ�� �̵�
          if FCurCmdDataIdx > BUFFER_SIZE then
            FCurCmdDataIdx := 0;
        end;
      end;

      //��ġ�� �����Ͱ��� ��û�ϴ� �κ�
      if bControlMode = False then
      begin
        //            				 .   0  1    R        S  S         0  1    0  7              %  D  W  0  0  0  5        .	   (5�� Data Register �б�)
        //.01RSS0107%DW0005.	05  30 31   52       53 53        30 31   30 37             25 44 57 30 30 30 35       04

        //FLastExeCommand := COM_MON;
        sDevice := StrZeroAdd(IntToStr(FLastDevice), 2);
        FSendData := #05 + '01RSS0107%DW00' + sDevice + #04;
        FComPort.Write(FSendData[1], Length(FSendData));
        //Global.Log.LogHeatCtrlWrite('SendData : COM_MON ' + FSendData);

        //FWriteTm := now + (((1/24)/60)/60) * 1;
        SetNextMonNo;
      end;

      //FReceived := False;
      Sleep(200);

      inc(Cnt_1);
      if Cnt_1 > 10 then
      begin
        //���� �ڵ����� Ÿ�̸� üũ
        Synchronize(HeatTimeChk);
        Cnt_1 := 0;
      end;

    except
      on e: Exception do
      begin
        sLogMsg := 'TComThreadHeat_D4001 Error : ' + e.Message + ' / ' + FSendData;
        Global.Log.LogHeatCtrlWrite(sLogMsg);
      end;
    end;
  end;

end;

end.
