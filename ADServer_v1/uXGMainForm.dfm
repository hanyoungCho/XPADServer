object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'ADServer'
  ClientHeight = 876
  ClientWidth = 1134
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pgcConfig: TcxPageControl
    Left = 0
    Top = 0
    Width = 1134
    Height = 876
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
    ClientRectBottom = 875
    ClientRectLeft = 1
    ClientRectRight = 1133
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
        Left = 297
        Top = 0
        Width = 835
        Height = 850
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
        Width = 297
        Height = 850
        Align = alLeft
        BevelInner = bvLowered
        Color = clWindow
        ParentBackground = False
        TabOrder = 1
        object Memo1: TMemo
          Left = 11
          Top = 48
          Width = 273
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
          Left = 224
          Top = 385
          Width = 57
          Height = 22
          TabOrder = 1
        end
        object chkDebug: TCheckBox
          Left = 167
          Top = 389
          Width = 53
          Height = 17
          Caption = 'Debug'
          TabOrder = 2
          OnClick = chkDebugClick
        end
        object pnlSeat: TPanel
          Left = 15
          Top = 16
          Width = 74
          Height = 26
          Caption = 'Seat'
          Color = clBlue
          ParentBackground = False
          TabOrder = 3
        end
        object pnlCom: TPanel
          Left = 95
          Top = 16
          Width = 74
          Height = 26
          Caption = 'Com'
          Color = clGreen
          ParentBackground = False
          TabOrder = 4
        end
        object pnlEmergency: TPanel
          Left = 11
          Top = 385
          Width = 150
          Height = 26
          Caption = #44596#44553#48176#51221#47784#46300
          ParentBackground = False
          TabOrder = 5
          OnClick = pnlEmergencyClick
        end
        object pnlHeat: TPanel
          Left = 207
          Top = 16
          Width = 74
          Height = 26
          Caption = 'Heat'
          Color = clGreen
          ParentBackground = False
          TabOrder = 6
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
        Top = 18
        Width = 16
        Height = 14
        Caption = 'No'
      end
      object Label2: TLabel
        Left = 79
        Top = 18
        Width = 20
        Height = 14
        Caption = 'Nm'
      end
      object Memo4: TMemo
        Left = 15
        Top = 38
        Width = 321
        Height = 331
        TabOrder = 0
      end
      object btnReserveInfo: TButton
        Left = 143
        Top = 7
        Width = 65
        Height = 25
        Caption = #45936#51060#53552' '#54869#51064
        TabOrder = 1
        OnClick = btnReserveInfoClick
      end
      object edTeeboxNo: TEdit
        Left = 39
        Top = 10
        Width = 34
        Height = 22
        TabOrder = 2
      end
      object Button8: TButton
        Left = 210
        Top = 7
        Width = 65
        Height = 25
        Caption = #45936#51060#53552' '#44160#51613
        TabOrder = 3
        OnClick = Button8Click
      end
      object btnHoldCancel: TButton
        Left = 342
        Top = 37
        Width = 75
        Height = 25
        Caption = #54848#46300#52712#49548
        TabOrder = 4
        OnClick = btnHoldCancelClick
      end
      object edTeeboxNm: TEdit
        Left = 103
        Top = 10
        Width = 34
        Height = 22
        TabOrder = 5
      end
      object btnTcpServerRe: TButton
        Left = 17
        Top = 375
        Width = 82
        Height = 25
        Caption = 'TcpServer Re'
        TabOrder = 6
        OnClick = btnTcpServerReClick
      end
    end
    object cxTabSheet2: TcxTabSheet
      Caption = #50868#50689#54872#44221'2'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Panel3: TPanel
        Left = 0
        Top = 0
        Width = 297
        Height = 850
        Align = alLeft
        BevelInner = bvLowered
        Color = clWindow
        ParentBackground = False
        TabOrder = 0
        object Memo5: TMemo
          Left = 11
          Top = 48
          Width = 273
          Height = 180
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 0
        end
        object pnlSeat2: TPanel
          Left = 12
          Top = 16
          Width = 74
          Height = 26
          Caption = 'Seat'
          Color = clBlue
          ParentBackground = False
          TabOrder = 1
        end
        object pnlCom1: TPanel
          Left = 88
          Top = 16
          Width = 50
          Height = 26
          Caption = 'Com'
          Color = clGreen
          ParentBackground = False
          TabOrder = 2
        end
        object Memo6: TMemo
          Left = 11
          Top = 230
          Width = 273
          Height = 180
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 3
        end
        object Edit16: TEdit
          Left = 227
          Top = 787
          Width = 57
          Height = 22
          TabOrder = 4
        end
        object CheckBox4: TCheckBox
          Left = 170
          Top = 791
          Width = 53
          Height = 17
          Caption = 'Debug'
          TabOrder = 5
          OnClick = chkDebugClick
        end
        object Memo7: TMemo
          Left = 11
          Top = 413
          Width = 273
          Height = 180
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 6
        end
        object pnlCom2: TPanel
          Left = 139
          Top = 16
          Width = 50
          Height = 26
          Caption = 'Com'
          Color = clGreen
          ParentBackground = False
          TabOrder = 7
        end
        object pnlCom3: TPanel
          Left = 190
          Top = 16
          Width = 50
          Height = 26
          Caption = 'Com'
          Color = clGreen
          ParentBackground = False
          TabOrder = 8
        end
        object Memo8: TMemo
          Left = 11
          Top = 596
          Width = 273
          Height = 180
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 9
        end
        object pnlCom4: TPanel
          Left = 242
          Top = 16
          Width = 50
          Height = 26
          Caption = 'Com'
          Color = clGreen
          ParentBackground = False
          TabOrder = 10
        end
        object pnlEmergency2: TPanel
          Left = 14
          Top = 782
          Width = 150
          Height = 26
          Caption = #44596#44553#48176#51221#47784#46300
          ParentBackground = False
          TabOrder = 11
        end
      end
      object Panel6: TPanel
        Left = 297
        Top = 0
        Width = 835
        Height = 850
        Align = alClient
        BevelInner = bvLowered
        Color = clWindow
        Font.Charset = HANGEUL_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        TabOrder = 1
      end
    end
  end
  object ComPort1: TComPort
    BaudRate = br9600
    Port = 'COM10'
    Parity.Bits = prOdd
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    StoredProps = [spBasic]
    TriggersOnRxChar = True
    OnRxChar = ComPort1RxChar
    Left = 48
    Top = 88
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 104
    Top = 88
  end
  object IdAntiFreeze1: TIdAntiFreeze
    Active = False
    Left = 154
    Top = 89
  end
end
