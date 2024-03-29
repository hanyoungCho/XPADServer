unit Frame.ItemStyle;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uStruct;

type
  TFrame1 = class(TFrame)
    Label1: TLabel;
    edRemin: TEdit;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    edDeviceRemin: TEdit;
  private
    { Private declarations }
    FTeeboxInfo: TTeeboxInfo;
    FHeatStatus: String;
    FReserveCnt: String;
  public
    { Public declarations }
    procedure DisPlaySeatInfo;

    property TeeboxInfo: TTeeboxInfo read FTeeboxInfo write FTeeboxInfo;
    property HeatStatus: String read FHeatStatus write FHeatStatus;
    property ReserveCnt: String read FReserveCnt write FReserveCnt;
  end;

implementation

{$R *.dfm}

uses
  uGlobal;

{ TFrame1 }

procedure TFrame1.DisPlaySeatInfo;
begin
  Label1.Caption := TeeboxInfo.TeeboxNm;
  Label2.Caption := '[' + IntToStr(TeeboxInfo.TeeboxNo) + ']';
  {
  if Global.ADConfig.TimeCheckMode = '1' then
  begin
    edRemin.Text := '-';
    edDeviceRemin.Text := IntToStr(TeeboxInfo.RemainMinute);
  end
  else  }
  begin
    edRemin.Text := IntToStr(TeeboxInfo.RemainMinute);
    edDeviceRemin.Text := IntToStr(TeeboxInfo.DeviceRemainMin);
  end;

  Edit2.Text := IntToStr(TeeboxInfo.RemainBall);
  Edit4.Text := FReserveCnt;

  if TeeboxInfo.UseYn = 'Y' then
  begin
    if TeeboxInfo.UseStatus = '9' then
      Self.Color := clRed
    else if (TeeboxInfo.UseStatus = '7') or (TeeboxInfo.UseStatus = '8') then
      Self.Color := clSkyBlue
    else if (TeeboxInfo.UseStatus = '6') then
      Self.Color := clGreen
    else if (TeeboxInfo.UseStatus = 'M') then
      Self.Color := clOlive
    {
    else if (TeeboxInfo.UseStatus = '0') and (TeeboxInfo.UseLStatus = '1') and (Global.ADConfig.ProtocolType = 'JMS') then
        Self.Color := clTeal
    else if (TeeboxInfo.UseStatus = '0') and (TeeboxInfo.UseLStatus = '1') and (Global.ADConfig.StoreCode = 'A5001') then
        Self.Color := clTeal
    }
    else if (TeeboxInfo.UseStatus = '0') and (TeeboxInfo.DeviceUseStatus = 'D') and (Global.ADConfig.ProtocolType = 'NANO') then
        Self.Color := clTeal
    {
    else if (Global.ADConfig.TimeCheckMode = '1') and (TeeboxInfo.UseStatus = '0') and (TeeboxInfo.DeviceUseStatus = '4') and (Global.ADConfig.ProtocolType = 'NANO') then
        Self.Color := clTeal
    }
    else if TeeboxInfo.HoldUse = True then
      Self.Color := clGray
    else
      Self.Color := clWhite;
  end
  else
  begin
    Self.Color := clBtnFace;
  end;

  if TeeboxInfo.ErrorYn = 'Y' then
    edDeviceRemin.Color := clRed
  else
    edDeviceRemin.Color := clWindow;

  Edit3.Text := '';
  Edit3.Color := clWindow;

  if (Global.ADConfig.StoreCode = 'BB001') and (Global.ADConfig.DeviceType = 0) then //������
  begin
    if HeatStatus = 'N' then
    begin
      Edit3.Text := 'F';
      Edit3.Color := clNavy;
    end;
  end
  else
  begin
    if HeatStatus = '1' then
    begin
      Edit3.Text := 'H';
      Edit3.Color := clRed;
    end;
  end;

end;

end.
