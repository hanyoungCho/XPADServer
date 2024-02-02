object MainForm: TMainForm
  Left = 0
  Top = 0
  ClientHeight = 591
  ClientWidth = 1084
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object pgcConfig: TcxPageControl
    Left = 0
    Top = 0
    Width = 1084
    Height = 591
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
    ExplicitWidth = 1080
    ExplicitHeight = 590
    ClientRectBottom = 590
    ClientRectLeft = 1
    ClientRectRight = 1083
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
      ExplicitWidth = 1078
      ExplicitHeight = 564
      object Panel1: TPanel
        Left = 0
        Top = 41
        Width = 779
        Height = 524
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
        TabOrder = 0
        ExplicitWidth = 775
        ExplicitHeight = 523
        object Label4: TLabel
          Left = 5
          Top = 7
          Width = 364
          Height = 13
          AutoSize = False
          Caption = 
            '   '#47749'  | ID | '#48516' | R |  T  |  A  |            Mac          |      ' +
            '     IP'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
        object Label5: TLabel
          Left = 395
          Top = 7
          Width = 364
          Height = 13
          AutoSize = False
          Caption = 
            '   '#47749'  | ID | '#48516' | R |  T  |  A  |            Mac          |      ' +
            '     IP'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
        object laWOL: TLabel
          Left = 13
          Top = 457
          Width = 754
          Height = 45
          AutoSize = False
          Caption = '0000-00-00 '#55092#51109'. Wake On Lan '#48120#51089#46041
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -33
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnCheckWOL: TButton
          Left = 657
          Top = 457
          Width = 102
          Height = 48
          Caption = 'WOL'#54644#51228
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          OnClick = btnCheckWOLClick
        end
      end
      object Panel5: TPanel
        Left = 0
        Top = 0
        Width = 1082
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitWidth = 1078
        object laTeebox: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 70
          Height = 31
          Align = alLeft
          Alignment = taCenter
          AutoSize = False
          Caption = 'TEEBOX'
          Color = clBlue
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = #44404#47548
          Font.Style = [fsBold]
          ParentColor = False
          ParentFont = False
          Transparent = False
          Layout = tlCenter
          ExplicitTop = 2
        end
        object Label3: TLabel
          Left = 310
          Top = 14
          Width = 299
          Height = 14
          Caption = ' '#53440#49437#47749' / ID / '#51092#50668#49884#44036' / '#50696#50557#49688' / Tapo / Agent / Mac / IP'
        end
        object edApiResult: TEdit
          Left = 79
          Top = 11
          Width = 57
          Height = 22
          TabOrder = 0
        end
        object pnlEmergency: TPanel
          Left = 142
          Top = 7
          Width = 150
          Height = 26
          Caption = #44596#44553#48176#51221#47784#46300
          ParentBackground = False
          TabOrder = 1
        end
      end
      object Panel2: TPanel
        Left = 779
        Top = 41
        Width = 303
        Height = 524
        Align = alRight
        BevelInner = bvLowered
        Color = clWindow
        Font.Charset = HANGEUL_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = #45208#45588#44256#46357
        Font.Style = [fsBold]
        ParentBackground = False
        ParentFont = False
        TabOrder = 2
        ExplicitLeft = 775
        ExplicitHeight = 523
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
          Width = 270
          Height = 291
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
          Left = 17
          Top = 335
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
        object btnCtrlLock: TButton
          Left = 98
          Top = 335
          Width = 75
          Height = 25
          Caption = #51228#50612#51104#44552
          TabOrder = 6
          OnClick = btnCtrlLockClick
        end
        object btnRunAppEnd: TButton
          Left = 226
          Top = 335
          Width = 47
          Height = 25
          Caption = #51333#47308
          TabOrder = 7
          OnClick = btnRunAppEndClick
        end
        object btnRunAppStart: TButton
          Left = 179
          Top = 335
          Width = 46
          Height = 25
          Caption = #49892#54665
          TabOrder = 8
          OnClick = btnRunAppStartClick
        end
        object btnWOL: TButton
          Left = 183
          Top = 420
          Width = 90
          Height = 25
          Caption = 'Wake On Lan'
          TabOrder = 9
          OnClick = btnWOLClick
        end
        object edWOL: TEdit
          Left = 15
          Top = 421
          Width = 162
          Height = 22
          TabOrder = 10
        end
        object edBeam: TEdit
          Left = 15
          Top = 457
          Width = 114
          Height = 22
          TabOrder = 11
        end
        object btnBeam: TButton
          Left = 183
          Top = 487
          Width = 90
          Height = 25
          Caption = 'Beam'
          TabOrder = 12
          OnClick = btnBeamClick
        end
        object cbBeamType: TComboBox
          Left = 135
          Top = 457
          Width = 73
          Height = 22
          ItemIndex = 0
          TabOrder = 13
          Text = 'PJLink'
          Items.Strings = (
            'PJLink'
            'Hitachi')
        end
        object cbBeamOnOff: TComboBox
          Left = 214
          Top = 457
          Width = 59
          Height = 22
          ItemIndex = 0
          TabOrder = 14
          Text = 'off'
          Items.Strings = (
            'off'
            'on')
        end
      end
    end
    object cxTabSheet2: TcxTabSheet
      Caption = 'TAPO/Agent'
      ImageIndex = 2
      object mmoSendMsg: TMemo
        AlignWithMargins = True
        Left = 0
        Top = 0
        Width = 1082
        Height = 40
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 1
        Align = alTop
        TabOrder = 0
        ExplicitWidth = 1078
      end
      object panToolbar: TPanel
        Left = 0
        Top = 41
        Width = 1082
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        TabOrder = 1
        ExplicitWidth = 1078
        object btnBroadcast: TButton
          AlignWithMargins = True
          Left = 924
          Top = 4
          Width = 150
          Height = 29
          Align = alRight
          Caption = #47700#49884#51648' '#48652#47196#46300#52880#49828#54021
          TabOrder = 0
          OnClick = btnBroadcastClick
          ExplicitLeft = 920
        end
        object btnEnd: TButton
          AlignWithMargins = True
          Left = 154
          Top = 4
          Width = 69
          Height = 29
          Align = alLeft
          Caption = #51333#47308
          TabOrder = 1
          OnClick = btnEndClick
        end
        object btnStart: TButton
          AlignWithMargins = True
          Left = 79
          Top = 4
          Width = 69
          Height = 29
          Align = alLeft
          Caption = #49884#51089
          TabOrder = 2
          OnClick = btnStartClick
        end
        object btnPrepare: TButton
          AlignWithMargins = True
          Left = 4
          Top = 4
          Width = 69
          Height = 29
          Align = alLeft
          Caption = #51456#48708
          TabOrder = 3
          OnClick = btnPrepareClick
        end
        object btnSetting: TButton
          AlignWithMargins = True
          Left = 229
          Top = 4
          Width = 69
          Height = 29
          Align = alLeft
          Caption = #49483#54021
          TabOrder = 4
          OnClick = btnSettingClick
        end
      end
      object Panel3: TPanel
        Left = 0
        Top = 82
        Width = 1082
        Height = 31
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 2
        ExplicitWidth = 1078
        object Label6: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 95
          Height = 25
          Align = alLeft
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Terminal UUID'
          Layout = tlCenter
          ExplicitHeight = 28
        end
        object edtTerminalUUID: TEdit
          AlignWithMargins = True
          Left = 104
          Top = 3
          Width = 851
          Height = 25
          Align = alClient
          ReadOnly = True
          TabOrder = 0
          ExplicitWidth = 847
          ExplicitHeight = 22
        end
        object btnDeviceList: TButton
          AlignWithMargins = True
          Left = 961
          Top = 3
          Width = 118
          Height = 25
          Align = alRight
          Caption = 'GetDeviceList'
          TabOrder = 1
          OnClick = btnDeviceListClick
          ExplicitLeft = 957
        end
      end
      object Panel4: TPanel
        Left = 0
        Top = 113
        Width = 1082
        Height = 31
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 3
        ExplicitWidth = 1078
        object btnSetDeviceOff: TButton
          AlignWithMargins = True
          Left = 1023
          Top = 3
          Width = 56
          Height = 25
          Align = alRight
          Caption = 'Off'
          TabOrder = 4
          OnClick = btnSetDeviceOffClick
          ExplicitLeft = 1019
        end
        object btnSetDeviceOn: TButton
          AlignWithMargins = True
          Left = 961
          Top = 3
          Width = 56
          Height = 25
          Align = alRight
          Caption = 'On'
          TabOrder = 3
          OnClick = btnSetDeviceOnClick
          ExplicitLeft = 957
        end
        object btnDeviceInfo: TButton
          AlignWithMargins = True
          Left = 837
          Top = 3
          Width = 118
          Height = 25
          Align = alRight
          Caption = 'DeviceInfo'
          TabOrder = 2
          OnClick = btnDeviceInfoClick
          ExplicitLeft = 833
        end
        object btnRescanIPList: TButton
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 118
          Height = 25
          Align = alLeft
          Caption = 'Rescan IP List'
          TabOrder = 0
          OnClick = btnRescanIPListClick
        end
        object btnRefreshIPList: TButton
          AlignWithMargins = True
          Left = 127
          Top = 3
          Width = 118
          Height = 25
          Align = alLeft
          Caption = 'Refresh IP List'
          TabOrder = 1
          OnClick = btnRefreshIPListClick
        end
        object Edit1: TEdit
          Left = 672
          Top = 3
          Width = 153
          Height = 22
          TabOrder = 5
          Text = '192.168.0.'
        end
      end
      object lbxIPList: TListBox
        AlignWithMargins = True
        Left = 3
        Top = 147
        Width = 266
        Height = 209
        Align = alLeft
        Font.Charset = HANGEUL_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = #44404#47548#52404
        Font.Style = []
        ItemHeight = 13
        ParentFont = False
        TabOrder = 4
      end
      object lbxDeviceList: TListBox
        AlignWithMargins = True
        Left = 275
        Top = 147
        Width = 804
        Height = 209
        Style = lbOwnerDrawFixed
        Align = alClient
        Font.Charset = HANGEUL_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = #44404#47548#52404
        Font.Style = []
        ItemHeight = 13
        ParentFont = False
        TabOrder = 5
        OnDblClick = lbxDeviceListDblClick
        OnDrawItem = lbxDeviceListDrawItem
      end
      object mmoLog: TMemo
        AlignWithMargins = True
        Left = 3
        Top = 362
        Width = 1076
        Height = 200
        Align = alBottom
        Color = clBlack
        Font.Charset = HANGEUL_CHARSET
        Font.Color = clLime
        Font.Height = -13
        Font.Name = #44404#47548#52404
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 6
        WordWrap = False
        ExplicitTop = 361
        ExplicitWidth = 1072
      end
    end
    object cxTabSheet3: TcxTabSheet
      Caption = 'Agent '#49444#51221
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Panel6: TPanel
        Left = 0
        Top = 41
        Width = 1082
        Height = 524
        Align = alClient
        BevelKind = bkFlat
        TabOrder = 0
        object DBGrid1: TDBGrid
          Left = 1
          Top = 1
          Width = 217
          Height = 518
          Align = alLeft
          DataSource = XGolfDM.UniDataSourceAgent
          Options = [dgEditing, dgAlwaysShowEditor, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
          TabOrder = 0
          TitleFont.Charset = HANGEUL_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = #45208#45588#44256#46357
          TitleFont.Style = [fsBold]
          Columns = <
            item
              Expanded = False
              FieldName = 'STORE_CD'
              Title.Caption = #44032#47609#51216
              Width = 54
              Visible = True
            end
            item
              Expanded = False
              FieldName = 'TEEBOX_NO'
              Title.Caption = #53440#49437#48264#54840
              Width = 54
              Visible = True
            end
            item
              Expanded = False
              FieldName = 'LEFT_HANDED'
              Title.Caption = #51340#50864#50668#48512
              Width = 52
              Visible = True
            end>
        end
        object DBMemo1: TDBMemo
          Left = 218
          Top = 1
          Width = 859
          Height = 518
          Align = alClient
          DataField = 'SETTING'
          DataSource = XGolfDM.UniDataSourceAgent
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
      object Panel7: TPanel
        Left = 0
        Top = 0
        Width = 1082
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        TabOrder = 1
        object btnAgentSelect: TButton
          AlignWithMargins = True
          Left = 17
          Top = 4
          Width = 69
          Height = 29
          Caption = #51312#54924
          TabOrder = 0
          OnClick = btnAgentSelectClick
        end
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 552
    Top = 24
  end
  object IdAntiFreeze1: TIdAntiFreeze
    Active = False
    Left = 618
    Top = 25
  end
end
