object DMPrincipal: TDMPrincipal
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 232
  Width = 300
  object FDLocal: TFDConnection
    Params.Strings = (
      'User_Name=sysdba'
      'Password=masterkey'
      'Port=3052'
      'CharacterSet=WIN1252'
      'Database=D:\Fontes\$Servisoft\Bases\SSFacil\SSFacil.FDB'
      'DriverID=FB')
    Connected = True
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
    Left = 80
    Top = 16
  end
end
