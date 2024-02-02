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
  Vcl.Samples.Spin, ShellAPI, Data.DB, Vcl.DBCtrls, Vcl.Grids, Vcl.DBGrids;

type
  TMainForm = class(TForm)
    pgcConfig: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    cxTabSheet4: TcxTabSheet;
    Timer1: TTimer;
    Panel1: TPanel;
    IdAntiFreeze1: TIdAntiFreeze;
    Panel3: TPanel;
    laTeebox: TLabel;
    Panel4: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Memo4: TMemo;
    btnReserveInfo: TButton;
    edTeeboxNo: TEdit;
    Button8: TButton;
    edTeeboxNm: TEdit;
    panHeader: TPanel;
    Label3: TLabel;
    lblConnCount: TLabel;
    Label4: TLabel;
    lblServerStatus: TLabel;
    Label5: TLabel;
    mmoSendMsg: TMemo;
    panToolbar: TPanel;
    btnBroadcast: TButton;
    btnEnd: TButton;
    btnStart: TButton;
    btnPrepare: TButton;
    Panel2: TPanel;
    Label6: TLabel;
    edtTerminalUUID: TEdit;
    btnDeviceList: TButton;
    lbxIPList: TListBox;
    lbxDeviceList: TListBox;
    mmoLog: TMemo;
    Panel5: TPanel;
    btnSetDeviceOff: TButton;
    btnSetDeviceOn: TButton;
    btnDeviceInfo: TButton;
    btnRescanIPList: TButton;
    btnRefreshIPList: TButton;
    btnSetting: TButton;
    btnHoldCancel: TButton;
    btnChange: TButton;
    btnRunAppStart: TButton;
    btnRunAppEnd: TButton;
    cxTabSheet2: TcxTabSheet;
    Panel7: TPanel;
    btnAgentSelect: TButton;
    Panel6: TPanel;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    edBeam: TEdit;
    cbBeamType: TComboBox;
    cbBeamOnOff: TComboBox;
    btnBeam: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnReserveInfoClick(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnBroadcastClick(Sender: TObject);
    procedure btnPrepareClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnEndClick(Sender: TObject);
    procedure btnRefreshIPListClick(Sender: TObject);
    procedure btnRescanIPListClick(Sender: TObject);
    procedure btnDeviceListClick(Sender: TObject);
    procedure btnDeviceInfoClick(Sender: TObject);
    procedure btnSetDeviceOnClick(Sender: TObject);
    procedure btnSetDeviceOffClick(Sender: TObject);
    procedure lbxDeviceListDblClick(Sender: TObject);
    procedure lbxDeviceListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure btnSettingClick(Sender: TObject);
    procedure btnHoldCancelClick(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
    procedure btnRunAppStartClick(Sender: TObject);
    procedure btnRunAppEndClick(Sender: TObject);
    procedure btnAgentSelectClick(Sender: TObject);
    procedure btnBeamClick(Sender: TObject);
  private
    { Private declarations }
    FItemList: TList<TFrame1>;

    FSeatChk: TDateTime;

    procedure StartUp;
    procedure Display(APloor: Integer);
    procedure Display2(APloor: Integer);

    procedure RefreshIPList;
    function CheckDeviceIndex(const AIndex: Integer; var AErrMsg: string): Boolean;
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
  IdGlobal, JSON;

{$R *.dfm}

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //Application.Minimize;
  //Action := caNone;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FApplicationHandle := Application.Handle;
  StartUp;

  Display(1);
  Timer1.Enabled := True;

  pgcConfig.ActivePageIndex := 0;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;
  Global.Free;
  FreeAndNil(FItemList);
  lbxDeviceList.Items.Clear;
end;

procedure TMainForm.lbxDeviceListDblClick(Sender: TObject);
begin
  //ShowDeviceInfo;
end;

procedure TMainForm.lbxDeviceListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
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

procedure TMainForm.StartUp;
begin
  Global := TGlobal.Create;
  Global.StartUp;

  if Global.ADConfig.TapoUse = True then
  begin
  RefreshIPList;
  edtTerminalUUID.Text := Global.Tapo.TerminalUUID;
  end;

  Caption := Global.Store.StoreNm + '[' + Global.ADConfig.StoreCode + '] ' + Global.ADConfig.ApiUrl;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Display2(1);

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
  {
  if lbxLog.Items.Count > 50 then
    lbxLog.Items.Delete(0);
    //lbxLog.Lines.Clear;

  lbxLog.Items.Add('[' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '] ' + ALog);
  lbxLog.ItemIndex := Pred(lbxLog.Items.Count);
  }
  lblConnCount.Caption := IntToStr(Global.TcpAgentServer.ClientCount);
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
        sFloor := rTeeboxInfo.FloorCd;

      if sFloor <> rTeeboxInfo.FloorCd then
      begin
        Inc(RowIndex);
        ColIndex := 0;

        sFloor := rTeeboxInfo.FloorCd;
      end;

      nColIndex := 2;

      if ColIndex = nColIndex then
      begin
        Inc(RowIndex);
        ColIndex := 0;
      end;

      ASelectBoxProductItemStyle := TFrame1.Create(nil);

      ASelectBoxProductItemStyle.Left := ColIndex * ASelectBoxProductItemStyle.Width;
      ASelectBoxProductItemStyle.Top := RowIndex * ASelectBoxProductItemStyle.Height;
      ASelectBoxProductItemStyle.Parent := Panel1;
      ASelectBoxProductItemStyle.TeeboxInfo := rTeeboxInfo;
      ASelectBoxProductItemStyle.DisPlaySeatInfo;

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
begin
  try
    if FItemList.Count = 0 then
      Exit;

    for Index := 1 to Global.Teebox.TeeboxLastNo do
    begin
      rTeeboxInfo := Global.Teebox.GetTeeboxInfo(Index);
      FItemList[Index - 1].TeeboxInfo := rTeeboxInfo;
      FItemList[Index - 1].ReserveCnt := IntToStr(Global.ReserveList.GetTeeboxReserveNextListCnt(Index));
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
  Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
  Memo4.Lines.Add('ReserveDate : ' + rTeeboxInfo.TeeboxReserve.ReserveDate);
  Memo4.Lines.Add('PrepareStartDate : ' + rTeeboxInfo.TeeboxReserve.PrepareStartDate);
  Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
  Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
  Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);

  sStr := Global.ReserveList.GetTeeboxReserveNextView(rTeeboxInfo.TeeboxNo);

  Memo4.Lines.Add(sStr);
end;

procedure TMainForm.btnRunAppStartClick(Sender: TObject);
begin
  ShellExecute(FApplicationHandle, 'open', PChar(Global.HomeDir + 'run.vbs'), nil, nil, SW_SHOW);
  Global.Log.LogWrite(Global.HomeDir + 'run.vbs');
end;

procedure TMainForm.btnRunAppEndClick(Sender: TObject);
begin
  ShellExecute(FApplicationHandle, 'open', PChar(Global.HomeDir + 'exit.vbs'), nil, nil, SW_SHOW);
  Global.Log.LogWrite(Global.HomeDir + 'exit.vbs');
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
      Memo4.Lines.Add('ReserveNo : ' + rTeeboxInfo.TeeboxReserve.ReserveNo);
      Memo4.Lines.Add('ReserveStartDate : ' + rTeeboxInfo.TeeboxReserve.ReserveStartDate);
      Memo4.Lines.Add('ReserveEndDate : ' + rTeeboxInfo.TeeboxReserve.ReserveEndDate);
      Memo4.Lines.Add('UseStatus : ' + rTeeboxInfo.UseStatus);
    end;
  end;
end;

procedure TMainForm.btnAgentSelectClick(Sender: TObject);
begin
  Global.XGolfDM.AgentSelectAll;
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

procedure TMainForm.btnPrepareClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9001, "teebox_no": ' + ', "reserve_no":"T00010001", "prepare_min":5}';
end;

procedure TMainForm.btnStartClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9002, "teebox_no": ' + ', "reserve_no":"T00010001", "assign_min":60}';
end;

procedure TMainForm.btnChangeClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9006, "teebox_no": ' + ', "reserve_no":"T00010001", "assign_min":60}';
end;

procedure TMainForm.btnEndClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9003, "teebox_no": ' + ', "reserve_no":"T00010001"}';
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
                  '"user_id":"' + Global.ADConfig.UserId + '",' +     //사용자 Id	user_id
                  '"teebox_no":"' + sSeatNo + '"' +   //타석기 번호	teebox_no
               '}';

  global.tcpserver.SetTeeboxHoldCancel(sSendData);

end;

procedure TMainForm.btnSettingClick(Sender: TObject);
begin
  mmoSendMsg.Text := '{"api_id":9005, "teebox_no": ' + ', "method": }';
end;

procedure TMainForm.btnRefreshIPListClick(Sender: TObject);
begin
  RefreshIPList;
end;

procedure TMainForm.btnRescanIPListClick(Sender: TObject);
begin
  Global.Tapo.RescanIPList;
end;

procedure TMainForm.btnSetDeviceOffClick(Sender: TObject);
var
  nIndex: Integer;
  sIP, sErrMsg: string;
begin
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
  try
    nIndex := lbxDeviceList.ItemIndex;
    if not CheckDeviceIndex(nIndex, sErrMsg) then
      raise Exception.Create(sErrMsg);

    sIP := TDeviceInfo(lbxDeviceList.Items.Objects[nIndex]).IP;
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
