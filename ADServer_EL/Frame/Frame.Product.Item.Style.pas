unit Frame.Product.Item.Style;

interface

uses
  uStruct,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, FMX.Edit;

type
  TProductItemStyle = class(TFrame)
    Layout: TLayout;
    BodyImage: TImage;
    Text1: TText;
    Edit1: TEdit;
  private
    { Private declarations }
    FSeatInfo: TSeatInfo;
    FSeatInfoTemp: TSeatInfo;
  public
    { Public declarations }

    procedure DisPlayTasukInfo;

    property SeatInfo: TSeatInfo read FSeatInfo write FSeatInfo;
    property SeatInfoTemp: TSeatInfo read FSeatInfoTemp write FSeatInfoTemp;
  end;

implementation

uses
  uFunction, uGlobal;

{$R *.fmx}

procedure TProductItemStyle.DisPlayTasukInfo;
begin
  Text1.Text := IntToStr(SeatInfo.SeatNo);

end;

end.
