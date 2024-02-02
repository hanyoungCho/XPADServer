unit uHeatControlTcp;

interface

uses
  Vcl.ExtCtrls, System.SysUtils,System.Classes, IdTCPClient,
  uConsts, uStruct;

type
  TTcpThreadHeat = class(TThread)
  private
    FIdTCPClient: TIdTCPClient;
    FCmdSendBufArr: array[0..COM_CTL_MAX] of AnsiString;

    FTeeboxLastNo: Integer;
    FReTry: Integer;

    FLastCmdDataIdx: word; //대기중인 명령번호
    FCurCmdDataIdx: word;  //처리한 명령번호

    FLastExeCommand: Integer; //최종 패킷 수행 펑션

    FHeatInfoList: array of THeatInfo;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetCmdSendBuffer(AFloor, ATeeboxNm, AType: String);

    procedure HeatTimeChk;
    procedure SetHeatUse(ATeeboxNo: Integer; AType, AAuto, AStartTm: String; ACtrl: Boolean = False);
    procedure SetHeatUseAll;
    function GetHeatUseStatus(ATeeboxNo: Integer): String;
  end;

implementation

uses
  uGlobal, uXGMainForm, uFunction;

{ TTcpThreadHeat }

constructor TTcpThreadHeat.Create;
var
  sLogMsg: String;
  nCnt, nIndex, nHeatNo: Integer;
  rTeeboxInfo: TTeeboxInfo;
begin
  FIdTCPClient := TIdTCPClient.Create(nil);
  FIdTCPClient.Disconnect;

  FIdTCPClient.Host := Global.ADConfig.HeatTcpIP;
  FIdTCPClient.Port := Global.ADConfig.HeatTcpPort;

  FIdTCPClient.ConnectTimeout := 2000;
  FIdTCPClient.ReadTimeout := 2000;

  FReTry := 0;
  FLastCmdDataIdx := 0;
  FCurCmdDataIdx := 0;

  FTeeboxLastNo := global.teebox.teeboxlastno;
  SetLength(FHeatInfoList, FTeeboxLastNo + 1);
  for nIndex := 0 to FTeeboxLastNo - 1 do
  begin
    nHeatNo := nIndex + 1;

    rTeeboxInfo := global.teebox.GetTeeboxInfo(nHeatNo);

    FHeatInfoList[nHeatNo].HeatNo := rTeeboxInfo.TeeboxNo;
    FHeatInfoList[nHeatNo].TeeboxNm := rTeeboxInfo.TeeboxNm;
    FHeatInfoList[nHeatNo].FloorZoneCode := rTeeboxInfo.FloorZoneCode;
    FHeatInfoList[nHeatNo].UseStatus := '0';
  end;

  FreeOnTerminate := False;
  inherited Create(True);
end;

destructor TTcpThreadHeat.Destroy;
begin
  FIdTCPClient.Disconnect;
  FIdTCPClient.Free;
  inherited;
end;

procedure TTcpThreadHeat.SetHeatuse(ATeeboxNo: Integer; AType, AAuto, AStartTm: String; ACtrl: Boolean = False);
var
  nIndex, nHeatNo: Integer;
  sStr: String;
begin
  nHeatNo := 0;
  for nIndex := 1 to FTeeboxLastNo do
  begin
    if FHeatInfoList[nIndex].HeatNo = ATeeboxNo then
    begin
      nHeatNo := nIndex;
      Break;
    end;
  end;

  if nHeatNo = 0 then
  begin
    sStr := 'TeeboxNo: ' + IntToStr(ATeeboxNo) + ' No Device ';
    Global.Log.LogHeatWrite(sStr);
    Exit;
  end;

  FHeatInfoList[nHeatNo].UseStatus := AType;
  FHeatInfoList[nHeatNo].UseAuto := AAuto;
  sStr := 'FloorCd: ' + FHeatInfoList[nHeatNo].FloorZoneCode + ' / TeeboxNm: ' + FHeatInfoList[nHeatNo].TeeboxNm + ' / ' + AType;

  if AAuto = '1' then
  begin
    FHeatInfoList[nHeatNo].StartTime := DateStrToDateTime2(AStartTm);
    FHeatInfoList[nHeatNo].EndTime := FHeatInfoList[nHeatNo].StartTime +
                                      (((1/24)/60) * StrToInt(Global.ADConfig.HeatTime));
    sStr := sStr + ' / ' + AStartTm;
  end;

  Global.Log.LogHeatWrite(sStr);

  if ACtrl = True then
    SetCmdSendBuffer(FHeatInfoList[nHeatNo].FloorZoneCode, FHeatInfoList[nHeatNo].TeeboxNm, AType);
end;

procedure TTcpThreadHeat.SetHeatuseAll;
var
  nIndex: Integer;
  sSendData: AnsiString;
  bCtl: Boolean;
begin

  //“SBS,타석번호1^상태,타석번호2^상태,...,타석번호n^상태”
  //SBS,1^1,2^0,4^1,17^0,18^1
  //SBS,1^2^1 (1층 2번타석 ON 상태) - 캐슬렉스
  sSendData := 'SBS';
  bCtl := False;

  for nIndex := 1 to FTeeboxLastNo do
  begin
    if FHeatInfoList[nIndex].UseStatus = '1' then
    begin
      bCtl := True;

      if Global.ADConfig.StoreCode = 'A6001' then //캐슬렉스
        sSendData := sSendData + ',' + FHeatInfoList[nIndex].FloorZoneCode + '^' + FHeatInfoList[nIndex].TeeboxNm + '^0'
      else
        sSendData := sSendData + ',' + FHeatInfoList[nIndex].TeeboxNm + '^0';

      FHeatInfoList[nIndex].UseStatus := '0';
      FHeatInfoList[nIndex].UseAuto := '0';

      Global.SetTeeboxHeatConfig(IntToStr(FHeatInfoList[nIndex].HeatNo), '', '0', FHeatInfoList[nIndex].UseAuto, '');
    end;
  end;

  if bCtl = True then
  begin
    FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

    inc(FLastCmdDataIdx);
    if FLastCmdDataIdx > COM_CTL_MAX then
      FLastCmdDataIdx := 0;
  end;
end;

function TTcpThreadHeat.GetHeatUseStatus(ATeeboxNo: Integer): String;
var
  nIndex: Integer;
  sStatus: String;
begin
  Result := '';

  sStatus := '';
  for nIndex := 1 to FTeeboxLastNo do
  begin
    //if FHeatInfoList[nIndex].TeeboxNm = ATeeboxNm then
    if FHeatInfoList[nIndex].HeatNo = ATeeboxNo then
    begin
      sStatus := FHeatInfoList[nIndex].UseStatus;
      Break;
    end;
  end;

  Result := sStatus;
end;

procedure TTcpThreadHeat.SetCmdSendBuffer(AFloor, ATeeboxNm, AType: String);
var
  sSendData: AnsiString;
begin

  //“SBS,타석번호1^상태,타석번호2^상태,...,타석번호n^상태”
  //SBS,1^1,2^0,4^1,17^0,18^1
  if Global.ADConfig.StoreCode = 'A6001' then //캐슬렉스
    sSendData := 'SBS,' + AFloor + '^' + ATeeboxNm + '^' + AType
  else
    sSendData := 'SBS,' + ATeeboxNm + '^' + AType;

  FCmdSendBufArr[FLastCmdDataIdx] := sSendData;

  inc(FLastCmdDataIdx);
  if FLastCmdDataIdx > COM_CTL_MAX then
    FLastCmdDataIdx := 0;
end;

procedure TTcpThreadHeat.HeatTimeChk;
var
  nHeatNo: Integer;
  sSendData: AnsiString;
  sStr: string;
begin
  //Global.LogWrite('SeatReserveChk!!!');

  for nHeatNo := 1 to FTeeboxLastNo do
  begin

    //Auto 여부
    if FHeatInfoList[nHeatNo].UseAuto <> '1' then
      Continue;

    //가동여부
    if FHeatInfoList[nHeatNo].UseStatus <> '1' then
      Continue;

    if FHeatInfoList[nHeatNo].EndTime < Now then
    begin
      FHeatInfoList[nHeatNo].UseStatus := '0';
      Global.SetTeeboxHeatConfig(IntToStr(FHeatInfoList[nHeatNo].HeatNo), '', '0', FHeatInfoList[nHeatNo].UseAuto, '');
      SetCmdSendBuffer(FHeatInfoList[nHeatNo].FloorZoneCode, FHeatInfoList[nHeatNo].TeeboxNm, '0');

      sStr := '자동히터정지 - 층cd: ' + FHeatInfoList[nHeatNo].FloorZoneCode + ' / Nm: ' + FHeatInfoList[nHeatNo].TeeboxNm + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].StartTime) + ' / ' +
              FormatDateTime('YYYY-MM-DD hh:nn:ss', FHeatInfoList[nHeatNo].EndTime);
      Global.Log.LogHeatCtrlWrite(sStr);
    end;
  end;

end;

procedure TTcpThreadHeat.Execute;
var
  sChannelTemp, sLogMsg: String;
  sSendData, sRecvData: AnsiString;
begin
  inherited;

  while not Terminated do
  begin

    try

      Synchronize(Global.HeatThreadTimeCheck);

      if (FLastCmdDataIdx <> FCurCmdDataIdx) then
      begin //대기중인 제어명령이 있으면

        if not FIdTCPClient.Connected then
        begin
          FIdTCPClient.Disconnect;
          FIdTCPClient.Connect();
        end;

        sSendData := FCmdSendBufArr[FCurCmdDataIdx];
        sChannelTemp := Copy(sSendData, 4, Length(sSendData) - 1);
        FIdTCPClient.IOHandler.WriteLn(sSendData);
        //Global.Log.LogHeatWrite(IntToStr(FCurCmdDataIdx) + ' : ' + sSendData);

        //BST,1^1,2^0,4^1,17^0,18^1
        sRecvData := FIdTCPClient.IOHandler.ReadLn;
        Global.Log.LogHeatCtrlWrite(IntToStr(FCurCmdDataIdx) + ' : ' + sSendData + ' / ' + sRecvData);

        sleep(50);

        if sChannelTemp = Copy(sRecvData, 4, Length(sSendData) - 1) then
        begin
          if FLastCmdDataIdx <> FCurCmdDataIdx then
          begin
            inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
            if FCurCmdDataIdx > COM_CTL_MAX then
              FCurCmdDataIdx := 0;
          end;
          FReTry := 0;
        end
        else
        begin
          inc(FReTry);
          if FReTry > 2 then
          begin
            FReTry := 0;
            if FLastCmdDataIdx <> FCurCmdDataIdx then
            begin
              inc(FCurCmdDataIdx); //다음 제어 데이타로 이동
              if FCurCmdDataIdx > COM_CTL_MAX then
                FCurCmdDataIdx := 0;
            end;
          end;
        end;

        //2021-11-12 조광부터 적용
        FIdTCPClient.Disconnect;

      end;

      Sleep(100);

      //히터 자동사용시 타이머 체크
      Synchronize(HeatTimeChk);

    except
      on e: Exception do
      begin
        sLogMsg := 'TTcpThreadHeat Error : ' + e.Message;
        Global.Log.LogHeatCtrlWrite(sLogMsg);
        FIdTCPClient.Disconnect;

        if StrPos(PChar(e.Message), PChar('Socket Error')) <> nil then
        begin
          //wMonDelayTime := 10000; //10000 = 10초
          //g_bSMServerSocketError := True;
        end;
      end;
    end;

  end;

end;

end.
