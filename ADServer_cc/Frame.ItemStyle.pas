unit Frame.ItemStyle;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uStruct;

type
  TFrame1 = class(TFrame)
    laNm: TLabel;
    edMin: TEdit;
    edBall: TEdit;
    laNo: TLabel;
    edReserveCnt: TEdit;
    edDeviceMin: TEdit;
  private
    { Private declarations }
    FSeatInfo: TTeeboxInfo;
    FReserveCnt: String;
  public
    { Public declarations }
    procedure DisPlaySeatInfo;

    property SeatInfo: TTeeboxInfo read FSeatInfo write FSeatInfo;
    property ReserveCnt: String read FReserveCnt write FReserveCnt;
  end;

implementation

{$R *.dfm}

uses
  uGlobal;

{ TFrame1 }

procedure TFrame1.DisPlaySeatInfo;
begin
  laNm.Caption := SeatInfo.TeeboxNm;
  laNo.Caption := '[' + IntToStr(SeatInfo.TeeboxNo) + ']';
  edMin.Text := IntToStr(SeatInfo.RemainMinute);
  edDeviceMin.Text := IntToStr(SeatInfo.DeviceRemainMin);
  edBall.Text := IntToStr(SeatInfo.RemainBall);
  edReserveCnt.Text := FReserveCnt;

  if SeatInfo.UseYn = 'Y' then
  begin
    if SeatInfo.UseStatus = '9' then
      Self.Color := clRed
    else if (SeatInfo.UseStatus = '7') or (SeatInfo.UseStatus = '8') then
      Self.Color := clSkyBlue
    else if (SeatInfo.UseStatus = '6') then
      Self.Color := clGreen
    else if SeatInfo.HoldUse = True then
      Self.Color := clGray
    else
      Self.Color := clWhite;
  end
  else
  begin
    Self.Color := clBtnFace;
  end;

  if SeatInfo.ErrorYn = 'Y' then
    edDeviceMin.Color := clRed
  else
    edDeviceMin.Color := clWindow;

end;

end.
