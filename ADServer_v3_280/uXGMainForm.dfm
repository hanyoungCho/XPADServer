object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'ADServer_test'
  ClientHeight = 850
  ClientWidth = 1234
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
    Width = 1234
    Height = 850
    Align = alClient
    Font.Charset = HANGEUL_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #45208#45588#44256#46357
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Properties.ActivePage = cxTabSheet3
    Properties.CustomButtons.Buttons = <>
    Properties.ShowFrame = True
    LookAndFeel.Kind = lfUltraFlat
    LookAndFeel.NativeStyle = False
    ExplicitWidth = 1230
    ExplicitHeight = 849
    ClientRectBottom = 849
    ClientRectLeft = 1
    ClientRectRight = 1233
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
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 1228
      ExplicitHeight = 823
      object pnlSingle: TPanel
        Left = 297
        Top = 0
        Width = 935
        Height = 824
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
        ExplicitWidth = 931
        ExplicitHeight = 823
        object Label3: TLabel
          Left = 6
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '    '#53440#49437#47749' | '#48516' |'#51109#52824'| '#48380'  |H|R'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
        end
        object Label4: TLabel
          Left = 180
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '     '#53440#49437#47749' | '#48516' |'#51109#52824'| '#48380'  |H|R'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
        end
        object Label5: TLabel
          Left = 360
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '     '#53440#49437#47749' | '#48516' |'#51109#52824'| '#48380'  |H|R'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
        end
        object Label6: TLabel
          Left = 540
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '     '#53440#49437#47749' | '#48516' |'#51109#52824'| '#48380'  |H|R'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
        end
        object Label7: TLabel
          Left = 720
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '     '#53440#49437#47749' | '#48516' |'#51109#52824'| '#48380'  |H|R'
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
        end
      end
      object Panel2: TPanel
        Left = 0
        Top = 0
        Width = 297
        Height = 824
        Align = alLeft
        BevelInner = bvLowered
        Color = clWindow
        ParentBackground = False
        TabOrder = 1
        ExplicitHeight = 823
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
        object pnlEmergency: TPanel
          Left = 11
          Top = 385
          Width = 150
          Height = 26
          Caption = #44596#44553#48176#51221#47784#46300
          ParentBackground = False
          TabOrder = 4
        end
        object pnlPLC: TPanel
          Left = 175
          Top = 16
          Width = 74
          Height = 26
          Caption = 'PLC'
          Color = clGreen
          ParentBackground = False
          TabOrder = 5
        end
        object btnDebug: TButton
          Left = 167
          Top = 385
          Width = 51
          Height = 25
          Caption = 'Debug'
          TabOrder = 6
          OnClick = btnDebugMultiClick
        end
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
        Height = 824
        Align = alLeft
        BevelInner = bvLowered
        Color = clWindow
        ParentBackground = False
        TabOrder = 0
        object Memo5: TMemo
          Left = 9
          Top = 48
          Width = 280
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
          Left = 7
          Top = 16
          Width = 50
          Height = 26
          Caption = 'Seat'
          Color = clBlue
          ParentBackground = False
          TabOrder = 1
        end
        object pnlCom1: TPanel
          Left = 60
          Top = 16
          Width = 30
          Height = 26
          Caption = 'Com'
          Color = clGray
          ParentBackground = False
          TabOrder = 2
        end
        object Memo6: TMemo
          Left = 9
          Top = 230
          Width = 280
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
          Top = 786
          Width = 57
          Height = 22
          TabOrder = 4
        end
        object Memo7: TMemo
          Left = 9
          Top = 413
          Width = 280
          Height = 180
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 5
        end
        object pnlCom2: TPanel
          Left = 90
          Top = 16
          Width = 30
          Height = 26
          Caption = 'Com'
          Color = clGray
          ParentBackground = False
          TabOrder = 6
        end
        object pnlCom3: TPanel
          Left = 121
          Top = 16
          Width = 30
          Height = 26
          Caption = 'Com'
          Color = clGray
          ParentBackground = False
          TabOrder = 7
        end
        object Memo8: TMemo
          Left = 9
          Top = 596
          Width = 280
          Height = 180
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #44404#47548
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          TabOrder = 8
        end
        object pnlCom4: TPanel
          Left = 152
          Top = 16
          Width = 30
          Height = 26
          Caption = 'Com'
          Color = clGray
          ParentBackground = False
          TabOrder = 9
        end
        object pnlEmergency2: TPanel
          Left = 14
          Top = 782
          Width = 150
          Height = 26
          Caption = #44596#44553#48176#51221#47784#46300
          ParentBackground = False
          TabOrder = 10
        end
        object btnDebugMulti: TButton
          Left = 170
          Top = 783
          Width = 51
          Height = 25
          Caption = 'Debug'
          TabOrder = 11
          OnClick = btnDebugMultiClick
        end
        object pnlHeat: TPanel
          Left = 247
          Top = 16
          Width = 40
          Height = 26
          Caption = 'Heat'
          Color = clGreen
          ParentBackground = False
          TabOrder = 12
        end
        object pnlCom6: TPanel
          Left = 216
          Top = 16
          Width = 30
          Height = 26
          Caption = 'Com'
          Color = clGray
          ParentBackground = False
          TabOrder = 13
        end
        object pnlCom5: TPanel
          Left = 184
          Top = 16
          Width = 30
          Height = 26
          Caption = 'Com'
          Color = clGray
          ParentBackground = False
          TabOrder = 14
        end
        object pnlDome: TPanel
          Left = 9
          Top = 599
          Width = 282
          Height = 162
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 15
          Visible = False
          object rgDeviceType: TRadioGroup
            Left = 5
            Top = 16
            Width = 268
            Height = 49
            Caption = #51228#50612#54637#47785
            Columns = 2
            ItemIndex = 0
            Items.Strings = (
              #49440#54413#44592
              #55176#53552)
            TabOrder = 0
            OnClick = rgDeviceTypeClick
          end
          object Panel6: TPanel
            Left = 5
            Top = 71
            Width = 43
            Height = 26
            Caption = #44032#46041
            ParentBackground = False
            TabOrder = 1
          end
          object edtHeatOnTime: TEdit
            Left = 51
            Top = 73
            Width = 57
            Height = 22
            MaxLength = 5
            NumbersOnly = True
            TabOrder = 2
          end
          object Panel9: TPanel
            Left = 116
            Top = 71
            Width = 43
            Height = 26
            Caption = #51221#51648
            ParentBackground = False
            TabOrder = 3
          end
          object edtHeatOffTime: TEdit
            Left = 162
            Top = 73
            Width = 57
            Height = 22
            MaxLength = 5
            NumbersOnly = True
            TabOrder = 4
          end
          object btnHeatOnOffTime: TButton
            Left = 223
            Top = 71
            Width = 51
            Height = 25
            Caption = #51201#50857
            TabOrder = 5
            OnClick = btnHeatOnOffTimeClick
          end
        end
      end
      object pnlMulti: TPanel
        Left = 297
        Top = 0
        Width = 935
        Height = 824
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
        object Label8: TLabel
          Left = 540
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '      '#53440#49437#47749'   |  '#48516'  | '#51109#52824' |   '#48380'  | H | R'
        end
        object Label9: TLabel
          Left = 720
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '      '#53440#49437#47749'   |  '#48516'  | '#51109#52824' |   '#48380'  | H | R'
        end
        object Label10: TLabel
          Left = 0
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '      '#53440#49437#47749'   |  '#48516'  | '#51109#52824' |   '#48380'  | H | R'
        end
        object Label11: TLabel
          Left = 180
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '      '#53440#49437#47749'   |  '#48516'  | '#51109#52824' |   '#48380'  | H | R'
        end
        object Label12: TLabel
          Left = 360
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '      '#53440#49437#47749'   |  '#48516'  | '#51109#52824' |   '#48380'  | H | R'
        end
        object Label13: TLabel
          Left = 900
          Top = 5
          Width = 180
          Height = 13
          AutoSize = False
          Caption = '      '#53440#49437#47749'   |  '#48516'  | '#51109#52824' |   '#48380'  | H | R'
        end
      end
    end
    object cxTabSheet3: TcxTabSheet
      Caption = #48380#54924#49688' '#48176#51221
      Color = clBtnFace
      ImageIndex = 3
      ParentColor = False
      ExplicitWidth = 1228
      ExplicitHeight = 823
      object Panel4: TPanel
        Left = 876
        Top = 0
        Width = 356
        Height = 824
        Align = alRight
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        ExplicitLeft = 872
        ExplicitHeight = 823
        object Label1: TLabel
          Left = 20
          Top = 26
          Width = 16
          Height = 14
          Caption = 'No'
        end
        object Label2: TLabel
          Left = 82
          Top = 26
          Width = 20
          Height = 14
          Caption = 'Nm'
        end
        object Memo4: TMemo
          Left = 19
          Top = 77
          Width = 321
          Height = 331
          Font.Charset = HANGEUL_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = #45208#45588#44256#46357
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
        object btnReserveInfo: TButton
          Left = 148
          Top = 15
          Width = 65
          Height = 25
          Caption = #45936#51060#53552' '#54869#51064
          TabOrder = 1
          OnClick = btnReserveInfoClick
        end
        object edTeeboxNo: TEdit
          Left = 42
          Top = 18
          Width = 34
          Height = 22
          TabOrder = 2
        end
        object btnHoldCancel: TButton
          Left = 148
          Top = 46
          Width = 65
          Height = 25
          Caption = #54848#46300#52712#49548
          TabOrder = 3
          OnClick = btnHoldCancelClick
        end
        object edTeeboxNm: TEdit
          Left = 108
          Top = 18
          Width = 34
          Height = 22
          TabOrder = 4
        end
        object btnHeatOn: TButton
          Left = 219
          Top = 15
          Width = 75
          Height = 25
          Caption = #55176#53552'On'
          TabOrder = 5
          OnClick = btnHeatOnClick
        end
        object btnHeatOff: TButton
          Left = 219
          Top = 46
          Width = 75
          Height = 25
          Caption = #55176#53552'Off'
          TabOrder = 6
          OnClick = btnHeatOffClick
        end
        object btnPLC: TButton
          Left = 20
          Top = 414
          Width = 65
          Height = 25
          Caption = 'PLC'
          TabOrder = 7
          OnClick = btnPLCClick
        end
      end
      object Panel5: TPanel
        Left = 0
        Top = 0
        Width = 876
        Height = 824
        Align = alClient
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        ExplicitWidth = 872
        ExplicitHeight = 823
        object Panel7: TPanel
          Left = 1
          Top = 42
          Width = 874
          Height = 781
          Align = alClient
          TabOrder = 0
          ExplicitWidth = 870
          ExplicitHeight = 780
          object mmoBallbackList: TMemo
            Left = 1
            Top = 1
            Width = 872
            Height = 779
            Align = alClient
            ScrollBars = ssVertical
            TabOrder = 0
            ExplicitWidth = 868
            ExplicitHeight = 778
          end
        end
        object Panel8: TPanel
          Left = 1
          Top = 1
          Width = 874
          Height = 41
          Align = alTop
          TabOrder = 1
          ExplicitWidth = 870
          object laBallBackStart: TLabel
            Left = 103
            Top = 17
            Width = 58
            Height = 14
            Caption = #48380#54924#49688' '#51221#48372
          end
          object btnBallbackList: TButton
            Left = 15
            Top = 11
            Width = 82
            Height = 25
            Caption = #48176#51221#45236#50669
            TabOrder = 0
            OnClick = btnBallbackListClick
          end
        end
      end
    end
    object cxTabSheet4: TcxTabSheet
      Caption = 'Agent '#49444#51221
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Panel1: TPanel
        Left = 0
        Top = 41
        Width = 1232
        Height = 783
        Align = alClient
        BevelKind = bkFlat
        TabOrder = 0
        object DBGrid1: TDBGrid
          Left = 1
          Top = 1
          Width = 217
          Height = 777
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
          Width = 1009
          Height = 777
          Align = alClient
          DataField = 'SETTING'
          DataSource = XGolfDM.UniDataSourceAgent
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
      object Panel10: TPanel
        Left = 0
        Top = 0
        Width = 1232
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
    Left = 368
    Top = 40
  end
  object IdAntiFreeze1: TIdAntiFreeze
    Active = False
    Left = 370
    Top = 97
  end
end
