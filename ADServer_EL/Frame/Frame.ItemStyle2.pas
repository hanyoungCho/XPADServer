unit Frame.ItemStyle2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uStruct;

type
  TFrame2 = class(TFrame)
    Label1: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
  private
    { Private declarations }
    FSeatInfo: TSeatInfo;
    FHeatStatus: String;
    FReserveCnt: String;
  public
    { Public declarations }
    procedure DisPlaySeatInfo;

    property SeatInfo: TSeatInfo read FSeatInfo write FSeatInfo;
    property HeatStatus: String read FHeatStatus write FHeatStatus;
    property ReserveCnt: String read FReserveCnt write FReserveCnt;
  end;

implementation

{$R *.dfm}

uses
  uGlobal;

{ TFrame1 }

procedure TFrame2.DisPlaySeatInfo;
begin
  Label1.Caption := SeatInfo.SeatNm;
  Label2.Caption := '[' + IntToStr(SeatInfo.SeatNo) + ']';
  Edit1.Text := IntToStr(SeatInfo.RemainMinute);
  Edit2.Text := IntToStr(SeatInfo.RemainBall);
  Edit4.Text := FReserveCnt;

  if SeatInfo.UseYn = 'Y' then
  begin
    if SeatInfo.UseStatus = '9' then
      Self.Color := clRed
    else if (SeatInfo.UseStatus = '7') or (SeatInfo.UseApiStatus = '8') then
      Self.Color := clSkyBlue
    else if (SeatInfo.UseStatus = '6') then
      Self.Color := clGreen
    else if (SeatInfo.UseStatus = '0') and (SeatInfo.UseLStatus = '1') and (Global.ADConfig.ProtocolType = 'JMS') then
        Self.Color := clTeal
    else if (SeatInfo.UseStatus = '0') and (SeatInfo.UseLStatus = '1') and (Global.ADConfig.StoreCode = 'A5001') then
        Self.Color := clTeal
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
    Edit1.Color := clRed
  else
    Edit1.Color := clWindow;

  if HeatStatus = '1' then
  begin
    Edit3.Text := 'H';
    Edit3.Color := clRed;
  end
  else
  begin
    Edit3.Text := '';
    Edit3.Color := clWindow;
  end;
end;

end.
