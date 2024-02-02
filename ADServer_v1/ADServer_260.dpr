program ADServer_260;

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
  uSeatControlTcp in 'uSeatControlTcp.pas',
  Frame.ItemStyle in 'Frame.ItemStyle.pas' {Frame1: TFrame},
  FILELOG in 'FILELOG.pas',
  uFunction in '..\common\uFunction.pas',
  uXGClientDM in 'uXGClientDM.pas' {XGolfDM: TDataModule},
  uXGServer in 'uXGServer.pas',
  uErpApi in 'uErpApi.pas',
  uHeatControlCom in 'Comport\uHeatControlCom.pas',
  uComZoom in 'Comport\uComZoom.pas',
  uComJeu435 in 'Comport\uComJeu435.pas',
  uComJMS in 'Comport\uComJMS.pas',
  uComJeu60A in 'Comport\uComJeu60A.pas',
  uComJeu50A in 'Comport\uComJeu50A.pas',
  uComModen in 'Comport\uComModen.pas',
  uLogging in 'uLogging.pas',
  uComModenYJ in 'Comport\uComModenYJ.pas',
  uHeatControlTcp in 'uHeatControlTcp.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
