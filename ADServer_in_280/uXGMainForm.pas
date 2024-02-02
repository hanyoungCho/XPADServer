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
  Frame.ItemStyle, IdHTTP, CPortCtl, uXGClientDM, IdAntiFreezeBase, IdAntiFreeze,
  System.Threading, ShellAPI,
  { Indy }
  IdIcmpClient,
  { Custom }
  uArpHelper, uTapoHelper, Data.DB, Vcl.DBCtrls, Vcl.Grids, Vcl.DBGrids,
  Vcl.ComCtrls;

type
  TMainForm = class(TForm)
    pgcConfig: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    Timer1: TTimer;
    Panel1: TPanel;
    IdAntiFreeze1: TIdAntiFreeze;
    Panel5: TPanel;
    laTeebox: TLabel;
    edApiResult: TEdit;
    pnlEmergency: TPanel;
    cxTabSheet2: TcxTabSheet;
    mmoSendMsg: TMemo;
    panToolbar: TPanel;
    btnBroadcast: TButton;
    btnEnd: TButton;
    btnStart: TButton;
    btnPrepare: TButton;
    Panel3: TPanel;
    Label6: TLabel;
    edtTerminalUUID: TEdit;
    btnDeviceList: TButton;
    Panel4: TPanel;
    btnSetDeviceOff: TButton;
    btnSetDeviceOn: TButton;
    btnDeviceInfo: TButton;
    btnRescanIPList: TButton;
    btnRefreshIPList: TButton;
    lbxIPList: TListBox;
    lbxDeviceList: TListBox;
    mmoLog: TMemo;
    Panel2: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Memo4: TMemo;
    btnReserveInfo: TButton;
    edTeeboxNo: TEdit;
    Button8: TButton;
    btnHoldCancel: TButton;
    edTeeboxNm: TEdit;
    btnSetting: TButton;
    btnCtrlLock: TButton;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    cxTabSheet3: TcxTabSheet;
    Panel6: TPanel;
    Panel7: TPanel;
    btnAgentSelect: TButton;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    btnRunAppEnd: TButton;
    btnRunAppStart: TButton;
    btnWOL: TButton;
    edWOL: TEdit;
    edBeam: TEdit;
    btnBeam: TButton;
    cbBeamType: TComboBox;
    cbBeamOnOff: TComboBox;
    laWOL: TLabel;
    btnCheckWOL: TButton;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnReserveInfoClick(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnHoldCancelClick(Sender: TObject);
    procedure btnDeviceListClick(Sender: TObject);
    procedure btnSetDeviceOnClick(Sender: TObject);
    procedure btnSetDeviceOffClick(Sender: TObject);
    procedure btnDeviceInfoClick(Sender: TObject);
    procedure btnRescanIPListClick(Sender: TObject);
    procedure btnRefreshIPListClick(Sender: TObject);
    procedure lbxDeviceListDblClick(Sender: TObject);
    procedure lbxDeviceListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure btnPrepareClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnEndClick(Sender: TObject);
    procedure btnBroadcastClick(Sender: TObject);
    procedure btnSettingClick(Sender: TObject);
    procedure btnCtrlLockClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnAgentSelectClick(Sender: TObject);
    procedure btnRunAppStartClick(Sender: TObject);
    procedure btnRunAppEndClick(Sender: TObject);
    procedure btnWOLClick(Sender: TObject);
    procedure btnBeamClick(Sender: TObject);
    procedure btnCheckWOLClick(Sender: TObject);
  private
    { Private declarations }
    FItemList: TList<TFrame1>;

    FSeatChk: TDateTime;

    procedure StartUp;
    procedure Display(APloor: Integer);
    procedure Display_R(APloor: Integer);
    procedure Display2(APloor: Integer);
    procedure Display2_R(APloor: Integer);

    procedure RefreshIPList;

    function CheckDeviceIndex(const AIndex: Integer; var AErrMsg: string): Boolean;

    procedure ShowDeviceInfo;

  public
    { Public declarations }
    FApplicationHandle: THandle;

    procedure LogView(ALog: string);
    procedure AddLog(const ALogText: string; const AUseLineBreak: Boolean=False);

    property ItemList: TList<TFrame1> read FItemList write FItemList;
  end;

var
  MainForm: TMainForm;

implementation

uses
  uGlobal, uFunction, uConsts,
  CkGlobal, CkJsonObject, CkJsonArray, uCommonLib,
  IdGlobal, JSON,
  uPassForm;

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
var
  sErrMsg: string;
begin
  FApplicationHandle := Application.Handle;
  StartUp;

  if Global.ADConfig.StoreType = 0 then
    Display(1)
  else
    Display_R(1);
  Timer1.Enabled := True;

  pgcConfig.ActivePageIndex := 0;

  if (Global.ADConfig.StoreCode <> 'C5001') then //GTS아카데미 장현점
  begin
    btnCheckWOL.Visible := False;
  end;
  laWOL.Visible := False;

end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;
  Global.Free;
  FreeAndNil(FItemList);
  {
  if Assigned(FArpTable) then
    FArpTable.Free;
  }
  lbxDeviceList.Items.Clear;
end;

procedure TMainForm.StartUp;
begin
  Global := TGlobal.Create;
  Global.StartUp;

  {$IFDEF RELEASE}
  if Global.ADConfig.TapoUse = True then
  begin
    RefreshIPList;
    edtTerminalUUID.Text := Global.Tapo.TerminalUUID;
  end;
  {$ENDIF}

  Caption := Global.Store.StoreNm + '[' + Global.ADConfig.StoreCode + '] ' + Global.ADConfig.ApiUrl;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  if Global.ADConfig.StoreType = 0 then
    Display2(1)
  else
    Display2_R(1);

  //MainForm.LogView(global.CtrlBufferTemp);
  if FSeatChk <> Global.TeeboxThreadTime then
  begin
    if laTeebox.Color = clBtnFace then
      laTeebox.Color := clBlue
    else
      laTeebox.Color := clBtnFace;

    FSeatChk := Global.TeeboxThreadTime;
  end;
end;

procedure TMainForm.LogView(ALog: string);
begin

  if FSeatChk <> Global.TeeboxThreadTime then
  begin
    if laTeebox.Color = clBtnFace then
      laTeebox.Color := clBlue
    else
      laTeebox.Color := clBtnFace;

    FSeatChk := Global.TeeboxThreadTime;
  end;
end;

procedure TMainForm.Display(APloor: Integer);
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

    for Index := 0 to Global.Teebox.TeeboxCnt - 1 do
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxIndexInfo(Index);

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

      nColIndex := 2;

      if ColIndex = nColIndex then
      begin
        Inc(RowIndex);
        ColIndex := 0;
      end;

      ASelectBoxProductItemStyle := TFrame1.Create(nil);

      ASelectBoxProductItemStyle.Left := ColIndex * ASelectBoxProductItemStyle.Width;
      ASelectBoxProductItemStyle.Top := RowIndex * ASelectBoxProductItemStyle.Height + 23;
      ASelectBoxProductItemStyle.Parent := Panel1;
      ASelectBoxProductItemStyle.TeeboxInfo := rTeeboxInfo;
      ASelectBoxProductItemStyle.DisPlaySeatInfo;

      ItemList.Add(ASelectBoxProductItemStyle);
      Inc(ColIndex);

    end;
  finally

  end;
end;

procedure TMainForm.Display_R(APloor: Integer);
var
  Index, ColIndex, RowIndex: Integer;
  ASelectBoxProductItemStyle: TFrame1;
  rRoomInfo: TRoomInfo;
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

    for Index := 0 to Global.Room.RoomCnt - 1 do
    begin
      rRoomInfo := Global.Room.GetRoomIndexInfo(Index);

      if rRoomInfo.DelYn = 'Y' then
        Continue;

      nColIndex := 2;
      if ColIndex = nColIndex then
      begin
        Inc(RowIndex);
        ColIndex := 0;
      end;

      ASelectBoxProductItemStyle := TFrame1.Create(nil);

      ASelectBoxProductItemStyle.Left := ColIndex * ASelectBoxProductItemStyle.Width;
      ASelectBoxProductItemStyle.Top := RowIndex * ASelectBoxProductItemStyle.Height + 23;
      ASelectBoxProductItemStyle.Parent := Panel1;
      ASelectBoxProductItemStyle.RoomInfo := rRoomInfo;
      ASelectBoxProductItemStyle.DisPlayRoomInfo;

      ItemList.Add(ASelectBoxProductItemStyle);
      Inc(ColIndex);

    end;
  finally

  end;
end;

procedure TMainForm.Display2(APloor: Integer);
var
  Index: Integer;
  rTeeboxInfo: TTeeboxInfo;
  nTeeboxNo: Integer;
begin
  try
    if FItemList.Count = 0 then
      Exit;
    
    for Index := 0 to FItemList.Count - 1 do
    begin
      nTeeboxNo := FItemList[Index].TeeboxInfo.TeeboxNo;
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(nTeeboxNo);
      FItemList[Index].TeeboxInfo := rTeeboxInfo;
      FItemList[Index].ReserveCnt := IntToStr(Global.ReserveList.GetTeeboxReserveNextListCnt(nTeeboxNo));
      FItemList[Index].DisPlaySeatInfo;
    end;

  finally

  end;
end;

procedure TMainForm.Display2_R(APloor: Integer);
var
  Index: Integer;
  rRoomInfo: TRoomInfo;
  nRoomNo: Integer;
begin
  if FItemList.Count = 0 then
    Exit;

  for Index := 0 to FItemList.Count - 1 do
  begin
    nRoomNo := FItemList[Index].RoomInfo.RoomNo;
    rRoomInfo := Global.Room.GetRoomInfo(nRoomNo);
    FItemList[Index].RoomInfo := rRoomInfo;
    FItemList[Index].DisPlayRoomInfo;
  end;

end;

procedure TMainForm.btnRefreshIPListClick(Sender: TObject);
begin
  RefreshIPList;
end;

procedure TMainForm.btnRescanIPListClick(Sender: TObject);
begin
  //RescanIPList;
  Global.Tapo.RescanIPList;
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
  Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
  Memo4.Lines.Add('ReserveDate : ' + rTeeboxInfo.TeeboxReserve.ReserveDate);
  Memo4.Lines.Add('PrepareStartDate : ' + rTeeboxInfo.TeeboxReserve.PrepareStartDate);
  Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
  Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
  Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);
  Memo4.Lines.Add('AssignYn : ' + rTeeboxInfo.TeeboxReserve.AssignYn);


  Memo4.Lines.Add('AgentIP_R : ' + rTeeboxInfo.AgentIP_R);
  Memo4.Lines.Add('AgentIP_L : ' + rTeeboxInfo.AgentIP_L);
  Memo4.Lines.Add('AgentMAC_R : ' + rTeeboxInfo.AgentMAC_R);
  Memo4.Lines.Add('AgentMAC_L : ' + rTeeboxInfo.AgentMAC_L);

  Memo4.Lines.Add('BeamType : ' + rTeeboxInfo.BeamType);
  Memo4.Lines.Add('BeamPW : ' + rTeeboxInfo.BeamPW);
  Memo4.Lines.Add('BeamIP : ' + rTeeboxInfo.BeamIP);

  sStr := Global.ReserveList.GetTeeboxReserveNextView(rTeeboxInfo.TeeboxNo);

  Memo4.Lines.Add(sStr);
end;

procedure TMainForm.btnRunAppEndClick(Sender: TObject);
begin
  ShellExecute(FApplicationHandle, 'open', PChar(Global.HomeDir + 'exit.vbs'), nil, nil, SW_SHOW);
  Global.Log.LogWrite(Global.HomeDir + 'exit.vbs');
end;

procedure TMainForm.btnRunAppStartClick(Sender: TObject);
begin
  ShellExecute(FApplicationHandle, 'open', PChar(Global.HomeDir + 'run.vbs'), nil, nil, SW_SHOW);
  Global.Log.LogWrite(Global.HomeDir + 'run.vbs');
end;

procedure TMainForm.Button8Click(Sender: TObject);
var
  rTeeboxInfo: TTeeboxInfo;
  nIndex: Integer;
begin

  Memo4.Lines.Clear;
  for nIndex := 0 to Global.Teebox.TeeboxCnt - 1 do
  begin
    rTeeboxInfo := Global.Teebox.GetTeeboxIndexInfo(nIndex);

    if (rTeeboxInfo.RemainMinute > 0) and (rTeeboxInfo.UseStatus = '1') and
       (rTeeboxInfo.TeeboxReserve.ReserveStartDate = '') then
    begin
      Memo4.Lines.Add('SeatNm : ' + rTeeboxInfo.TeeboxNm);
      Memo4.Lines.Add('RemainMinute : ' + IntToStr(rTeeboxInfo.RemainMinute));
      Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
      Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
      Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
      Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);
    end;
  end;
end;

procedure TMainForm.btnSetDeviceOffClick(Sender: TObject);
var
  nIndex: Integer;
  sIP, sErrMsg: string;
begin
  //SetDeviceOnOff(lbxDeviceList.ItemIndex, False);
  nIndex := lbxDeviceList.ItemIndex;

  try
    if not CheckDeviceIndex(nIndex, sErrMsg) then
      raise Exception.Create(sErrMsg);

    sIP := TDeviceInfo(lbxDeviceList.Items.Objects[nIndex]).IP;
    Global.Tapo.SetDeviceOnOff(sIP, False, True);
  except
    on E: Exception do
      AddLog(Format('SetDeviceOnOff(%s).Exception : %s', [sIP, E.Message]));
  end;
end;

procedure TMainForm.btnSetDeviceOnClick(Sender: TObject);
var
  nIndex: Integer;
  sIP, sErrMsg: string;
begin
  //SetDeviceOnOff(lbxDeviceList.ItemIndex, True);
  nIndex := lbxDeviceList.ItemIndex;

  try
    if not CheckDeviceIndex(nIndex, sErrMsg) then
      raise Exception.Create(sErrMsg);

    sIP := TDeviceInfo(lbxDeviceList.Items.Objects[nIndex]).IP;
    Global.Tapo.SetDeviceOnOff(sIP, True, True);
  except
    on E: Exception do
      AddLog(Format('SetDeviceOnOff(%s).Exception : %s', [sIP, E.Message]));
  end;
end;

procedure TMainForm.btnDeviceInfoClick(Sender: TObject);
var
  sIP, sErrMsg: String;
  nIndex: integer;
begin
  //GetDeviceInfo(lbxDeviceList.ItemIndex);
  try
    {
    nIndex := lbxDeviceList.ItemIndex;
    if not CheckDeviceIndex(nIndex, sErrMsg) then
      raise Exception.Create(sErrMsg);

    sIP := TDeviceInfo(lbxDeviceList.Items.Objects[nIndex]).IP;
    }

    sIP := Edit1.Text;
    Global.Tapo.GetDeviceInfo(sIP);
  except
    on E: Exception do
       AddLog(Format('GetDeviceInfo(%s).Exception : %s', [sIP, E.Message]));
  end;
end;

procedure TMainForm.btnDeviceListClick(Sender: TObject);
var
  I: integer;
  rDI: TDeviceInfo;
begin
  //GetDeviceList;
  Global.Tapo.GetDeviceList;

  lbxDeviceList.Items.Clear;
  lbxDeviceList.Items.BeginUpdate;
  try

    for I := 0 to Global.Tapo.List.Count - 1 do
    begin
      rDI := TDeviceInfo(Global.Tapo.List.Objects[I]);

      lbxDeviceList.Items.AddObject(Format('%d | %s | %s | %s | %s %s', [rDI.Status, rDI.DeviceType, rDI.DeviceName, rDI.DeviceAlias, rDI.MAC, IIF(rDI.IP.IsEmpty, '(Offline)', rDI.IP)]), TObject(rDI));
    end;

  finally
    lbxDeviceList.Items.EndUpdate;
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
                  '"user_id":"T0001",' +     //사용자 Id	user_id
                  '"teebox_no":"' + sSeatNo + '"' +   //타석기 번호	teebox_no
               '}';

  global.tcpserver.SetTeeboxHoldCancel(sSendData);
end;

procedure TMainForm.RefreshIPList;
var
  I: Integer;
  sMac, sIP: String;
begin

  Global.Tapo.ArpTable.Refresh;
  lbxIPList.Items.Clear;
  lbxIPList.Items.BeginUpdate;
  try
    for I := 0 to Pred(Global.Tapo.ArpTable.List.Count) do
      if Global.Tapo.ArpTable.GetARPInfo(I, sMac, sIP) = True then
      begin
        lbxIPList.Items.Add(Format('%s %s', [sMac, sIP]));
        //Global.Teebox.SetTeeboxIP(PARPInfo(FArpTable.List[I])^.MAC, PARPInfo(FArpTable.List[I])^.IP);
      end;
  finally
    lbxIPList.Items.EndUpdate;
    //AddLog(Format('%d Local IP(s) Detected.', [lbxIPList.Items.Count]));
  end;
end;

procedure TMainForm.lbxDeviceListDblClick(Sender: TObject);
begin
  ShowDeviceInfo;
end;

procedure TMainForm.lbxDeviceListDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  OldColor: TColor;
begin
  with (Control as TListBox).Canvas do
  begin
    OldColor := Font.Color;
    with TDeviceInfo((Control as TListBox).Items.Objects[Index]) do
    begin
      if (odSelected in State) then
      begin
        Brush.Color := clHighlight;
        if DeviceOn then
          Font.Color := clWhite
        else if OverHeated then
          Font.Color := clRed
        else
          Font.Color := clBlack;
      end
      else
      begin
        Brush.Color := clWhite;
        if DeviceOn then
          Font.Color := clHighlight
        else if OverHeated then
          Font.Color := clRed
        else
          Font.Color := clBlack;
      end;
    end;

    FillRect(Rect);
    TextOut(Rect.Left, Rect.Top, (Control as TListBox).Items[Index]);
    Font.Color := OldColor;
  end;

end;

function TMainForm.CheckDeviceIndex(const AIndex: Integer; var AErrMsg: string): Boolean;
var
  sIP: string;
begin
  Result := False;
  AErrMsg := '';
  try
    if (AIndex < 0) then
      raise Exception.Create('DeviceList is Empty');

    sIP := TDeviceInfo(lbxDeviceList.Items.Objects[AIndex]).IP;
    if sIP.IsEmpty then
      raise Exception.Create('Device is Offline');

    Result := True;
  except
    on E: Exception do
      AErrMsg := E.Message;
  end;
end;

procedure TMainForm.ShowDeviceInfo;
var
  sDeviceInfo: string;
  nIndex, nOnTime: Integer;
  bDeviceOn, bOverHeated: Boolean;
begin
  nIndex := lbxDeviceList.ItemIndex;
  if (nIndex < 0) then
    Exit;

  with TDeviceInfo(lbxDeviceList.Items.Objects[nIndex]) do
  begin
    sDeviceInfo :=
      Format('IP Address = %s', [IP]) + #13#10 +
      Format('MAC Address = %s', [MAC]) + #13#10 +
      Format('Device Type = %s', [DeviceType]) + #13#10 +
      Format('Device Name = %s', [DeviceName]) + #13#10 +
      Format('Device Alias = %s', [DeviceAlias]) + #13#10 +
      Format('Device On = %s', [IIF(DeviceOn, 'True', 'False')]) + #13#10 +
      Format('Overheated = %s', [IIF(OverHeated, 'True', 'False')]) + #13#10 +
      Format('On Times = %d', [OnTimes]);
    MessageBox(0, PChar(sDeviceInfo), PChar('Device Information'), MB_ICONWARNING or MB_OK or MB_TOPMOST or MB_APPLMODAL);
  end;
end;

procedure TMainForm.btnPrepareClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9001, "teebox_no":' + ', "reserve_no":"T00010001", "prepare_min":5}';
end;

procedure TMainForm.btnStartClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9002, "teebox_no":' + ', "reserve_no":"T00010001", "assign_min":60}';
end;

procedure TMainForm.btnWOLClick(Sender: TObject);
var
  sLogMsg: String;
begin
  Memo4.Lines.Clear;
  if Trim(edWOL.text) = '' then
  begin
    Memo4.Lines.Add('Wake On Lan Mac 주소없음');
    Exit;
  end;

  sLogMsg := Global.Api.WakeOnLan(edWOL.text);
  if sLogMsg= '' then
    Memo4.Lines.Add('Wake On Lan 전송')
  else
    Memo4.Lines.Add(sLogMsg);
end;

procedure TMainForm.btnBeamClick(Sender: TObject);
begin
  Memo4.Lines.Clear;
  if Trim(edBeam.text) = '' then
  begin
    Memo4.Lines.Add('Beam IP 없음');
    Exit;
  end;

  if cbBeamType.ItemIndex = 0 then
    Global.Api.PostBeamPJLinkApi(edBeam.text, '', cbBeamOnOff.ItemIndex)
  else
    Global.Api.PostBeamHitachiApi(edBeam.text, cbBeamOnOff.ItemIndex);
end;

procedure TMainForm.btnEndClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9003, "teebox_no":' + ', "reserve_no":"T00010001"}';
end;

procedure TMainForm.btnSettingClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9005, "teebox_no": ' + ', "method": }';
end;

procedure TMainForm.btnAgentSelectClick(Sender: TObject);
begin
  Global.XGolfDM.AgentSelectAll;
end;



procedure TMainForm.btnBroadcastClick(Sender: TObject);
var
  sSendStr: String;

  jObj: TJSONObject;
  nApi, nTeeboxNo: Integer;
begin

  sSendStr := mmoSendMsg.Text;

  try
    try
      jObj := TJSONObject.ParseJSONValue( sSendStr ) as TJSONObject;
      nApi := StrToInt(jObj.GetValue('api_id').Value);
      nTeeboxNo := StrToInt(jObj.GetValue('teebox_no').Value);

      Global.TcpAgentServer.BroadcastMessage(sSendStr);
    except
    on E: Exception do
      ShowMessage('데이타를 확인해 주세요');
    end;
  finally
    FreeAndNil(jObj);
  end;
end;

procedure TMainForm.btnCheckWOLClick(Sender: TObject);
var
  sDt: String;
begin
  if laWOL.Visible = True then
  begin
    btnCheckWOL.Caption := 'WOL해제';
    laWOL.Visible := False;

    Global.SetWOLUnusedDt('');
  end
  else
  begin
    btnCheckWOL.Caption := 'WOL설정';
    sDt := FormatDateTime('YYYY-MM-DD', Now + 1);
    laWOL.Visible := True;
    laWOL.Caption := sDt + ' 휴장. PC자동전원ON 미작동';

    Global.SetWOLUnusedDt(sDt);
  end;

end;

procedure TMainForm.btnCtrlLockClick(Sender: TObject);
begin
  if Global.TapoCtrlLock = True then
  begin
    Global.TapoCtrlLock := False;
    Global.Config.WriteString('ADInfo', 'TapoCtrlLock', 'N');
    btnCtrlLock.Caption := '제어잠금';
  end
  else
  begin
    try
      Form1 := TForm1.Create(nil);
      if Form1.ShowModal <> mrOk then
        exit;
    finally
      FreeAndNil(Form1);
    end;

    Global.TapoCtrlLock := True;
    Global.Config.WriteString('ADInfo', 'TapoCtrlLock', 'Y');
    btnCtrlLock.Caption := '제어해제';
  end;

end;

procedure TMainForm.AddLog(const ALogText: string; const AUseLineBreak: Boolean);
begin
  mmoLog.Lines.BeginUpdate;
  try
    if mmoLog.Lines.Count > 100 then
      mmoLog.Lines.Delete(0);

    mmoLog.Lines.Add(ALogText);
  finally
    mmoLog.Lines.EndUpdate;
  end;
end;

end.
