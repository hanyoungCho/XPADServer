unit Frame.ItemStyle;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uStruct;

type
  TFrame1 = class(TFrame)
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    Edit4: TEdit;
    etTapoStatus: TEdit;
    etMac: TEdit;
    etIP: TEdit;
    etAgentStatus: TEdit;
  private
    { Private declarations }
    FTeeboxInfo: TTeeboxInfo;
    FReserveCnt: String;
  public
    { Public declarations }
    procedure DisPlaySeatInfo;

    property TeeboxInfo: TTeeboxInfo read FTeeboxInfo write FTeeboxInfo;
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
  Edit1.Text := IntToStr(TeeboxInfo.RemainMinute);
  Edit4.Text := FReserveCnt;
  etTapoStatus.Text := TeeboxInfo.TapoOnOff;
  if (Trim(etTapoStatus.Text) = EmptyStr) or (TeeboxInfo.TapoError = True) then
    etTapoStatus.Color := clRed
  else
    etTapoStatus.Color := clWindow;

  if TeeboxInfo.AgentCtlYN = '1' then
  begin
    etAgentStatus.Text := 'on';
    etAgentStatus.Color := clWindow;
  end
  else
  begin
    etAgentStatus.Text := 'off';
    etAgentStatus.Color := clRed;
  end;

  etMac.Text := TeeboxInfo.TapoMac;
  etIP.Text := TeeboxInfo.TapoIP;

  if TeeboxInfo.UseYn = 'Y' then
  begin
    if TeeboxInfo.UseStatus = '9' then
      Self.Color := clRed
    else if TeeboxInfo.UseStatus = '8' then
      Self.Color := clSkyBlue
    else if (TeeboxInfo.UseStatus = '6') then
      Self.Color := clGreen
    else if TeeboxInfo.HoldUse = True then
      Self.Color := clGray
    else
      Self.Color := clWhite;
  end
  else
  begin
    Self.Color := clBtnFace;
  end;

end;

end.
