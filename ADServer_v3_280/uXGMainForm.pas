unit uXGMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Types,
  System.Classes, Vcl.Graphics, SvcMgr,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdContext, Vcl.StdCtrls, Uni,
  Generics.Collections,
  Vcl.ExtCtrls, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit,
  cxButtons, cxLabel,
  cxTextEdit, cxPC,
  CPortCtl, IdAntiFreezeBase, IdAntiFreeze,
  Frame.ItemStyle, uStruct, dxColorPicker, Data.DB, Vcl.DBCtrls, Vcl.Grids,
  Vcl.DBGrids;

type
  TMainForm = class(TForm)
    pgcConfig: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    Timer1: TTimer;
    pnlSingle: TPanel;
    Panel2: TPanel;
    Memo1: TMemo;
    edApiResult: TEdit;
    pnlSeat: TPanel;
    pnlCom: TPanel;
    cxTabSheet2: TcxTabSheet;
    Panel3: TPanel;
    Memo5: TMemo;
    pnlSeat2: TPanel;
    pnlCom1: TPanel;
    pnlMulti: TPanel;
    Memo6: TMemo;
    Edit16: TEdit;
    Memo7: TMemo;
    pnlCom2: TPanel;
    pnlCom3: TPanel;
    Memo8: TMemo;
    pnlCom4: TPanel;
    IdAntiFreeze1: TIdAntiFreeze;
    pnlEmergency: TPanel;
    pnlEmergency2: TPanel;
    cxTabSheet3: TcxTabSheet;
    Panel4: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Memo4: TMemo;
    btnReserveInfo: TButton;
    edTeeboxNo: TEdit;
    btnHoldCancel: TButton;
    edTeeboxNm: TEdit;
    Panel5: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    btnBallbackList: TButton;
    laBallBackStart: TLabel;
    mmoBallbackList: TMemo;
    btnHeatOn: TButton;
    btnHeatOff: TButton;
    btnDebugMulti: TButton;
    pnlHeat: TPanel;
    btnPLC: TButton;
    pnlPLC: TPanel;
    pnlCom6: TPanel;
    pnlCom5: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    pnlDome: TPanel;
    rgDeviceType: TRadioGroup;
    Panel6: TPanel;
    edtHeatOnTime: TEdit;
    Panel9: TPanel;
    edtHeatOffTime: TEdit;
    btnHeatOnOffTime: TButton;
    btnDebug: TButton;
    cxTabSheet4: TcxTabSheet;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    Panel10: TPanel;
    btnAgentSelect: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure Timer1Timer(Sender: TObject);
    procedure btnReserveInfoClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnHoldCancelClick(Sender: TObject);
    procedure btnBallbackListClick(Sender: TObject);
    procedure btnHeatOnClick(Sender: TObject);
    procedure btnHeatOffClick(Sender: TObject);
    procedure btnPLCClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure rgDeviceTypeClick(Sender: TObject);
    procedure btnHeatOnOffTimeClick(Sender: TObject);
    procedure btnDebugMultiClick(Sender: TObject);
    procedure btnAgentSelectClick(Sender: TObject);
  private
    { Private declarations }
    FItemList: TList<TFrame1>;

    FSeatChk: TDateTime;
    FHeatChk: TDateTime;
    FComChk: String;
    FPLCChk: TDateTime;

    FComChk1: String;
    FComChk2: String;
    FComChk3: String;
    FComChk4: String;
    FComChk5: String;
    FComChk6: String;

    procedure StartUp;
    procedure Display;
    procedure Display2;
    procedure DisplayDome;

  public
    { Public declarations }
    FApplicationHandle: THandle;

    procedure LogView(ALog: string);
    procedure LogViewFloor(ALog1, ALog2, ALog3, ALog4, ALog5, ALog6: string);

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
  FApplicationHandle := Application.Handle;
  StartUp;
  Display;

  if (Global.ADConfig.StoreCode = 'BB001') then //돔골프
  begin
    pnlDome.Visible := True;

    {$IFDEF RELEASE}
    DisplayDome;
    {$ENDIF}
  end;

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

  Caption := Global.Store.StoreNm + '[' + Global.ADConfig.StoreCode + '] ' + Global.ADConfig.ApiUrl + ' / ' + Global.ADConfig.ProtocolType;

  if Global.ADConfig.MultiCom = True then
    pgcConfig.ActivePageIndex := 1
  else
    pgcConfig.ActivePageIndex := 0;

  if (Global.ADConfig.StoreCode <> 'CD001') then //CD001	스타골프클럽(일산)
    cxTabSheet4.Visible := False;

end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Display2;

  if Global.ADConfig.MultiCom = True then
  begin
    MainForm.LogViewFloor(global.CtrlBufferTemp1, global.CtrlBufferTemp2, global.CtrlBufferTemp3, global.CtrlBufferTemp4, global.CtrlBufferTemp5, global.CtrlBufferTemp6);
  end
  else
  begin
    MainForm.LogView(global.CtrlBufferTemp1);
  end;
end;

procedure TMainForm.LogView(ALog: string);
begin

  if Memo1.Lines.Count > 100 then
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

  if (global.ADConfig.StoreCode = 'B7001') then //프라자 3층
  begin
    if FPLCChk <> Global.PLCThreadTime then
    begin
      if pnlPLC.Color = clBtnFace then
        pnlPLC.Color := clGreen
      else
        pnlPLC.Color := clBtnFace;

      FPLCChk := Global.PLCThreadTime;
    end;
  end;

end;

procedure TMainForm.LogViewFloor(ALog1, ALog2, ALog3, ALog4, ALog5, ALog6: string);
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

  if FComChk5 <> ALog5 then
  begin
    if pnlCom5.Color = clBtnFace then
      pnlCom5.Color := clGreen
    else
      pnlCom5.Color := clBtnFace;

    FComChk5 := ALog5;
  end;

  if FComChk6 <> ALog6 then
  begin
    if pnlCom6.Color = clBtnFace then
      pnlCom6.Color := clGreen
    else
      pnlCom6.Color := clBtnFace;

    FComChk6 := ALog6;
  end;

  if FSeatChk <> Global.TeeboxThreadTime then
  begin
    if pnlSeat2.Color = clBtnFace then
      pnlSeat2.Color := clBlue
    else
      pnlSeat2.Color := clBtnFace;

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

procedure TMainForm.rgDeviceTypeClick(Sender: TObject);
var
  nIndex: Integer;
begin

  if rgDeviceType.ItemIndex <> Global.ADConfig.DeviceType then
  begin
    if MessageDlg('항목변경시 기존 장비는 모두 종료됩니다.'+#13+'변경 하시겠습니까?', mtConfirmation, [mbOK, mbCancel], 0) = mrCancel then
    begin
      rgDeviceType.ItemIndex := Global.ADConfig.DeviceType;
      Exit;
    end;
  end;

  nIndex := Global.ADConfig.DeviceType;
  Global.SetDeviceTypeConfig(rgDeviceType.ItemIndex);

  if nIndex = 0 then //선풍기
  begin
    Global.ComHeat_Dome.SetHeatUseAllOff;
  end
  else //히터
  begin
    Global.ComFan_Dome.SetFanUseAllOff;
  end;
end;

procedure TMainForm.Display;
var
  Index, ColIndex, RowIndex: Integer;
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

    RowIndex := 0;
    ColIndex := 0;
    sFloor := '';

    for Index := 1 to Global.Teebox.TeeboxLastNo do
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(Index);

      if rTeeboxInfo.DelYn = 'Y' then
        Continue;

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
      ASelectBoxProductItemStyle.Top := RowIndex * ASelectBoxProductItemStyle.Height + 23;

      if Global.ADConfig.MultiCom = True then
        ASelectBoxProductItemStyle.Parent := pnlMulti
      else
        ASelectBoxProductItemStyle.Parent := pnlSingle;

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

      if (Global.ADConfig.StoreCode = 'BB001') then //돔골프
      begin
        if Global.ADConfig.DeviceType = 0 then
        begin
          if Global.ComFan_Dome <> nil then
          begin
            ASelectBoxProductItemStyle.HeatStatus := Global.ComFan_Dome.GetFanUseStatus(rTeeboxInfo.TeeboxNm);
          end;
        end
        else
        begin
          if Global.ComHeat_Dome <> nil then
          begin
            ASelectBoxProductItemStyle.HeatStatus := Global.ComHeat_Dome.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
          end;
        end;
      end;

      if (Global.ADConfig.StoreCode = 'A8003') then //쇼골프(가양점)
      begin
        if Global.ComHeat_A8003 <> nil then
        begin
          ASelectBoxProductItemStyle.HeatStatus := Global.ComHeat_A8003.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
        end;
      end;

      if (Global.ADConfig.StoreCode = 'D4001') then // 수원CC
      begin
        if Global.ComHeat_D4001 <> nil then
        begin
          ASelectBoxProductItemStyle.HeatStatus := Global.ComHeat_D4001.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
        end;
      end;

      ASelectBoxProductItemStyle.DisPlaySeatInfo;

      ItemList.Add(ASelectBoxProductItemStyle);
      Inc(ColIndex);
      
    end;

    Height := ASelectBoxProductItemStyle.Top + ASelectBoxProductItemStyle.Height + 36 + 25 + 10; //516 477 25
    if Height < 516 then
      Height := 516;

    if Global.ADConfig.MultiCom = True then
      Height := 910;

    if (Global.ADConfig.StoreCode = 'A8001') then
      Width := 1400
    else
      Width := 1250;

  finally

  end;
end;

procedure TMainForm.Display2;
var
  Index, nTeeboxNo: Integer;
  rTeeboxInfo: TTeeboxInfo;
begin
  try
    if FItemList.Count = 0 then
      Exit;

    for Index := 0 to FItemList.Count - 1 do
    begin
      nTeeboxNo := FItemList[Index].TeeboxInfo.TeeboxNo;
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(nTeeboxNo);

      FItemList[Index].TeeboxInfo := rTeeboxInfo;
      FItemList[Index].ReserveCnt := IntToStr(Global.ReserveList.GetTeeboxReserveNextListCnt(rTeeboxInfo.TeeboxNo));
      {
      if Global.ControlComPortHeatMonThread <> nil then
      begin
        FItemList[Index].HeatStatus := Global.ControlComPortHeatMonThread.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
      end;
      }
      if Global.TcpThreadHeat <> nil then
      begin
        FItemList[Index].HeatStatus := Global.TcpThreadHeat.GetHeatUseStatus(rTeeboxInfo.TeeboxNo);
      end;

      if (Global.ADConfig.StoreCode = 'BB001') then //돔골프
      begin
        if Global.ADConfig.DeviceType = 0 then
        begin
          if Global.ComFan_Dome <> nil then
          begin
            FItemList[Index].HeatStatus := Global.ComFan_Dome.GetFanUseStatus(rTeeboxInfo.TeeboxNm);
          end;
        end
        else
        begin
          if Global.ComHeat_Dome <> nil then
          begin
            FItemList[Index].HeatStatus := Global.ComHeat_Dome.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
          end;
        end;
      end;

      if (Global.ADConfig.StoreCode = 'A8003') then //쇼골프(가양점)
      begin
        if Global.ComHeat_A8003 <> nil then
        begin
          FItemList[Index].HeatStatus := Global.ComHeat_A8003.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
        end;
      end;

      if (Global.ADConfig.StoreCode = 'D4001') then // 수원CC
      begin
        if Global.ComHeat_D4001 <> nil then
        begin
          FItemList[Index].HeatStatus := Global.ComHeat_D4001.GetHeatUseStatus(rTeeboxInfo.TeeboxNm);
        end;
      end;

      FItemList[Index].DisPlaySeatInfo;
    end;
  finally

  end;
end;

procedure TMainForm.DisplayDome;
begin
  rgDeviceType.ItemIndex := Global.ADConfig.DeviceType;
  edtHeatOnTime.Text := IntToStr(Global.ADConfig.HeatOnTime);
  edtHeatOffTime.Text := IntToStr(Global.ADConfig.HeatOffTime);
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
  Memo4.Lines.Add('AssignMin : ' + IntToStr(rTeeboxInfo.TeeboxReserve.AssignMin));
  Memo4.Lines.Add('RemainMinute : ' + IntToStr(rTeeboxInfo.RemainMinute));
  Memo4.Lines.Add('RemainBall : ' + IntToStr(rTeeboxInfo.RemainBall));
  Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
  Memo4.Lines.Add('PrepareMin : ' + IntToStr(rTeeboxInfo.TeeboxReserve.PrepareMin));
  Memo4.Lines.Add('ReserveDate : ' + rTeeboxInfo.TeeboxReserve.ReserveDate);
  Memo4.Lines.Add('PrepareStartDate : ' + rTeeboxInfo.TeeboxReserve.PrepareStartDate);
  Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
  Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
  Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);
  Memo4.Lines.Add('AssignYn : ' + rTeeboxInfo.TeeboxReserve.AssignYn);
  Memo4.Lines.Add('UseReset : ' + rTeeboxInfo.UseReset);
  if rTeeboxInfo.ErrorReward = True then
    Memo4.Lines.Add('ErrorReward : True')
  else
    Memo4.Lines.Add('ErrorReward : False');

  sStr := Global.ReserveList.GetTeeboxReserveNextView(rTeeboxInfo.TeeboxNo);

  Memo4.Lines.Add(sStr);
end;

procedure TMainForm.btnHeatOnOffTimeClick(Sender: TObject);
var
  nOnTime, nOffTime: Integer;
begin
  if Trim(edtHeatOnTime.Text) = '' then
  begin
    edtHeatOnTime.Text := '60';
    Exit;
  end;

  if Trim(edtHeatOffTime.Text) = '' then
  begin
    edtHeatOffTime.Text := '60';
    Exit;
  end;

  nOnTime := StrToInt(edtHeatOnTime.Text);
  nOffTime := StrToInt(edtHeatOffTime.Text);
  Global.SetHeatOnOffTimeConfig(nOnTime, nOffTime);

  if Global.ComHeat_Dome <> nil then
    Global.ComHeat_Dome.HeatOnOffTimeSetting(nOnTime, nOffTime);
end;

procedure TMainForm.btnAgentSelectClick(Sender: TObject);
begin
  Global.XGolfDM.AgentSelectAll;
end;

procedure TMainForm.btnBallbackListClick(Sender: TObject);
var
  i, nDelay: integer;
  sStr, sTeeboxNm, sReserveNo: String;
  nAssignMin, nRemainMin: integer;
begin
  mmoBallbackList.Clear;

  nDelay := Global.ConfigBall.ReadInteger('BallBack', 'Delay', 0);
  laBallBackStart.Caption := Global.ConfigBall.ReadString('BallBack', 'Start', '') + ' / 볼회수시간: ' + IntToStr(nDelay);

  for I := 1 to Global.Teebox.TeeboxLastNo do
  begin
    sTeeboxNm := Global.ConfigBall.ReadString('Teebox_' + IntToStr(I), 'TeeboxNm', '');
    sReserveNo := Global.ConfigBall.ReadString('Teebox_' + IntToStr(I), 'ReserveNo', '');
    nAssignMin := Global.ConfigBall.ReadInteger('Teebox_' + IntToStr(I), 'AssignMin', 0);
    nRemainMin := Global.ConfigBall.ReadInteger('Teebox_' + IntToStr(I), 'RemainMinute', 0);

    if nRemainMin > 0 then
      sStr := '타석: ' + sTeeboxNm + ' / 예약번호:' + sReserveNo + ' / 총배정시간 : ' + IntToStr(nAssignMin) + ' -> ' + IntToStr(nAssignMin + nDelay) + ' / 잔여시간: ' + IntToStr(nRemainMin)
    else
      sStr := '타석: ' + sTeeboxNm + ' / 빈타석';

    mmoBallbackList.Lines.Add(sStr);
  end;
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
                  '"user_id":"ADServer",' +     //사용자 Id	user_id
                  '"teebox_no":"' + sSeatNo + '"' +   //타석기 번호	teebox_no
               '}';

  global.tcpserver.SetTeeboxHoldCancel(sSendData);
end;

procedure TMainForm.btnHeatOnClick(Sender: TObject);
var
  sTeeboxNo, sResult: String;
  sSendData: AnsiString;
begin
  if Trim(edTeeboxNo.text) = '' then
    Exit;

  sTeeboxNo := edTeeboxNo.text;

  sSendData := '{' +
                  '"store_cd":"' + global.ADConfig.StoreCode + '",' +
                  '"api":"K414_TeeBoxHeat",' +
                  '"user_id":"TEST",' +
                  '"teebox_no":"' + sTeeboxNo + '",' +
                  '"heat_time":"",' +
                  '"heat_use":"1"' +
               '}';

  sResult := global.tcpserver.SetTeeboxHeatUsed(sSendData);
  Memo4.Text := sResult;
end;

procedure TMainForm.btnDebugMultiClick(Sender: TObject);
begin
  if (Global.ADConfig.StoreCode = 'A8001') then //쇼골프
    Global.ShowDebug;
end;

procedure TMainForm.btnHeatOffClick(Sender: TObject);
var
  sTeeboxNo, sResult: String;
  sSendData: AnsiString;
begin
  if Trim(edTeeboxNo.text) = '' then
    Exit;

  sTeeboxNo := edTeeboxNo.text;

  sSendData := '{' +
                  '"store_cd":"' + global.ADConfig.StoreCode + '",' +
                  '"api":"K414_TeeBoxHeat",' +
                  '"user_id":"TEST",' +
                  '"teebox_no":"' + sTeeboxNo + '",' +
                  '"heat_time":"",' +
                  '"heat_use":"0"' +
               '}';

  sResult := global.tcpserver.SetTeeboxHeatUsed(sSendData);
  Memo4.Text := sResult;
end;

procedure TMainForm.btnPLCClick(Sender: TObject);
var
  sStr: String;
begin
  Memo4.Lines.Clear;
  if global.ComInfornetPLC <> nil then
  begin
    sStr := global.ComInfornetPLC.GetTeeboxUse;
  end
  else
  begin
    sStr := 'global.ComInfornetPLC = nil';
  end;
  Memo4.Lines.Add(sStr);
end;


end.
