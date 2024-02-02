unit Frame.ItemStyleTop;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uStruct;

type
  TFrame2 = class(TFrame)
    Label1: TLabel;
    Label2: TLabel;
    etMin: TEdit;
    etIP: TEdit;
    etCnt: TEdit;
    etTapoStatus: TEdit;
    etMac: TEdit;
    etAgentStatus: TEdit;
    Label3: TLabel;
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

{ TFrame2 }

procedure TFrame2.DisPlaySeatInfo;
begin
  Label1.Caption := TeeboxInfo.TeeboxNm;
  Label2.Caption := '[' + IntToStr(TeeboxInfo.TeeboxNo) + ']';
  etMin.Text := IntToStr(TeeboxInfo.RemainMinute);
  etCnt.Text := FReserveCnt;
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
    if Global.TapoCtrlLock = True then
    begin
      Self.Color := clBtnFace;
    end
    else
    begin

    if TeeboxInfo.UseStatus = '9' then
      Self.Color := clRed
    else if (TeeboxInfo.UseStatus = '7') or (TeeboxInfo.UseStatus = '8') then
      Self.Color := clSkyBlue
    else if (TeeboxInfo.UseStatus = '6') then
      Self.Color := clGreen
    else if TeeboxInfo.HoldUse = True then
      Self.Color := clGray
    else
      Self.Color := clWhite;
    end;
  end
  else
  begin
    Self.Color := clBtnFace;
  end;

  if TeeboxInfo.ErrorYn = 'Y' then
    etMin.Color := clRed
  else
    etMin.Color := clWindow;

end;

end.
