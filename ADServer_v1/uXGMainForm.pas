
unit uXGMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Types,
  System.Classes, Vcl.Graphics, SvcMgr,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdTCPServer, IdContext, Vcl.StdCtrls, Uni,
  Generics.Collections,
  uStruct, CPort, Vcl.ExtCtrls, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, Vcl.Menus,
  cxCheckBox, cxMaskEdit, cxDropDownEdit, cxCurrencyEdit, cxButtons, cxLabel,
  cxTextEdit, cxGroupBox, cxPC, IdTCPConnection, IdTCPClient, AdvShapeButton,
  Frame.ItemStyle, IdHTTP, CPortCtl, uXGClientDM, IdAntiFreezeBase, IdAntiFreeze;

type
  TMainForm = class(TForm)
    pgcConfig: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    cxTabSheet4: TcxTabSheet;
    ComPort1: TComPort;
    Timer1: TTimer;
    Panel1: TPanel;
    Memo4: TMemo;
    btnReserveInfo: TButton;
    edTeeboxNo: TEdit;
    Button8: TButton;
    Panel2: TPanel;
    Memo1: TMemo;
    edApiResult: TEdit;
    chkDebug: TCheckBox;
    pnlSeat: TPanel;
    pnlCom: TPanel;
    btnHoldCancel: TButton;
    edTeeboxNm: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    btnTcpServerRe: TButton;
    cxTabSheet2: TcxTabSheet;
    Panel3: TPanel;
    Memo5: TMemo;
    pnlSeat2: TPanel;
    pnlCom1: TPanel;
    Panel6: TPanel;
    Memo6: TMemo;
    Edit16: TEdit;
    CheckBox4: TCheckBox;
    Memo7: TMemo;
    pnlCom2: TPanel;
    pnlCom3: TPanel;
    Memo8: TMemo;
    pnlCom4: TPanel;
    IdAntiFreeze1: TIdAntiFreeze;
    pnlEmergency: TPanel;
    pnlEmergency2: TPanel;
    pnlHeat: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure btnReserveInfoClick(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure chkDebugClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnHoldCancelClick(Sender: TObject);
    procedure btnTcpServerReClick(Sender: TObject);
    procedure pnlEmergencyClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    FItemList: TList<TFrame1>;

    FSeatChk: TDateTime;
    FHeatChk: TDateTime;
    FComChk: String;

    FComChk1: String;
    FComChk2: String;
    FComChk3: String;
    FComChk4: String;

    procedure StartUp;
    procedure Display(APloor: Integer);
    procedure Display2(APloor: Integer);
    function SendDataCreat(AChannelCd: String): String;
  public
    { Public declarations }
    procedure LogView(ALog: string);
    procedure LogViewA6001(ALog1, ALog2, ALog3, ALog4: string);

    property ItemList: TList<TFrame1> read FItemList write FItemList;
  end;

var
  MainForm: TMainForm;

implementation

uses
  uGlobal, uFunction, uConsts;

{$R *.dfm}

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Global.Log.LogWrite('사용자 종료!!');
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if MessageDlg('종료시 타석배정 및 제어를 할수 없습니다.'+#13+'종료하시겠습니까?', mtConfirmation, [mbOK, mbCancel], 0) = mrCancel then
  begin
    CanClose := False;
    Exit;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  StartUp;
  Display(1);
  Timer1.Enabled := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;
  Global.Free;
  FreeAndNil(FItemList);
end;

procedure TMainForm.StartUp;
begin
  Global := TGlobal.Create;
  Global.StartUp;

  Caption := Global.Store.StoreNm + '[' + Global.ADConfig.StoreCode + '] ' + Global.ADConfig.ApiUrl;

  if (Global.ADConfig.StoreCode = 'A6001') or (Global.ADConfig.StoreCode = 'A7001') or
     (Global.ADConfig.StoreCode = 'A8001') or (Global.ADConfig.StoreCode = 'AB001') or
     (Global.ADConfig.StoreCode = 'AD001') then //캐슬렉스, 빅토리아, 쇼골프, 한강
    pgcConfig.ActivePageIndex := 2
  else
    pgcConfig.ActivePageIndex := 0;

end;

procedure TMainForm.chkDebugClick(Sender: TObject);
begin
  if chkDebug.Checked = True then
  begin
    Global.SetConfigDebug('Y');
  end
  else
  begin
    Global.SetConfigDebug('N');
  end;
end;

procedure TMainForm.ComPort1RxChar(Sender: TObject; Count: Integer);
var
  Buffer: String;
  sRecvData: AnsiString;
begin
  //ComPort1.ReadStr(Buffer, Count);

  SetLength(sRecvData, Count);
  ComPort1.Read(sRecvData[1], Count);
  Memo1.Lines.Add(sRecvData);
end;

function TMainForm.SendDataCreat(AChannelCd: String): String;
var
  SeatInfo: TTeeboxInfo;
  sSendData: String;
  i, nCnt: Integer;
  sUseTime, sBall: String;
begin
  Result := '';

  sSendData := '' + AChannelCd;
  SeatInfo := Global.Teebox.GetTeeboxInfoA(AChannelCd);
  sUseTime := StrZeroAdd(IntToStr(SeatInfo.RemainMinute), 4);
  sBall := StrZeroAdd(IntToStr(SeatInfo.RemainBall), 4);

  if SeatInfo.UseStatus = '0' then
  begin
    //빈타석
    //1	2	3	4	5	6	7	8	9	10 11	12 13	14 15	16
    //	2	7	2	4	@	0	0	0	 0	0	 0	0	 0		 2
    //02 32	37 32	34 40	30 30	30 30	30 30	30 30	03 32
    sSendData := sSendData + '4@000000002';
  end
  else if SeatInfo.UseStatus = '1' then
  begin
    //사용중인 타석
    //	0	9	1	3	@	0	0	5	4	9	9	2	5		2
    //02 30	39 31	33 40	30 30	35 34	39 39	32 35	03 32
    sSendData := sSendData + '3@' + sUseTime + sBall + '2';
  end
  else
  begin
    //장애발생
    //	0	6	1	3	C	0	0	3	2	9	9	9	9		9
    //02 30	36 31	33 43	30 30	33 32	39 39	39 39	03 39
    sSendData := sSendData + '3B' + sUseTime + '99999';
  end;

  Result := sSendData;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Display2(1);

  if (Global.ADConfig.StoreCode = 'A6001') or (Global.ADConfig.StoreCode = 'A7001') or
     (Global.ADConfig.StoreCode = 'A8001') or (Global.ADConfig.StoreCode = 'AB001') or
     (Global.ADConfig.StoreCode = 'AD001') then //캐슬렉스, 빅토리아, 쇼골프,대성,한강
  begin
    MainForm.LogViewA6001(global.CtrlBufferTemp1, global.CtrlBufferTemp2, global.CtrlBufferTemp3, global.CtrlBufferTemp4);
  end
  else
  begin
    MainForm.LogView(global.CtrlBufferTemp);
  end;
end;

procedure TMainForm.LogView(ALog: string);
begin

  if Memo1.Lines.Count > 100 then
    //Memo1.Lines.Delete(0);
    Memo1.Lines.Clear;

  //Memo1.Lines.Add(FormatDateTime('hh:nn:ss ▶ ', now) + ALog);
  Memo1.Lines.Add(ALog);
  //WriteLogDayFile(Global.LogFileName, ALog);

  if FComChk <> ALog then
  begin
    if pnlCom.Color = clBtnFace then
      pnlCom.Color := clGreen
    else
      pnlCom.Color := clBtnFace;

    FComChk := ALog;
  end;

  if FSeatChk <> Global.TeeboxThreadTime then
  begin
    if pnlSeat.Color = clBtnFace then
      pnlSeat.Color := clBlue
    else
      pnlSeat.Color := clBtnFace;

    FSeatChk := Global.TeeboxThreadTime;
  end;

  if FHeatChk <> Global.HeatThreadTime then
  begin
    if pnlHeat.Color = clBtnFace then
      pnlHeat.Color := clGreen
    else
      pnlHeat.Color := clBtnFace;

    FHeatChk := Global.HeatThreadTime;
  end;
end;

procedure TMainForm.LogViewA6001(ALog1, ALog2, ALog3, ALog4: string);
begin

  if Memo5.Lines.Count > 50 then
    Memo5.Lines.Clear;

  Memo5.Lines.Add(ALog1);

  if Memo6.Lines.Count > 50 then
    Memo6.Lines.Clear;

  Memo6.Lines.Add(ALog2);

  if Memo7.Lines.Count > 50 then
    Memo7.Lines.Clear;

  Memo7.Lines.Add(ALog3);

  if Memo8.Lines.Count > 50 then
    Memo8.Lines.Clear;

  Memo8.Lines.Add(ALog4);

  if FComChk1 <> ALog1 then
  begin
    if pnlCom1.Color = clBtnFace then
      pnlCom1.Color := clGreen
    else
      pnlCom1.Color := clBtnFace;

    FComChk1 := ALog1;
  end;

  if FComChk2 <> ALog2 then
  begin
    if pnlCom2.Color = clBtnFace then
      pnlCom2.Color := clGreen
    else
      pnlCom2.Color := clBtnFace;

    FComChk2 := ALog2;
  end;

  if FComChk3 <> ALog3 then
  begin
    if pnlCom3.Color = clBtnFace then
      pnlCom3.Color := clGreen
    else
      pnlCom3.Color := clBtnFace;

    FComChk3 := ALog3;
  end;

  if FComChk4 <> ALog4 then
  begin
    if pnlCom4.Color = clBtnFace then
      pnlCom4.Color := clGreen
    else
      pnlCom4.Color := clBtnFace;

    FComChk4 := ALog4;
  end;

  if FSeatChk <> Global.TeeboxThreadTime then
  begin
    if pnlSeat2.Color = clBtnFace then
      pnlSeat2.Color := clBlue
    else
      pnlSeat2.Color := clBtnFace;

    FSeatChk := Global.TeeboxThreadTime;
  end;
end;

procedure TMainForm.pnlEmergencyClick(Sender: TObject);
begin
//global.TcpServer.SetTeeboxCheckIn('{"store_cd":"T0002","api":"A432_TeeboxCheckIn","user_id":"kiosk1","data":[{"reserve_no":"202108100002","teebox_no":"15"}]}');
end;

procedure TMainForm.Display(APloor: Integer);
var
  Index, ColIndex, RowIndex: Integer;
  Y, X: Single;
  APoint: TPointF;
  ASelectBoxProductItemStyle: TFrame1;
  rTeeboxInfo: TTeeboxInfo;
  sFloor: String;
  nColIndex: Integer;
begin
  try
    if FItemList = nil then
      FItemList := TList<TFrame1>.Create;

    if FItemList.Count <> 0 then
      FItemList.Clear;

    X := 0;
    Y := 0;

    RowIndex := 0;
    ColIndex := 0;
    sFloor := '';

    APoint := TPointF.Create(Y, X);

    for Index := 1 to Global.Teebox.TeeboxLastNo do
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(Index);

      if sFloor = '' then
        sFloor := rTeeboxInfo.FloorZoneCode;

      if sFloor <> rTeeboxInfo.FloorZoneCode then
      begin
        Inc(RowIndex);
        ColIndex := 0;

        sFloor := rTeeboxInfo.FloorZoneCode;
      end;

      if (Global.ADConfig.StoreCode = 'A8001') then
        nColIndex := 6
      else
        nColIndex := 5;

      if ColIndex = nColIndex then
      begin
        Inc(RowIndex);
        ColIndex := 0;
      end;

      ASelectBoxProductItemStyle := TFrame1.Create(nil);

      ASelectBoxProductItemStyle.Left := ColIndex * ASelectBoxProductItemStyle.Width;
      ASelectBoxProductItemStyle.Top := RowIndex * ASelectBoxProductItemStyle.Height;

      if (Global.ADConfig.StoreCode = 'A6001') or (Global.ADConfig.StoreCode = 'A7001') or
         (Global.ADConfig.StoreCode = 'A8001') or (Global.ADConfig.StoreCode = 'AB001') or
         (Global.ADConfig.StoreCode = 'AD001') then //캐슬렉스, 빅토리아, 쇼골프, 한강
        ASelectBoxProductItemStyle.Parent := Panel6
      else
        ASelectBoxProductItemStyle.Parent := Panel1;

      ASelectBoxProductItemStyle.TeeboxInfo := rTeeboxInfo;

      ASelectBoxProductItemStyle.HeatStatus := '';
      {
      if Global.ControlComPortHeatMonThread <> nil then
      begin
        ASelectBoxProductItemStyle.HeatStatus := Global.ControlComPortHeatMonThread.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
      end;
      }
      if Global.TcpThreadHeat <> nil then
      begin
        ASelectBoxProductItemStyle.HeatStatus := Global.TcpThreadHeat.GetHeatUseStatus(rTeeboxInfo.TeeboxNo);
      end;

      ASelectBoxProductItemStyle.DisPlaySeatInfo;

      ItemList.Add(ASelectBoxProductItemStyle);
      Inc(ColIndex);

      if Index = Global.Teebox.TeeboxLastNo then
      begin
        Height := ASelectBoxProductItemStyle.Top + ASelectBoxProductItemStyle.Height + 36 + 25 + 5; //516 477 25
        if Height < 516 then
          Height := 516;

        if (Global.ADConfig.StoreCode = 'A6001') or (Global.ADConfig.StoreCode = 'A7001') or
           (Global.ADConfig.StoreCode = 'A8001') or (Global.ADConfig.StoreCode = 'AB001') or
           (Global.ADConfig.StoreCode = 'AD001') then
          Height := 915;

        if (Global.ADConfig.StoreCode = 'A8001') then
          Width := 1250
        else
          Width := 1150;
      end;

    end;
  finally

  end;
end;

procedure TMainForm.Display2(APloor: Integer);
var
  Index: Integer;
  rTeeboxInfo: TTeeboxInfo;
begin
  try
    if FItemList.Count = 0 then
      Exit;

    for Index := 1 to Global.Teebox.TeeboxLastNo do
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(Index);
      FItemList[Index - 1].TeeboxInfo := rTeeboxInfo;
      FItemList[Index - 1].ReserveCnt := Global.Teebox.GetTeeboxReserveNextListCnt(Index);
      {
      if Global.ControlComPortHeatMonThread <> nil then
      begin
        FItemList[Index - 1].HeatStatus := Global.ControlComPortHeatMonThread.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
      end;
      }
      if Global.TcpThreadHeat <> nil then
      begin
        FItemList[Index - 1].HeatStatus := Global.TcpThreadHeat.GetHeatUseStatus(rTeeboxInfo.TeeboxNo);
      end;

      FItemList[Index - 1].DisPlaySeatInfo;
    end;
  finally

  end;
end;

procedure TMainForm.btnReserveInfoClick(Sender: TObject);
var
  rTeeboxInfo: TTeeboxInfo;
  nSeatNo: Integer;
  I: Integer;
  sStr: String;
begin
  if Trim(edTeeboxNo.text) <> '' then
  begin
    nSeatNo := StrToInt(edTeeboxNo.text);
    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(nSeatNo);
  end
  else if Trim(edTeeboxNm.text) <> '' then
  begin
    rTeeboxInfo := Global.Teebox.GetNmToTeeboxInfo(edTeeboxNm.text);
  end;

  Memo4.Lines.Clear;
  Memo4.Lines.Add('SeatNo : ' + IntToStr(rTeeboxInfo.TeeboxNo) + ' [ ' + 'SeatNm : ' + rTeeboxInfo.TeeboxNm + ' ] ');
  Memo4.Lines.Add('RemainMinute : ' + IntToStr(rTeeboxInfo.RemainMinute));
  Memo4.Lines.Add('RemainBall : ' + IntToStr(rTeeboxInfo.RemainBall));
  Memo4.Lines.Add('PrepareMin : ' + IntToStr(rTeeboxInfo.TeeboxReserve.PrepareMin));
  Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
  Memo4.Lines.Add('ReserveDate : ' + rTeeboxInfo.TeeboxReserve.ReserveDate);
  Memo4.Lines.Add('PrepareStartDate : ' + rTeeboxInfo.TeeboxReserve.PrepareStartDate);
  Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
  Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
  Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);
  Memo4.Lines.Add('UseRStatus : ' + rTeeboxInfo.UseRStatus);
  Memo4.Lines.Add('UseLStatus : ' + rTeeboxInfo.UseLStatus);
  Memo4.Lines.Add('AssignYn : ' + rTeeboxInfo.TeeboxReserve.AssignYn);

  sStr := Global.Teebox.GetTeeboxReserveNextView(rTeeboxInfo.TeeboxNo);

  Memo4.Lines.Add(sStr);
end;

procedure TMainForm.Button8Click(Sender: TObject);
var
  rTeeboxInfo: TTeeboxInfo;
  nIndex: Integer;
begin

  Memo4.Lines.Clear;
  for nIndex := 1 to Global.Teebox.TeeboxLastNo do
  begin
    rTeeboxInfo := Global.Teebox.GetTeeboxInfo(nIndex);

    if (rTeeboxInfo.RemainMinute > 0) and (rTeeboxInfo.UseStatus = '1') and
       (rTeeboxInfo.TeeboxReserve.ReserveStartDate = '') then
    begin
      Memo4.Lines.Add('SeatNm : ' + rTeeboxInfo.TeeboxNm);
      Memo4.Lines.Add('RemainMinute : ' + IntToStr(rTeeboxInfo.RemainMinute));
      Memo4.Lines.Add('RemainBall : ' + IntToStr(rTeeboxInfo.RemainBall));
      Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
      Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
      Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
      Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);
    end;
  end;
end;

procedure TMainForm.btnTcpServerReClick(Sender: TObject);
begin
  Global.TcpServer.ServerReConnect;
end;

procedure TMainForm.btnHoldCancelClick(Sender: TObject);
var
  sSeatNo: String;
  sSendData: AnsiString;
  SeatInfo: TTeeboxInfo;
begin
  if Trim(edTeeboxNo.text) <> '' then
    sSeatNo := edTeeboxNo.text
  else if Trim(edTeeboxNm.text) <> '' then
  begin
    SeatInfo := Global.Teebox.GetNmToTeeboxInfo(edTeeboxNm.text);
    sSeatNo := IntToStr(SeatInfo.TeeboxNo);
  end;

  //홀드 취소
  sSendData := '{' +
                  '"store_cd":"' + global.ADConfig.StoreCode + '",' +
                  '"api":"K406_TeeBoxHold",' +
                  '"user_id":"T0001",' +     //사용자 Id	user_id
                  '"teebox_no":"' + sSeatNo + '"' +   //타석기 번호	teebox_no
               '}';

  global.tcpserver.SetTeeboxHoldCancel(sSendData);
end;

end.
