object fAutoCalcSettings: TfAutoCalcSettings
  Left = 385
  Top = 441
  Width = 441
  Height = 373
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1072' '#1072#1074#1090#1086#1084#1072#1095#1080#1095#1077#1089#1082#1086#1081' '#1087#1088#1086#1074#1077#1088#1082#1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 24
    Width = 169
    Height = 13
    Caption = #1047#1072#1087#1091#1089#1082#1072#1090#1100' '#1095#1077#1088#1077#1079' '#1082#1072#1078#1076#1099#1077' '#1089#1077#1082#1091#1085#1076':'
  end
  object eTime: TEdit
    Left = 194
    Top = 19
    Width = 73
    Height = 21
    TabOrder = 0
    Text = '60'
  end
  object bOk: TButton
    Left = 8
    Top = 304
    Width = 75
    Height = 25
    Caption = #1054#1082
    TabOrder = 1
    OnClick = bOkClick
  end
  object bCancel: TButton
    Left = 344
    Top = 304
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 2
    OnClick = bCancelClick
  end
end
