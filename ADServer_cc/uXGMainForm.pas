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
  Frame.ItemStyle, IdHTTP, CPortCtl, uXGClientDM;

type
  TMainForm = class(TForm)
    pgcConfig: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    cxTabSheet4: TcxTabSheet;
    Timer1: TTimer;
    Panel1: TPanel;
    Memo4: TMemo;
    btnReserveInfo: TButton;
    edTeeboxNo: TEdit;
    Panel2: TPanel;
    Memo1: TMemo;
    edApiResult: TEdit;
    pnlSeat: TPanel;
    pnlCom: TPanel;
    btnHoldCancel: TButton;
    edTeeboxNm: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnReserveInfoClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnHoldCancelClick(Sender: TObject);
  private
    { Private declarations }
    FItemList: TList<TFrame1>;

    FSeatChk: TDateTime;
    FComChk: String;

    FComChk1: String;
    FComChk2: String;
    FComChk3: String;

    procedure StartUp;
    procedure DisplayInit;
    procedure DisplayStatus;
  public
    { Public declarations }
    procedure LogView(ALog: string);

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
  //Application.Minimize;
  //Action := caNone;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  StartUp;
  DisplayInit;
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
  pgcConfig.ActivePageIndex := 0;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  DisplayStatus;

  MainForm.LogView(global.CtrlBufferTemp);
end;

procedure TMainForm.LogView(ALog: string);
begin

  if Memo1.Lines.Count > 100 then
    Memo1.Lines.Clear;

  Memo1.Lines.Add(ALog);

  if FComChk <> ALog then
  begin
    if pnlCom.Color = clBtnFace then
      pnlCom.Color := clGreen
    else
      pnlCom.Color := clBtnFace;

    FComChk := ALog;
  end;

  if FSeatChk <> Global.SeatThreadTime then
  begin
    if pnlSeat.Color = clBtnFace then
      pnlSeat.Color := clBlue
    else
      pnlSeat.Color := clBtnFace;

    FSeatChk := Global.SeatThreadTime;
  end;
end;

procedure TMainForm.DisplayInit;
var
  Index, ColIndex, RowIndex: Integer;
  AItemStyle: TFrame1;
  SeatInfo: TTeeboxInfo;
begin
  try
    if FItemList = nil then
      FItemList := TList<TFrame1>.Create;

    if FItemList.Count <> 0 then
      FItemList.Clear;

    RowIndex := 0;
    ColIndex := 0;

    for Index := 1 to Global.Teebox.TeeboxLastNo do
    begin
      SeatInfo := Global.Teebox.GetTeeboxInfo(Index);

      if ColIndex = 5 then
      begin
        Inc(RowIndex);
        ColIndex := 0;
      end;

      AItemStyle := TFrame1.Create(nil);
      AItemStyle.Left := ColIndex * AItemStyle.Width;
      AItemStyle.Top := RowIndex * AItemStyle.Height;
      AItemStyle.Parent := Panel1;
      AItemStyle.SeatInfo := SeatInfo;
      AItemStyle.DisPlaySeatInfo;

      ItemList.Add(AItemStyle);
      Inc(ColIndex);

      if Index = Global.Teebox.TeeboxLastNo then
      begin
        Height := AItemStyle.Top + AItemStyle.Height + 36 + 25 + 5; //516 477 25
        if Height < 516 then
          Height := 516;

        Width := 1160;
      end;

    end;
  finally

  end;
end;

procedure TMainForm.DisplayStatus;
var
  Index: Integer;
  SeatInfo: TTeeboxInfo;
begin
  try
    if FItemList.Count = 0 then
      Exit;

    for Index := 1 to Global.Teebox.TeeboxLastNo do
    begin
      SeatInfo := Global.Teebox.GetTeeboxInfo(Index);
      FItemList[Index - 1].SeatInfo := SeatInfo;
      FItemList[Index - 1].ReserveCnt := Global.Teebox.GetReserveNextListCnt(Index);
      FItemList[Index - 1].DisPlaySeatInfo;
    end;
  finally

  end;
end;

procedure TMainForm.btnReserveInfoClick(Sender: TObject);
var
  SeatInfo: TTeeboxInfo;
  nSeatNo: Integer;
  sStr: String;
begin
  if Trim(edTeeboxNo.text) <> '' then
  begin
    nSeatNo := StrToInt(edTeeboxNo.text);
    SeatInfo := Global.Teebox.GetTeeboxInfo(nSeatNo);
  end
  else if Trim(edTeeboxNm.text) <> '' then
  begin
    SeatInfo := Global.Teebox.GetNmToTeeboxInfo(edTeeboxNm.text);
  end;

  Memo4.Lines.Clear;
  Memo4.Lines.Add('TeeboxNo : ' + IntToStr(SeatInfo.TeeboxNo) + ' [ ' + 'TeeboxNm : ' + SeatInfo.TeeboxNm + ' ] ');
  Memo4.Lines.Add('RemainMinute : ' + IntToStr(SeatInfo.RemainMinute));
  Memo4.Lines.Add('RemainBall : ' + IntToStr(SeatInfo.RemainBall));
  Memo4.Lines.Add('ReserveNo : ' + SeatInfo.Reserve.ReserveNo);
  Memo4.Lines.Add('ReserveDate : ' + SeatInfo.Reserve.ReserveDate);
  Memo4.Lines.Add('PrepareStartDate : ' + SeatInfo.Reserve.PrepareStartDate);
  Memo4.Lines.Add('ReserveStartDate : ' + SeatInfo.Reserve.ReserveStartDate);
  Memo4.Lines.Add('ReserveEndDate : ' + SeatInfo.Reserve.ReserveEndDate);
  Memo4.Lines.Add('UseStatus : ' + SeatInfo.UseStatus);

  sStr := Global.Teebox.GetReserveNextView(SeatInfo.TeeboxNo);

  Memo4.Lines.Add(sStr);
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

  global.tcpserver.SetSeatHoldCancel(sSendData);
end;

end.
