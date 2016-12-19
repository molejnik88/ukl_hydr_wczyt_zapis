unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Math;

type

  { TForm1 }

  TForm1 = class(TForm)
    TzEdit: TEdit;
    TzLabel: TLabel;
    Label6: TLabel;
    stopButton: TButton;
    cEdit: TEdit;
    cLabel: TLabel;
    dtlLabel: TLabel;
    fLabel: TLabel;
    fEdit: TEdit;
    aLabel: TLabel;
    aEdit: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    QpLabel: TLabel;
    mzrLabel: TLabel;
    pmaxEdit: TEdit;
    mzrEdit: TEdit;
    dtlEdit: TEdit;
    QpEdit: TEdit;
    vmaxEdit: TEdit;
    xrmaxEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SymulacjaButton: TButton;
    ReadButton: TButton;
    Shape1: TShape;
    QmaxEdit: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure ReadButtonClick(Sender: TObject);
    procedure stopButtonClick(Sender: TObject);
    procedure SymulacjaButtonClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  pTab : Array [0..400] of Real;
  vTab : Array [0..400] of Real;
  xrTab : Array [0..400] of Real;
  qzTab : Array [0..400] of Real;

const
  szer=800; wys=600;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ReadButtonClick(Sender: TObject);
var
  i, j : Integer;
  s : String;
  plikp, plikv, plikxr, plikqz : Text;
begin
  // plik z wartosciami cisnienia
  AssignFile(plikp, 'pp.txt');
  Reset(plikp);

  i:=0;
  for j:=0 to 1200 do
  begin
    if ((j MOD 3)=0) then
    begin
    ReadLN(plikp, s);
    pTab[i]:=strtofloat(s);
    i:=i+1;
    end
    else
    ReadLN(plikp, s);
    end;

  // plik z wartosciami predkosci ladunku
  AssignFile(plikv, 'vq.txt');
  Reset(plikv);

  i:=0;
  for j:=0 to 1200 do
  begin
    if ((j MOD 3)=0) then
    begin
    ReadLN(plikv, s);
    vTab[i]:=strtofloat(s);
    i:=i+1;
    end
    else
    ReadLN(plikv, s);
    end;

  // plik z wartosciami x rozdzielacza
  AssignFile(plikxr, 'xr.txt');
  Reset(plikxr);

  i:=0;
  for j:=0 to 1200 do
  begin
    if ((j MOD 3)=0) then
    begin
    ReadLN(plikxr, s);
    xrTab[i]:=strtofloat(s);
    i:=i+1;
    end
    else
    ReadLN(plikxr, s);
    end;

  // plik z wartosciami Qz
  AssignFile(plikqz, 'qz.txt');
  Reset(plikqz);

  i:=0;
  for j:=0 to 1200 do
  begin
    if ((j MOD 3)=0) then
    begin
    ReadLN(plikqz, s);
    qzTab[i]:=strtofloat(s);
    i:=i+1;
    end
    else
    ReadLN(plikqz, s);
    end;

end;

procedure TForm1.stopButtonClick(Sender: TObject);
begin
  halt;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Shape1.Width:=szer;
  Shape1.Height:=wys;
end;

procedure TForm1.SymulacjaButtonClick(Sender: TObject);
var
dtl, Atl, mzr, Qp, Qprz, f, a, c : Real;
pp, vp, xr, xrk, Qzp : Real;
xrp : Real =5;
p, dp, v, dv, t, tr : Real;
tp : Real; // marker początku rozruchu
dtpom : Real = 0.0025;
dt : Real = 0.0001;
tsym : Real = 1;
i,j,k,n,dn : Integer;
ppu : Real = 82.31;
psu : Real = 70.31;
deltap : Real;
Etap : Integer;
// zmienne do zaworu
pz : Real = 94.4;
hz : Real = 4.62;
Tz : Real; // =0.085;
Qz, dQz : Real;
// zmienne do wykresu
skp, skv, skx, skQ, skt : Real;
pmax, vmax, xrmax, Qmax : Real;
begin
  // czyszczenie wykresu
  Shape1.Canvas.Clear;
  // wczytanie zmiennych
  mzr:=strtofloat(mzrEdit.Text);
  dtl:=strtofloat(dtlEdit.Text);
  Qp:=strtofloat(QpEdit.Text);
  f:=strtofloat(fEdit.Text);
  a:=strtofloat(aEdit.Text);
  c:=strtofloat(cEdit.Text);
  pmax:=strtofloat(pmaxEdit.Text);
  vmax:=strtofloat(vmaxEdit.Text);
  xrmax:=strtofloat(xrmaxEdit.Text);
  Qmax:=strtofloat(QmaxEdit.Text);
  Tz:=strtofloat(TzEdit.Text);
  // przeliczenie jednostek
  dtl:=dtl/1000;
  Qp:=Qp/60000;
  a:=a*power(10,-12);
  c:=c*power(10,-12);
  ppu:=ppu*power(10,5);
  psu:=psu*power(10,5);
  pz:=pz*power(10,5);
  hz:=hz*power(10,-10);
  // skale
  skt:=szer/tsym;
  skv:=wys/vmax;
  skp:=wys/pmax;
  skx:=wys/xrmax;
  skQ:=wys/Qmax;
  // obliczenia
  k:=round(dtpom/dt);
  dn:=round(1/dt);
  deltap:=ppu-psu;
  Atl:=(pi*dtl*dtl)/4;
  tr:=0.0558*(16.25/100);
  xrk:=xrp+0.65;
  // warunki poczatkowe
  i:=0; j:=0; n:=0; t:=0;
  p:=0; v:=0; Etap:=1; Qz:=0;
  repeat
    if i<400 then
    begin
      pp:=pTab[i]+(pTab[i+1]-pTab[i])*(j/k);
      vp:=vTab[i]+(vTab[i+1]-vTab[i])*(j/k);
      xr:=xrTab[i]+(xrTab[i+1]-xrTab[i])*(j/k);
      Qzp:=qzTab[i]+(qzTab[i+1]-qzTab[i])*(j/k);
    end
    else
    begin
      pp:=pTab[i];
      vp:=vTab[i];
      xr:=xrTab[i];
      qzp:=qzTab[i];
    end;
    // wymuszenie
    Qp:=(28-0.0142*(p/power(10,5)))/60000;
    {if t<0.1183 then Qprz:=0;
    if ((t>=0.1183) and (t<0.1742)) then Qprz:=(Qp/(0.1742-0.1183))*(t-0.1183);
    if t>=0.1742 then Qprz:=Qp;}
    if xr<xrp then Qprz:=0;
    if ((xr>=xrp)and(xr<=xrk)) then Qprz:=(Qp/(xrk-xrp))*(xr-xrp);
    if xr>xrk then Qprz:=Qp;
    if p>ppu then Etap:=2;
    if Etap=1 then
    begin
      dp:=(1/c)*(Qprz-a*p-Qz);
      dv:=0;
      if p>=pz then
                   dQz:=(1/Tz)*(hz*(p-pz)-Qz)
               else
                   dQz:=(1/Tz)*(-Qz);
    end
    else
    begin
      dp:=(1/c)*(Qprz-a*p-v*Atl-Qz);
      dv:=(1/mzr)*((p)*Atl-mzr*9.81-f*v);
      if p>=pz then
                   dQz:=(1/Tz)*(hz*(p-pz)-Qz)
               else
                   dQz:=(1/Tz)*(-Qz);
    end;

    shape1.Canvas.Pixels[round(t*skt), round(skp*(pmax-pp))]:=clblue;
    shape1.Canvas.Pixels[round(t*skt), round(skp*(pmax-p/power(10,5)))]:=clred;
    shape1.Canvas.Pixels[round(t*skt), round(skv*(vmax-vp*60))]:=clblue;
    shape1.Canvas.Pixels[round(t*skt), round(skv*(vmax-v*60))]:=clred;
    shape1.Canvas.Pixels[round(t*skt), round(skx*(xrmax-xr))]:=clblue;
    shape1.Canvas.Pixels[round(t*skt), round(skQ*(Qmax-Qprz*60000))]:=clred;
    shape1.Canvas.Pixels[round(t*skt), round(skQ*(Qmax-Qzp))]:=clblue;
    shape1.Canvas.Pixels[round(t*skt), round(skQ*(Qmax-Qz*60000))]:=clred;
    p:=p+dp*dt;
    v:=v+dv*dt;
    if Qz<0 then Qz:=0 else Qz:=Qz+dQz*dt;
    n:=n+1;
    j:=j+1;
    t:=n/dn;
    if j=k then
       begin
         i:=i+1;
         j:=0;
       end;

  until ((i=400) and (j=1)) ;


end;

end.

