object DMPrincipal: TDMPrincipal
  OldCreateOrder = False
  Height = 341
  Width = 467
  object qryConsultaTabelaLocal: TFDQuery
    Connection = FDLocal
    Left = 384
    Top = 16
  end
  object qryConsultaTabelaServer: TFDQuery
    Connection = FDServer
    Left = 392
    Top = 128
  end
  object qryApagaLocal: TFDQuery
    Connection = FDLocal
    Left = 192
    Top = 16
  end
  object qryConsultaLocal: TFDQuery
    CachedUpdates = True
    Connection = FDLocal
    Left = 96
    Top = 16
  end
  object qryLocalUpdate: TFDQuery
    Connection = FDLocal
    Left = 288
    Top = 16
  end
  object FDLocal: TFDConnection
    Params.Strings = (
      'User_Name=sysdba'
      'Password=masterkey'
      'Port=3050'
      'CharacterSet=WIN1252'
      'DriverID=FB')
    LoginPrompt = False
    Left = 16
    Top = 16
  end
  object FDServer: TFDConnection
    Params.Strings = (
      'Protocol=TCPIP'
      'Port=3050'
      'CharacterSet=WIN1252'
      'User_Name=sysdba'
      'Password=masterkey'
      'DriverID=FB')
    LoginPrompt = False
    Left = 16
    Top = 128
  end
  object qryApagaServer: TFDQuery
    Connection = FDServer
    Left = 200
    Top = 128
  end
  object qryServerUpdate: TFDQuery
    Connection = FDServer
    Left = 296
    Top = 128
  end
  object qryConsultaServidor: TFDQuery
    CachedUpdates = True
    Connection = FDServer
    Left = 96
    Top = 128
  end
end
