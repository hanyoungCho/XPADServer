object XGolfDM: TXGolfDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 387
  Width = 588
  object Connection: TUniConnection
    AutoCommit = False
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 120
    Top = 17
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object MySQL: TMySQLUniProvider
    Left = 46
    Top = 17
  end
  object qrySeatUpdate: TUniQuery
    Connection = Connection
    Left = 248
    Top = 16
  end
  object qryTemp: TUniQuery
    Connection = Connection
    Left = 184
    Top = 16
  end
  object qrySeatStatusUpdate: TUniQuery
    Connection = ConnectionSeat
    Left = 208
    Top = 144
  end
  object ConnectionSeat: TUniConnection
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 120
    Top = 145
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object ConnectionAuto: TUniConnection
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 120
    Top = 81
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object ConnectionTm: TUniConnection
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 208
    Top = 81
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object ConnectionReserve: TUniConnection
    AutoCommit = False
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 120
    Top = 209
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object ConnectionHold: TUniConnection
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 120
    Top = 273
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object conTeeBox: TUniConnection
    ProviderName = 'MySQL'
    BeforeConnect = conTeeBoxBeforeConnect
    Left = 48
    Top = 83
  end
  object ConnectionTemp: TUniConnection
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 328
    Top = 17
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object UniDataSourceAgent: TUniDataSource
    DataSet = UniQueryAgent
    Left = 400
    Top = 224
  end
  object UniConnectionAgent: TUniConnection
    AutoCommit = False
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'xgolf'
    Username = 'xgolf'
    Server = 'localhost'
    LoginPrompt = False
    Left = 400
    Top = 129
    EncryptedPassword = '87FF98FF90FF93FF99FFCFFFCEFFCFFFCAFF'
  end
  object UniQueryAgent: TUniQuery
    Connection = UniConnectionAgent
    Left = 400
    Top = 176
  end
end
