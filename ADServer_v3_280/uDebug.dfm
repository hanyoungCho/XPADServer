object frmDebug: TfrmDebug
  Left = 0
  Top = 0
  Caption = 'Debug COM'
  ClientHeight = 536
  ClientWidth = 356
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel8: TPanel
    Left = 0
    Top = 0
    Width = 356
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitLeft = 1
    ExplicitTop = 1
    ExplicitWidth = 874
    object btnDebugStart: TButton
      Left = 71
      Top = 10
      Width = 82
      Height = 25
      Caption = #49884#51089
      TabOrder = 0
      OnClick = btnDebugStartClick
    end
    object edIndex: TEdit
      Left = 8
      Top = 13
      Width = 57
      Height = 22
      TabOrder = 1
    end
  end
  object mmoDebug: TMemo
    Left = 0
    Top = 41
    Width = 356
    Height = 495
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitLeft = 1
    ExplicitTop = 1
    ExplicitWidth = 872
    ExplicitHeight = 779
  end
  object btnDebugEnd: TButton
    Left = 159
    Top = 10
    Width = 82
    Height = 25
    Caption = #51333#47308
    TabOrder = 2
    OnClick = btnDebugEndClick
  end
end
