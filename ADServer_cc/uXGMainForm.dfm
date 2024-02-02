object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'XGolf'
  ClientHeight = 476
  ClientWidth = 1180
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pgcConfig: TcxPageControl
    Left = 0
    Top = 0
    Width = 1180
    Height = 476
    Align = alClient
    Font.Charset = HANGEUL_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #45208#45588#44256#46357
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Properties.ActivePage = cxTabSheet1
    Properties.CustomButtons.Buttons = <>
    Properties.ShowFrame = True
    LookAndFeel.Kind = lfUltraFlat
    LookAndFeel.NativeStyle = False
    ClientRectBottom = 475
    ClientRectLeft = 1
    ClientRectRight = 1179
    ClientRectTop = 25
    object cxTabSheet1: TcxTabSheet
      Caption = #50868#50689#54872#44221
      Color = clWhite
      Font.Charset = HANGEUL_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = #45208#45588#44256#46357
      Font.Style = [fsBold]
      ImageIndex = 0
      ParentColor = False
      ParentFont = False
      object Panel1: TPanel
        Left = 260
        Top = 0
        Width = 918
        Height = 450
        Align = alClient
        BevelInner = bvLowered
        Color = clWindow
        Font.Charset = HANGEUL_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #45208#45588#44256#46357
        Font.Style = [fsBold]
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
      end
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 260
        Height = 450
        Align = alLeft
        BevelInner = bvLowered
        Color = clWindow
        ParentBackground = False
        TabOrder = 1
        object Memo1: TMemo
          Left = 11
          Top = 48
          Width = 240
          Height = 331
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = [fsBold]
          ParentFont = False
          ReadOnly = True
          TabOrder = 0
        end
        object edApiResult: TEdit
          Left = 194
          Top = 385
          Width = 57
          Height = 22
          TabOrder = 1
        end
        object pnlSeat: TPanel
          Left = 15
          Top = 16
          Width = 74
          Height = 26
          Caption = 'Seat'
          Color = clBlue
          ParentBackground = False
          TabOrder = 2
        end
        object pnlCom: TPanel
          Left = 95
          Top = 16
          Width = 74
          Height = 26
          Caption = 'Com'
          Color = clGreen
          ParentBackground = False
          TabOrder = 3
        end
      end
    end
    object cxTabSheet4: TcxTabSheet
      Caption = #47196#44536
      Color = clWhite
      ImageIndex = 1
      ParentColor = False
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label1: TLabel
        Left = 17
        Top = 26
        Width = 16
        Height = 14
        Caption = 'No'
      end
      object Label2: TLabel
        Left = 79
        Top = 26
        Width = 20
        Height = 14
        Caption = 'Nm'
      end
      object Memo4: TMemo
        Left = 15
        Top = 46
        Width = 270
        Height = 331
        TabOrder = 0
      end
      object btnReserveInfo: TButton
        Left = 143
        Top = 15
        Width = 65
        Height = 25
        Caption = #45936#51060#53552' '#54869#51064
        TabOrder = 1
        OnClick = btnReserveInfoClick
      end
      object edTeeboxNo: TEdit
        Left = 39
        Top = 18
        Width = 34
        Height = 22
        TabOrder = 2
      end
      object btnHoldCancel: TButton
        Left = 214
        Top = 15
        Width = 75
        Height = 25
        Caption = #54848#46300#52712#49548
        TabOrder = 3
        OnClick = btnHoldCancelClick
      end
      object edTeeboxNm: TEdit
        Left = 103
        Top = 18
        Width = 34
        Height = 22
        TabOrder = 4
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 72
    Top = 96
  end
end
