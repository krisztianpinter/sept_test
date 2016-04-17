unit unif2d;

interface

uses
  Math, Types;

type
  bitpos = type ShortInt;

  PBoard = ^TBoard;
  TBoard = record
    Size: TPoint;
    Grid: array[0..MaxInt div 8 - 2] of UInt64;
    function GetAt(X, Y: integer): UInt64; inline;
    procedure SetAt(X, Y: integer; const NewVal: UInt64); inline;
    property At[X, Y: integer]: UInt64 read GetAt write SetAt;
  end;

function AllocBoard(ASize: TPoint): PBoard;

function Log2(X: UInt64): bitpos;

procedure FillBoard(XX, YY: UInt64; Sb: bitpos; out Board: TBoard; out VMin, VMax: UInt64);

var
  World: UInt64 = 0;


implementation


uses
  chacha;

{$O+}

function AllocBoard(ASize: TPoint): PBoard;
begin
  Result := PBoard(AllocMem(ASize.X * ASize.Y * 8));
  Result.Size := ASize;
end;

function TBoard.GetAt(X, Y: integer): UInt64;
begin
  Result := Grid[Y * Size.X + X];
end;

procedure TBoard.SetAt(X, Y: integer; const NewVal: UInt64);
begin
  Grid[Y * Size.X + X] := NewVal;
end;

const
  TotalNumber = $FFFFFFFFFFFFFFFF;

function Log2(X: UInt64): bitpos;
begin
  if X = 0 then begin
    Result := -1;
    exit;
  end;
  Result := 0;
  if X and $FFFFFFFF00000000 <> 0 then begin
    X := X shr 32;
    Result := 32;
  end;
  if X and $FFFF0000 <> 0 then begin
    X := X shr 16;
    Inc(Result, 16);
  end;
  if X and $FF00 <> 0 then begin
    X := X shr 8;
    Inc(Result, 8);
  end;
  if X and $F0 <> 0 then begin
    X := X shr 4;
    Inc(Result, 4);
  end;
  if X and $C <> 0 then begin
    X := X shr 2;
    Inc(Result, 2);
  end;
  if X and $2 <> 0 then
    Inc(Result, 1);
end;

function Max(A, B: bitpos): bitpos; overload;
begin
  if A > B then Result := A else Result := B;
end;

function Min(A, B: bitpos): bitpos; overload;
begin
  if A < B then Result := A else Result := B;
end;


type
  TMemBlock = array[0..7] of UInt64;

procedure MemBlock(X, Y: UInt64; Sb: bitpos; out MB: TMemBlock);
var
  Key: array[0..3] of UInt64;
begin
  Key[0] := World;
  Key[1] := Sb;
  Key[2] := 0;
  Key[3] := 0;
  ChaChaR(Key, Int64(X), Int64(Y), MB, 5);
end;

procedure Sort(var R1, R2: UInt64); inline;
var
  W: UInt64;
begin
  if R1 > R2 then begin
    W := R1;
    R1 := R2;
    R2 := W;
  end;
end;

procedure CorrectSum(V: UInt64; var V1, V2, V3, V4: UInt64; const R: UInt64); inline;
begin
  V := V - V1 - V2 - V3 - V4;
  case R and 3 of
    0: V1 := V1 + V;
    1: V2 := V2 + V;
    2: V3 := V3 + V;
    3: V4 := V4 + V;
  end;
end;

// calculates A * B / 2^64
function M64(A, B: UInt64): UInt64; inline;
type
  THL = packed record L, H: cardinal; end;
var
  AA: THL absolute A;
  BB: THL absolute B;
begin
  Result := UInt64(AA.H) * UInt64(BB.H)
          + UInt64(AA.H) * UInt64(BB.L) shr 32
          + UInt64(AA.L) * UInt64(BB.H) shr 32

          + ( UInt64(cardinal(AA.H * BB.L))
              + UInt64(cardinal(AA.L * BB.H))
              + UInt64(AA.L) * UInt64(BB.L) shr 32
              + UInt64(cardinal(AA.L * BB.L)) shr 31 ) shr 32;
end;

// calculates A / B * 2^64
function D64(A, B: UInt64): UInt64; // inline;
begin

end;

function Avg(const A, B: UInt64): UInt64; inline;
begin
  Result := A shr 1 + B shr 1 + Cardinal(A) and Cardinal(B) and 1;
end;

function SqrtI(X: UInt64): UInt64; inline;
var
  b: UInt64;
begin
  Result := 0;
  b := UInt64(1) shl (Log2(X) and not 1);

  while b <> 0 do begin
    if (X >= Result + b) then begin
      X := X - Result - b;
      Result := (Result shr 1) + b;
    end else
      Result := Result shr 1;

    b := b shr 2;
  end;
end;

procedure SplitWild(V, R1, R2, R3, R4: UInt64; out V1, V2, V3, V4: UInt64);
begin
  Sort(R1, R2);
  Sort(R2, R3);
  Sort(R1, R2);

  V1 := M64(V, R1);
  V2 := M64(V, R2 - R1);
  V3 := M64(V, R3 - R2);
  V4 := M64(V, $FFFFFFFFFFFFFFFF - R3);

  CorrectSum(V, V1, V2, V3, V4, R4);
end;

procedure SplitUnif(V: UInt64; const R: TMemBlock; out V1, V2, V3, V4: UInt64);
var
  Q, S1, S2, S3: UInt64;
  i: integer;
begin
  if V < 32 then begin
    V1 := 0;  V2 := 0;  V3 := 0;  V4 := 0;
    for i := 0 to V - 1 do begin
      case R[0] shr (i*2) and 3 of
        0: V1 := V1 + 1;
        1: V2 := V2 + 1;
        2: V3 := V3 + 1;
        3: V4 := V4 + 1;
      end;
    end;
  end else begin
    S1 := V shr 2;
    S2 := V shr 1;
    S3 := S2 + S1;

    // now we limit delta to sqrt V. it should be a proper distribution.
    Q := SqrtI(V);
    //Q := Q shr 1 + Q shr 3 + Q shr 4; // sqrt(2)
    Q := Q shr 1 + Q shr 2 + Q shr 4 + Q shr 5; // 0.8
    S1 := S1 + M64(Q, R[0]) - Q shr 1;
    S2 := S2 + M64(Q, R[1]) - Q shr 1;
    S3 := S3 + M64(Q, R[2]) - Q shr 1;

    V1 := S1;
    V2 := S2 - S1;
    V3 := S3 - S2;
    V4 := V - S3;

    CorrectSum(V, V1, V2, V3, V4, R[3]);
  end;
end;

{function F(X, Y: UInt64): double;
var
  Xf, Yf: double;
const
  scale = 1e7;
begin   // integ 1/r^3:  -sqrt(x^2+y^2)/(x y)
  Xf := X / scale - scale/2.0;
  Yf := Y / scale - scale/2.0;
  Result := -Sqrt(Xf*Xf+Yf*Yf) / Xf / Yf;
end;}

function F(X, Y: UInt64): double; // inline;
var
  F: double;
  XS: Int64 absolute X;
  YS: Int64 absolute Y;
begin
  F := Int64(1) shl 63;
  F := F + XS;
  Result := ArcTan(F * 1e-10);
  F := YS;
  F := F + Int64(1) shl 63;
  Result := Result * ArcTan(F * 1e-10);
end;

procedure SplitR(V: UInt64; const R: TMemBlock; const Xmin, Xmax, Ymin, Ymax: UInt64;
  out V1, V2, V3, V4: UInt64);
var
  Q, S1, S2, S3, S4, Xmid, Ymid: UInt64;
  VS, VTR, VBR, VTL, VBL, TM, LM, RM, BM, MM: double;
  i: integer;
const
  MaxUInt64f = 65536.0*65536.0*65536.0*65536.0 - 1;
begin
  if V < 32 then begin
    V1 := 0;  V2 := 0;  V3 := 0;  V4 := 0;
    for i := 0 to V - 1 do begin
      case R[0] shr (i*2) and 3 of
        0: V1 := V1 + 1;
        1: V2 := V2 + 1;
        2: V3 := V3 + 1;
        3: V4 := V4 + 1;
      end;
    end;
  end else begin
    Xmid := Avg(Xmin, Xmax);
    Ymid := Avg(Ymin, Ymax);
    TM := F(Xmid, Ymin);
    BM := F(Xmid, Ymax);
    LM := F(Xmin, Ymid);
    RM := F(Xmax, Ymid);
    MM := F(Xmid, Ymid);
    VTR := RM + TM - F(Xmax, Ymin) - MM;
    VBR := F(Xmax, Ymax) - RM - BM + MM;
    VTL := MM - TM - LM + F(Xmin, Ymin);
    VBL := BM - MM - F(Xmin, Ymax) + LM;

    if VTR < 0 then VTR := 0;
    if VBR < 0 then VBR := 0;
    if VTL < 0 then VTL := 0;
    if VBL < 0 then VBL := 0;

    VS := VTR + VBR + VTL + VBL;

    // todo: rewrite to
    // todo: add some random
    if VS = 0 then begin
      V1 := V shr 2;
      V2 := V shr 2;
      V3 := V shr 2;
      V4 := V shr 2;
    end else begin
      V1 := M64(V, Trunc(VTL / VS * MaxUInt64f / 2.0) shl 1);
      V2 := M64(V, Trunc(VTR / VS * MaxUInt64f / 2.0) shl 1);
      V3 := M64(V, Trunc(VBL / VS * MaxUInt64f / 2.0) shl 1);
      V4 := M64(V, Trunc(VBR / VS * MaxUInt64f / 2.0) shl 1);
    end;

    CorrectSum(V, V1, V2, V3, V4, R[3]);
  end;
end;

procedure Split(const V: UInt64; const R: TMemBlock; const Xmin, Xmax, Ymin, Ymax: UInt64;
  out V1, V2, V3, V4: UInt64);
begin
//  SplitWild2(V, R[0], R[1], R[2], R[3], V1, V2, V3, V4);
//  SplitUnif(V, R, V1, V2, V3, V4);
  SplitR(V, R, Xmin, Xmax, Ymin, Ymax, V1, V2, V3, V4);
end;

procedure FillBoard(XX, YY: UInt64; Sb: bitpos; out Board: TBoard; out VMin, VMax: UInt64);
var
  b: bitpos;
  X, Y, X2, Y2, Xmin, Xmax, Ymin, Ymax, S00, S01, S10, S11: UInt64;
  Xd, Yd, Xo, Yo, Xn, Yn: integer;
  S: TMemBlock;
begin
  Board.At[0, 0] := TotalNumber;

  for b := 63 downto Sb do begin
    Xmin := XX shr b shr 1;
    Xmax := (XX + UInt64(Board.Size.X-1) shl Sb) shr b shr 1;
    Xd := Xmax - Xmin;
    Ymin := YY shr b shr 1;
    Ymax := (YY + UInt64(Board.Size.Y-1) shl Sb) shr b shr 1;
    Yd := Ymax - Ymin;

    Vmin := UInt64(-1);
    Vmax := 0;
    for Xo := Xd downto 0 do begin
      for Yo := Yd downto 0 do begin
        X := (Xo + Xmin) shl b shl 1;
        Y := (Yo + Ymin) shl b shl 1;
        X2 := (Xo + Xmin + 1) shl b shl 1 - 1;
        Y2 := (Yo + Ymin + 1) shl b shl 1 - 1;

        MemBlock(X, Y, b, S);
        Split(Board.At[Xo, Yo], S, X, X2, Y, Y2, S00, S01, S10, S11);

        if Vmax < S00 then Vmax := S00;
        if Vmax < S01 then Vmax := S01;
        if Vmax < S10 then Vmax := S10;
        if Vmax < S11 then Vmax := S11;
        if Vmin > S00 then Vmin := S00;
        if Vmin > S01 then Vmin := S01;
        if Vmin > S10 then Vmin := S10;
        if Vmin > S11 then Vmin := S11;

        Xn := Xo shl 1 - (XX shr b and 1);
        Yn := Yo shl 1 - (YY shr b and 1);

        if (Xn >= 0) and (Yn >= 0)
          then Board.At[Xn, Yn] := S00;
        if (Xn < Board.Size.X-1) and (Yn >= 0)
          then Board.At[Xn+1, Yn] := S10;
        if (Xn >= 0) and (Yn < Board.Size.Y-1)
          then Board.At[Xn, Yn+1] := S01;
        if (Xn < Board.Size.X-1) and (Yn < Board.Size.Y-1)
          then Board.At[Xn+1, Yn+1] := S11;
      end;
    end;
  end;
end;

procedure BlankLog(Xmin, Xmax, Ymin, Ymax, Vmin, Vmax: UInt64);
begin
end;

initialization
  chacha.Test;
end.
