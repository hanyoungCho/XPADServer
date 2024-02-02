unit uXGMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Types,
  System.Classes, Vcl.Graphics, SvcMgr,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdContext, Vcl.StdCtrls, Uni,
  uStruct, Vcl.ExtCtrls, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxContainer,
  cxPC, IdTCPConnection, IdTCPClient, AdvShapeButton, cxLookAndFeels,
  cxLookAndFeelPainters;

type
  TMainForm = class(TForm)
    pgcConfig: TcxPageControl;
    cxTabSheet1: TcxTabSheet;
    Panel2: TPanel;
    Memo1: TMemo;
    pnlCom: TPanel;
    Memo2: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure pnlComClick(Sender: TObject);
  private
    { Private declarations }
    FSeatChk: TDateTime;
    FComChk: String;

    procedure StartUp;
  public
    { Public declarations }
    procedure LogView(ALog: string);
    procedure LogViewA(ALog: string);
    procedure ErrorView;
  end;

var
  MainForm: TMainForm;

implementation

uses
  uGlobal, uConsts, uFunction;

{$R *.dfm}

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //Application.Minimize;
  //Action := caNone;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  StartUp;
  //Timer1.Enabled := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  //Timer1.Enabled := False;
  Global.Free;
end;

procedure TMainForm.StartUp;
begin
  Global := TGlobal.Create;
  Global.StartUp;
end;

procedure TMainForm.LogView(ALog: string);
var
  sLog: String;
begin

  if Memo1.Lines.Count > 100 then
    Memo1.Lines.Clear;

  //Memo1.Lines.Add(FormatDateTime('hh:nn:ss ▶ ', now) + ALog);
  Memo1.Lines.Add(ALog);

  if FComChk <> ALog then
  begin
    if pnlCom.Color = clBtnFace then
      pnlCom.Color := clGreen
    else
      pnlCom.Color := clBtnFace;

    FComChk := ALog;
  end;

  if Memo1.color = clRed then
  begin
    Memo1.color := clwindow;
    sLog := '컨베이어 통신이상 해제';
    LogViewA(sLog);
  end;

end;

procedure TMainForm.LogViewA(ALog: string);
begin
  if Memo2.Lines.Count > 100 then
    Memo2.Lines.Clear;

  Memo2.Lines.Add(FormatDateTime('hh:nn:ss ▶ ', now) + ALog);
  Global.Log.LogWrite('LogViewA : ' + ALog);
end;

procedure TMainForm.pnlComClick(Sender: TObject);
var
sbin: string;
begin
sBin := DecToBinStr(12);
    sBin := StrZeroAdd(sBin, 4);


  //FCtrlBufferTemp := sLog;
  MainForm.LogView(sBin);
end;

procedure TMainForm.ErrorView;
begin
  Memo1.color := clRed;
end;

end.
