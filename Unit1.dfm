object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 527
  ClientWidth = 698
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  PixelsPerInch = 96
  TextHeight = 13
  object Image: TImage
    Left = 9
    Top = 8
    Width = 510
    Height = 510
    OnMouseDown = ImageMouseDown
    OnMouseMove = ImageMouseMove
    OnMouseUp = ImageMouseUp
  end
  object Panel1: TPanel
    Left = 536
    Top = 0
    Width = 162
    Height = 527
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    object DownButton: TSpeedButton
      Left = 45
      Top = 412
      Width = 23
      Height = 22
      AllowAllUp = True
      GroupIndex = 3
      OnClick = DownButtonClick
    end
    object Label1: TLabel
      Left = 0
      Top = 3
      Width = 22
      Height = 13
      Caption = 'Xmin'
    end
    object Label2: TLabel
      Left = 0
      Top = 57
      Width = 26
      Height = 13
      Caption = 'Xmax'
    end
    object Label3: TLabel
      Left = 0
      Top = 101
      Width = 22
      Height = 13
      Caption = 'Ymin'
    end
    object Label4: TLabel
      Left = 0
      Top = 155
      Width = 26
      Height = 13
      Caption = 'Ymax'
    end
    object Label5: TLabel
      Left = 0
      Top = 200
      Width = 22
      Height = 13
      Caption = 'Vmin'
    end
    object Label6: TLabel
      Left = 0
      Top = 227
      Width = 26
      Height = 13
      Caption = 'Vmax'
    end
    object Label7: TLabel
      Left = 0
      Top = 30
      Width = 12
      Height = 13
      Caption = 'X2'
    end
    object Label8: TLabel
      Left = 0
      Top = 128
      Width = 12
      Height = 13
      Caption = 'Y2'
    end
    object LeftButton: TSpeedButton
      Left = 24
      Top = 392
      Width = 23
      Height = 22
      AllowAllUp = True
      GroupIndex = 2
      OnClick = LeftButtonClick
    end
    object RightButton: TSpeedButton
      Left = 66
      Top = 392
      Width = 23
      Height = 22
      AllowAllUp = True
      GroupIndex = 4
      OnClick = RightButtonClick
    end
    object TimeLabel: TLabel
      Left = 4
      Top = 448
      Width = 153
      Height = 34
      AutoSize = False
      Caption = 'TimeLabel'
      WordWrap = True
    end
    object UpButton: TSpeedButton
      Left = 45
      Top = 370
      Width = 23
      Height = 22
      AllowAllUp = True
      GroupIndex = 1
      OnClick = UpButtonClick
    end
    object ColorBWRadio: TRadioButton
      Left = 4
      Top = 273
      Width = 113
      Height = 17
      Caption = '0/1'
      TabOrder = 0
      OnClick = ColorChanged
    end
    object ColorManRadio: TRadioButton
      Left = 4
      Top = 296
      Width = 113
      Height = 17
      Caption = 'Manual'
      Checked = True
      TabOrder = 1
      TabStop = True
      OnClick = ColorChanged
    end
    object ColorStatRadio: TRadioButton
      Left = 4
      Top = 343
      Width = 113
      Height = 17
      Caption = 'Statistics'
      TabOrder = 2
      OnClick = ColorChanged
    end
    object ColorTrack: TTrackBar
      Left = 16
      Top = 319
      Width = 135
      Height = 26
      LineSize = 16
      Max = 256
      Min = -256
      PageSize = 64
      Frequency = 32
      ShowSelRange = False
      TabOrder = 3
      OnChange = ColorChanged
    end
    object TimeButton: TButton
      Left = 4
      Top = 488
      Width = 75
      Height = 25
      Caption = 'Time'
      TabOrder = 4
      OnClick = TimeButtonClick
    end
    object VmaxEdit: TEdit
      Left = 32
      Top = 224
      Width = 107
      Height = 21
      TabOrder = 5
    end
    object VminEdit: TEdit
      Left = 32
      Top = 197
      Width = 107
      Height = 21
      TabOrder = 6
    end
    object X2Edit: TEdit
      Left = 32
      Top = 27
      Width = 107
      Height = 21
      TabOrder = 7
    end
    object XmaxEdit: TEdit
      Left = 32
      Top = 54
      Width = 107
      Height = 21
      TabOrder = 8
    end
    object XminEdit: TEdit
      Left = 32
      Top = 0
      Width = 107
      Height = 21
      TabOrder = 9
    end
    object Y2Edit: TEdit
      Left = 32
      Top = 125
      Width = 107
      Height = 21
      TabOrder = 10
    end
    object YmaxEdit: TEdit
      Left = 32
      Top = 152
      Width = 107
      Height = 21
      TabOrder = 11
    end
    object YminEdit: TEdit
      Left = 32
      Top = 98
      Width = 107
      Height = 21
      TabOrder = 12
    end
  end
  object ScrollTimer: TTimer
    Enabled = False
    Interval = 30
    OnTimer = ScrollTimerTimer
    Left = 640
    Top = 416
  end
end
