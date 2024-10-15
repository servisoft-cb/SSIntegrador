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
    LoginPrompt = False
    Left = 16
    Top = 16
  end
  object FDServer: TFDConnection
    Params.Strings = (
      'Protocol=TCPIP'
      'Port=3052'
      'CharacterSet=WIN1252'
      'User_Name=sysdba'
      'Password=masterkey'
      'DriverID=FB'
      
        'database=192.168.0.99:D:\Fontes\$Servisoft\Bases\SSFacil\SSFacil' +
        '.FDB')
    LoginPrompt = False
    Left = 80
    Top = 16
  end
end
