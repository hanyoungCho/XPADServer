program ADConveyor_260;

uses
  FastMM4 in '..\..\FastMM4-master\FastMM4.pas',
  FastMM4Messages in '..\..\FastMM4-master\FastMM4Messages.pas',
  Vcl.Forms,
  System.SysUtils,
  uXGMainForm in 'uXGMainForm.pas' {MainForm},
  uStruct in 'uStruct.pas',
  uGlobal in 'uGlobal.pas',
  uConsts in 'uConsts.pas',
  uLogging in 'uLogging.pas',
  uComConveyor in 'uComConveyor.pas',
  uFunction in '..\common\uFunction.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
