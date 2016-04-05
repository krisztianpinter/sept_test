unit Unit1;

{ ZOOM shit
6       5       1,20    0,263           *
5       4       1,25    0,322   *
4       3       1,33    0,415
7       5       1,40    0,485           *
3       2       1,50    0,585   *
8       5       1,60    0,678
5       3       1,67    0,737           *
7       4       1,75    0,807
9       5       1,80    0,848
}

interface

uses
  unif2d, chacha,

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Types, Vcl.Buttons;

type
  TForm1 = class(TForm)
    Image: TImage;
    XminEdit: TEdit;
    Label1: TLabel;
    XmaxEdit: TEdit;
    Label2: TLabel;
    YminEdit: TEdit;
    Label3: TLabel;
    YmaxEdit: TEdit;
    Label4: TLabel;
    VminEdit: TEdit;
    Label5: TLabel;
    VmaxEdit: TEdit;
    Label6: TLabel;
    TimeButton: TButton;
    TimeLabel: TLabel;
    X2Edit: TEdit;
    Label7: TLabel;
    Y2Edit: TEdit;
    Label8: TLabel;
    ColorBWRadio: TRadioButton;
    ColorManRadio: TRadioButton;
    ColorStatRadio: TRadioButton;
    ColorTrack: TTrackBar;
    LeftButton: TSpeedButton;
    DownButton: TSpeedButton;
    UpButton: TSpeedButton;
    RightButton: TSpeedButton;
    ScrollTimer: TTimer;
    Panel1: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure TimeButtonClick(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure GrayCheckClick(Sender: TObject);
    procedure ColorChanged(Sender: TObject);
    procedure UpButtonClick(Sender: TObject);
    procedure RightButtonClick(Sender: TObject);
    procedure DownButtonClick(Sender: TObject);
    procedure LeftButtonClick(Sender: TObject);
    procedure ScrollTimerTimer(Sender: TObject);
  private
    Panning: boolean;
    StartX, StartY, X, Y: UInt64;
    b: bitpos;
    bf: byte;
    Scroll: TPoint;
    procedure Draw;
    procedure Rescale(var Board: TBoard; m, d: byte);
  protected
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

var
  TimeLine: string;
  LastTick: cardinal;

function ShlEx(const V: UInt64; b: bitpos): UInt64; inline;
begin
  if b < 0
    then Result := V shr (-b)
    else Result := V shl b;
end;

procedure Mark(const S: string);
begin
  if S = ''
    then TimeLine := ''
    else TimeLine := TimeLine+S+':'+IntToStr(GetTickCount - LastTick)+' ';
  LastTick := GetTickCount;
end;

procedure BoardToBitmap(const Board: TBoard; MaxBright: UInt64; Bmp: TBitmap);
var
  x, y: integer;
  Br: UInt64;
  SR, SL: bitpos;
  hBmp: cardinal;
  Ptr: PRGBQuad;
  BmpInfo: TBitmapInfo;
  UpHalf: boolean;
begin
  SR := Log2(MaxBright);
  if SR >= 7 then begin
    SL := 0;
    SR := SR - 7
  end else begin
    SL := 7 - SR;
    SR := 0;
  end;
  UpHalf := MaxBright shr SR shl SL < $AA;

  FillChar(BmpInfo, SizeOf(BmpInfo), 0);
  BmpInfo.bmiHeader.biSize := SizeOf(BmpInfo.bmiHeader);
  BmpInfo.bmiHeader.biWidth := Bmp.Width;
  BmpInfo.bmiHeader.biHeight := Bmp.Height;
  BmpInfo.bmiHeader.biPlanes := 1;
  BmpInfo.bmiHeader.biBitCount := 32;
  BmpInfo.bmiHeader.biCompression := BI_RGB;
  hBmp := CreateDIBSection(0, BmpInfo, DIB_RGB_COLORS, pointer(Ptr), 0, 0);
  Mark('create');

  for y := Board.Size.Y - 1 downto 0 do begin
    for x := 0 to Board.Size.X - 1 do begin
      Br := Board.At[x, y] shr SR shl SL;
      if UpHalf then Br := Br + Br shr 2;
      if Br and $ffffffffffffff00 <> 0 then Br := 255;
      with Ptr^ do begin
        rgbBlue := Br;
        rgbGreen := Br;
        rgbRed := Br;
      end;
      inc(Ptr);
    end;
  end;
  Mark('fill');

  Bmp.Handle := hBmp;
  Mark('feed');
end;

procedure TForm1.TimeButtonClick(Sender: TObject);
var
  L, H: UInt64;
  T: cardinal;
  Bmp: TBitmap;
  i: integer;
  Board: PBoard;
begin
  T := GetTickCount;

  Board := AllocBoard(Image.BoundsRect.BottomRight);
  for i := 0 to 19 do
    FillBoard(X, Y, b, Board^, L, H);

  T := GetTickCount - T;
  TimeLabel.Caption := IntToStr(T div 20) + 'ms + ';

  T := GetTickCount;

  Bmp := TBitmap.Create;
  Bmp.Width := Image.Width;
  Bmp.Height := Image.Height;
  Bmp.PixelFormat := pf32bit;
  for i := 0 to 99 do
    BoardToBitmap(Board^, H, Bmp);
  Bmp.Free;

  FreeMem(Board);

  T := GetTickCount - T;
  TimeLabel.Caption := TimeLabel.Caption + IntToStr(T div 100) + 'ms';
end;

procedure TForm1.ColorChanged(Sender: TObject);
begin
  Draw;
end;

procedure TForm1.Rescale(var Board: TBoard; m, d: byte);
var
  x, y, dx, dy: integer;
  S: UInt64;
begin
  if (m = 1) and (d = 1) then exit;
  for y := 0 to Board.Size.Y div d - 1 do begin
    for x := 0 to Board.Size.X div d - 1 do begin

      for dx := 0 to m-1 do
        for dy := 0 to m-1 do begin
          S := 0;
          // copy square x .. x+d-1, y .. y+d-1
          //  to x .. x+m-1, y .. y+m-1
          Board.At[x*m+dx, y*m+dy] := S;
        end;
    end;
  end;

  Board.Size.X := Board.Size.X div d * m;
  Board.Size.Y := Board.Size.Y div d * m;
end;

procedure TForm1.Draw;
var
  L, H: UInt64;
  Board: PBoard;
  P: TPoint;
  m, d: byte;
begin
  XminEdit.Text := IntToHex(X, 16);
  YminEdit.Text := IntToHex(Y, 16);
  X2Edit.Text := IntToHex(X + UInt64(1) shl b, 16);
  Y2Edit.Text := IntToHex(Y + UInt64(1) shl b, 16);
  XmaxEdit.Text := IntToHex(X + UInt64(Image.Width) shl b - 1, 16);
  YmaxEdit.Text := IntToHex(Y + UInt64(Image.Height) shl b - 1, 16);

  Mark('');
  P := Image.ClientRect.BottomRight;
  case bf of
    0: begin m := 1; d := 1; end;
    1: begin m := 6; d := 5; end;
    2: begin m := 7; d := 5; end;
    3: begin m := 5; d := 3; end;
    else raise Exception.Create('hell no');
  end;
  P.X := P.X div d * m;
  P.Y := P.Y div d * m;
  Board := AllocBoard(P);
  FillBoard(X - Image.Width div d * m div 2,
            Y - Image.Height div d * m div 2,
            b, Board^, L, H);
  Mark('calc');
  Rescale(Board^, m, d);
  Mark('rescl');

  VminEdit.Text := IntToHex(L, 16);
  VmaxEdit.Text := IntToHex(H, 16);

  if ColorBWRadio.Checked then H := 1;
  if ColorManRadio.Checked then begin
    H := Round(256*Exp(-ColorTrack.Position/16*Ln(2)));
    H := ShlEx(H, 2*b - 64 - 8);
    if H = 0 then H := 1;
  end;
  BoardToBitmap(Board^, H, Image.Picture.Bitmap);

  FreeMem(Board);

  TimeLabel.Caption := TimeLine;
  Image.Repaint;
end;

procedure TForm1.FormCreate(Sender: TObject);

  procedure rantes;
  const
    N = 1000;
    m = 50;
  var
    i, w, b, j: integer;
    S: array[0..512*m-1] of integer;
    SS: double;
    K: array[0..3] of UInt64;
    Bits: array[0..7] of UInt64;
  begin
    fillchar(K, SizeOf(K), 0);
    randomize;
    K[0] := RandSeed;

    fillchar(S, SizeOf(S), 0);
    for i := 0 to N-1 do begin
      for j := 0 to m-1 do begin
        ChaChaR(K, i, j, Bits);
        for w := 0 to 7 do
          for b := 0 to 63 do begin
            if Bits[w] shr b and 1 = 1 then
              inc(S[8*(64*j + b)+w]);
          end;
      end;
    end;
    SS := 0;
    for i := 0 to high(S) do SS := SS + (S[i] - N/2)*(S[i] - N/2);
    SS := SS / Length(S);
    Caption := FloatToStr(SS);
  end;

begin
  Image.Picture.Bitmap.Width := 510;
  Image.Picture.Bitmap.Height := 510;
  Image.Picture.Bitmap.PixelFormat := pf32bit;
  X := $2000000000000000;
  Y := $2000000000000000;
  b := 40;
  bf := 0;
  Draw;

  //rantes;
end;

procedure TForm1.ImageMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  StartX := X;
  StartY := Y;
  Panning := true;
end;

procedure TForm1.ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if Panning then begin
    Self.X := Self.X + (StartX - X) shl b;
    Self.Y := Self.Y + (StartY - Y) shl b;
    StartX := X;
    StartY := Y;
    Draw;
  end;
end;

procedure TForm1.ImageMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Panning := false;
end;

procedure TForm1.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
var
  P: TPoint;
begin
  P := Image.ScreenToClient(MousePos);
  if Image.ClientRect.Contains(P) then begin
    X := X - UInt64(P.X) shl b;
    Y := Y - UInt64(P.Y) shl b;
    b := b + 1;
    Draw;
    Handled := true;
  end;
end;

procedure TForm1.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
var
  P: TPoint;
begin
  P := Image.ScreenToClient(MousePos);
  if Image.ClientRect.Contains(P) then begin
    X := X + UInt64(P.X) shl b shr 1;
    Y := Y + UInt64(P.Y) shl b shr 1;
    b := b - 1;
    Draw;
    Handled := true;
  end;
end;

procedure TForm1.GrayCheckClick(Sender: TObject);
begin
  Draw;
end;

procedure TForm1.ScrollTimerTimer(Sender: TObject);
begin
  X := X + UInt64(Scroll.X) shl b;
  Y := Y + UInt64(Scroll.Y) shl b;
  Draw;
end;

procedure TForm1.UpButtonClick(Sender: TObject);
begin
  if UpButton.Down then Scroll.Y := -1 else Scroll.Y := 0;
  ScrollTimer.Enabled := not Scroll.IsZero;
  DownButton.Down := false;
end;

procedure TForm1.LeftButtonClick(Sender: TObject);
begin
  if LeftButton.Down then Scroll.X := -1 else Scroll.X := 0;
  ScrollTimer.Enabled := not Scroll.IsZero;
  RightButton.Down := false;
end;

procedure TForm1.RightButtonClick(Sender: TObject);
begin
  if RightButton.Down then Scroll.X := 1 else Scroll.X := 0;
  ScrollTimer.Enabled := not Scroll.IsZero;
  LeftButton.Down := false;
end;

procedure TForm1.DownButtonClick(Sender: TObject);
begin
  if DownButton.Down then Scroll.Y := 1 else Scroll.Y := 0;
  ScrollTimer.Enabled := not Scroll.IsZero;
  UpButton.Down := false;
end;

end.


