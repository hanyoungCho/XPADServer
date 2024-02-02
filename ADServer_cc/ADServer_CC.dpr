program ADServer_CC;

uses
  FastMM4 in '..\..\..\FastMM4-master\FastMM4.pas',
  FastMM4Messages in '..\..\..\FastMM4-master\FastMM4Messages.pas',
  Vcl.Forms,
  System.SysUtils,
  uXGMainForm in 'uXGMainForm.pas' {MainForm},
  uStruct in 'uStruct.pas',
  uGlobal in 'uGlobal.pas',
  uTeeboxInfo in 'uTeeboxInfo.pas',
  uTeeboxThread in 'uTeeboxThread.pas',
  uConsts in 'uConsts.pas',
  Frame.ItemStyle in 'Frame.ItemStyle.pas' {Frame1: TFrame},
  uFunction in '..\common\uFunction.pas',
  uXGClientDM in 'uXGClientDM.pas' {XGolfDM: TDataModule},
  uXGServer in 'uXGServer.pas',
  uErpApi in 'uErpApi.pas',
  uComZoomCC in 'uComZoomCC.pas',
  uLogging in 'uLogging.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
