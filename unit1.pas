unit Unit1;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Messages, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Label1: TLabel;
    ListBox1: TListBox;
    PaintBox1: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure Label1Click(Sender: TObject);
  private
    { private declarations }
    buf : Widestring;
    LastImeLen : Integer;
    procedure WMIMEComposition(var Msg: TMessage); message WM_IME_COMPOSITION;
    procedure WMIMEStartComposition(var Msg: TMessage); message WM_IME_STARTCOMPOSITION;
    //
    procedure WMIMEEndComposition(var Msg: TMessage); message WM_IME_ENDCOMPOSITION;
    procedure AddMessages(const Msg: TMessage);
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses Windows, imm, Lazutf8, fileutil;

const
     limitchar = 30;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key=#8 then begin
    Delete(buf,Length(buf),1);
  end else
    buf := buf + Key;
  PaintBox1.Canvas.TextOut(1,1,UTF8Encode(buf+'   '));
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Label1Click(nil);
end;

procedure TForm1.Label1Click(Sender: TObject);
begin
  buf := '';
  PaintBox1.Canvas.Rectangle(PaintBox1.ClientRect);
  PaintBox1.Update;
  ListBox1.Clear;
  ActiveControl:=nil;
end;

procedure TForm1.WMIMEComposition(var Msg: TMessage);
var
   imc : HIMC;
   icode, len : Integer;
   p : PWideChar;
begin
  AddMessages(Msg);
   if Msg.lParam and GCS_COMPSTR <> 0 then
      icode := GCS_COMPSTR
      else if Msg.lParam and GCS_RESULTSTR <> 0 then
           icode := GCS_RESULTSTR
           else
               icode := 0;
   // check compositon state
   if icode<>0 then begin
     imc := ImmGetContext(Handle);
     try
        len := ImmGetCompositionStringW(imc,icode,nil,0);
        GetMem(p,len+2);
        try
           // get compositon string
           ImmGetCompositionStringW(imc,icode,p,len);
           len := len shr 1;
           p[len]:=#0;
           // delete previous inputed strings
           if LastImeLen>0 then
              if Length(buf)>0 then
                 Delete(buf,Length(buf)-LastImeLen+1,LastImeLen);
           buf:=buf+p;
           // if IME return Result string, don't delete buffer
           if icode=GCS_RESULTSTR then
              LastImeLen:=0
              else LastImeLen:=len;
           // output to controls, must be utf-8 string
           PaintBox1.Canvas.TextOut(1,1,UTF8Encode(buf+'  '));
        finally
          FreeMem(p);
        end;

     finally
       ImmReleaseContext(Handle,imc);
     end;
   end;
   // disable IME Compositoin window
   Msg.Result:=-1;
end;

procedure TForm1.WMIMEStartComposition(var Msg: TMessage);
begin
  LastImeLen:=0;
  AddMessages(Msg);
end;

procedure TForm1.WMIMEEndComposition(var Msg: TMessage);
begin
  AddMessages(Msg);
end;

procedure TForm1.AddMessages(const Msg: TMessage);
var
   swork : string;
begin
  case Msg.msg of
  WM_IME_STARTCOMPOSITION : ListBox1.AddItem('WM_IME_STARTCOMPOSITION',nil);
  WM_IME_COMPOSITION : begin
                         swork := '';
                         if Msg.lParam and GCS_RESULTSTR <> 0 then
                            swork:=swork+' GCS_RESULTSTR';
                         if Msg.lParam and GCS_COMPSTR <> 0 then
                            swork:=swork+' GCS_COMPSTR';
                         if Msg.lParam and GCS_COMPATTR <> 0 then
                            swork:=swork+' GCS_COMPATTR';
                         ListBox1.AddItem(Format('WM_IME_COMPOSITION %x %s',[Msg.lParam,swork]),nil);
                       end;
  WM_IME_ENDCOMPOSITION : ListBox1.AddItem('WM_IME_ENDCOMPOSITION',nil);
  end;
  if ListBox1.Count>0 then;
    ListBox1.ItemIndex:=ListBox1.Count-1;
end;


end.

