object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'ADServer_ELOOM'
  ClientHeight = 618
  ClientWidth = 1079
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
    Width = 1079
    Height = 618
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
    ClientRectBottom = 617
    ClientRectLeft = 1
    ClientRectRight = 1078
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
        Left = 0
        Top = 41
        Width = 780
        Height = 551
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
      object Panel3: TPanel
        Left = 0
        Top = 0
        Width = 1077
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        BevelOuter = bvNone
        TabOrder = 1
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
      end
      object Panel4: TPanel
        Left = 780
        Top = 41
        Width = 297
        Height = 551
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
          Width = 266
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
        object edTeeboxNm: TEdit
          Left = 103
          Top = 10
          Width = 34
          Height = 22
          TabOrder = 4
        end
        object btnHoldCancel: TButton
          Left = 17
          Top = 375
          Width = 75
          Height = 25
          Caption = #54848#46300#52712#49548
          TabOrder = 5
          OnClick = btnHoldCancelClick
        end
        object btnRunAppStart: TButton
          Left = 17
          Top = 406
          Width = 75
          Height = 25
          Caption = #49892#54665
          TabOrder = 6
          OnClick = btnRunAppStartClick
        end
        object btnRunAppEnd: TButton
          Left = 98
          Top = 406
          Width = 75
          Height = 25
          Caption = #51333#47308
          TabOrder = 7
          OnClick = btnRunAppEndClick
        end
        object edBeam: TEdit
          Left = 15
          Top = 457
          Width = 114
          Height = 22
          TabOrder = 8
        end
        object cbBeamType: TComboBox
          Left = 135
          Top = 457
          Width = 73
          Height = 22
          ItemIndex = 0
          TabOrder = 9
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
          TabOrder = 10
          Text = 'off'
          Items.Strings = (
            'off'
            'on')
        end
        object btnBeam: TButton
          Left = 183
          Top = 487
          Width = 90
          Height = 25
          Caption = 'Beam'
          TabOrder = 11
          OnClick = btnBeamClick
        end
      end
    end
    object cxTabSheet4: TcxTabSheet
      Caption = 'Tapo/Agent'
      Color = clWhite
      ImageIndex = 1
      ParentColor = False
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object panHeader: TPanel
        Left = 0
        Top = 0
        Width = 1077
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        BevelOuter = bvNone
        TabOrder = 0
        object Label3: TLabel
          AlignWithMargins = True
          Left = 933
          Top = 3
          Width = 124
          Height = 13
          Align = alRight
          Caption = #53364#46972#51060#50616#53944' '#51217#49549' '#49688' : '
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
        end
        object lblConnCount: TLabel
          AlignWithMargins = True
          Left = 1063
          Top = 3
          Width = 7
          Height = 13
          Align = alRight
          Caption = '0'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clMaroon
          Font.Height = -13
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
        end
        object Label4: TLabel
          AlignWithMargins = True
          Left = 79
          Top = 3
          Width = 34
          Height = 13
          Align = alLeft
          Caption = #49345#53468' :'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
          Visible = False
        end
        object lblServerStatus: TLabel
          AlignWithMargins = True
          Left = 119
          Top = 3
          Width = 39
          Height = 13
          Align = alLeft
          Caption = #51473#51648#46120
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clMaroon
          Font.Height = -13
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
          Visible = False
        end
        object Label5: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 70
          Height = 31
          Align = alLeft
          Alignment = taCenter
          AutoSize = False
          Caption = 'SERVER'
          Color = clMaroon
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
      end
      object mmoSendMsg: TMemo
        AlignWithMargins = True
        Left = 0
        Top = 41
        Width = 1077
        Height = 56
        Margins.Left = 0
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 1
        Align = alTop
        TabOrder = 1
      end
      object panToolbar: TPanel
        Left = 0
        Top = 98
        Width = 1077
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        TabOrder = 2
        object btnBroadcast: TButton
          AlignWithMargins = True
          Left = 919
          Top = 4
          Width = 150
          Height = 29
          Align = alRight
          Caption = #47700#49884#51648' '#48652#47196#46300#52880#49828#54021
          TabOrder = 0
          OnClick = btnBroadcastClick
        end
        object btnEnd: TButton
          AlignWithMargins = True
          Left = 229
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
          Left = 304
          Top = 4
          Width = 69
          Height = 29
          Align = alLeft
          Caption = #49483#54021
          TabOrder = 4
          OnClick = btnSettingClick
        end
        object btnChange: TButton
          AlignWithMargins = True
          Left = 154
          Top = 4
          Width = 69
          Height = 29
          Align = alLeft
          Caption = #48320#44221
          TabOrder = 5
          OnClick = btnChangeClick
        end
      end
      object Panel2: TPanel
        Left = 0
        Top = 139
        Width = 1077
        Height = 31
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 3
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
          Width = 846
          Height = 25
          Align = alClient
          ReadOnly = True
          TabOrder = 0
          ExplicitHeight = 22
        end
        object btnDeviceList: TButton
          AlignWithMargins = True
          Left = 956
          Top = 3
          Width = 118
          Height = 25
          Align = alRight
          Caption = 'GetDeviceList'
          TabOrder = 1
          OnClick = btnDeviceListClick
        end
      end
      object lbxIPList: TListBox
        AlignWithMargins = True
        Left = 3
        Top = 204
        Width = 266
        Height = 179
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
        Top = 204
        Width = 799
        Height = 179
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
        Top = 389
        Width = 1071
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
      end
      object Panel5: TPanel
        Left = 0
        Top = 170
        Width = 1077
        Height = 31
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 7
        object btnSetDeviceOff: TButton
          AlignWithMargins = True
          Left = 1018
          Top = 3
          Width = 56
          Height = 25
          Align = alRight
          Caption = 'Off'
          TabOrder = 4
          OnClick = btnSetDeviceOffClick
        end
        object btnSetDeviceOn: TButton
          AlignWithMargins = True
          Left = 956
          Top = 3
          Width = 56
          Height = 25
          Align = alRight
          Caption = 'On'
          TabOrder = 3
          OnClick = btnSetDeviceOnClick
        end
        object btnDeviceInfo: TButton
          AlignWithMargins = True
          Left = 832
          Top = 3
          Width = 118
          Height = 25
          Align = alRight
          Caption = 'DeviceInfo'
          TabOrder = 2
          OnClick = btnDeviceInfoClick
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
      end
    end
    object cxTabSheet2: TcxTabSheet
      Caption = 'Agent '#49444#51221
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Panel7: TPanel
        Left = 0
        Top = 0
        Width = 1077
        Height = 41
        Align = alTop
        BevelKind = bkFlat
        TabOrder = 0
        object btnAgentSelect: TButton
          AlignWithMargins = True
          Left = 15
          Top = 4
          Width = 69
          Height = 29
          Caption = #51312#54924
          TabOrder = 0
          OnClick = btnAgentSelectClick
        end
      end
      object Panel6: TPanel
        Left = 0
        Top = 41
        Width = 1077
        Height = 551
        Align = alClient
        BevelKind = bkFlat
        TabOrder = 1
        object DBGrid1: TDBGrid
          Left = 1
          Top = 1
          Width = 217
          Height = 545
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
          Width = 854
          Height = 545
          Align = alClient
          DataField = 'SETTING'
          DataSource = XGolfDM.UniDataSourceAgent
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 352
    Top = 160
  end
  object IdAntiFreeze1: TIdAntiFreeze
    Active = False
    Left = 306
    Top = 161
  end
end
