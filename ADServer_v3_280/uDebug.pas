unit uDebug;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TfrmDebug = class(TForm)
    Panel8: TPanel;
    btnDebugStart: TButton;
    mmoDebug: TMemo;
    btnDebugEnd: TButton;
    edIndex: TEdit;
    procedure btnDebugStartClick(Sender: TObject);
    procedure btnDebugEndClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Function AddLog(ALog: String): Boolean;
  end;

var
  frmDebug: TfrmDebug;

implementation

uses
  uGlobal;

{$R *.dfm}

procedure TfrmDebug.btnDebugEndClick(Sender: TObject);
begin
  Global.DebugStart := 'N';
  edIndex.Enabled := True;
end;

procedure TfrmDebug.btnDebugStartClick(Sender: TObject);
begin
  Global.DebugIndex := edIndex.Text;
  Global.DebugStart := 'Y';
  edIndex.Enabled := False;
end;

function TfrmDebug.AddLog(ALog: String): Boolean;
begin
  if mmoDebug.Lines.Count > 200 then
    mmoDebug.Lines.Clear;

  mmoDebug.Lines.Add(ALog);
end;

end.
