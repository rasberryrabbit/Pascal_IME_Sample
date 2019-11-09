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
    buf : Unicodestring;
    LastImeLen : Integer;
    procedure WMIMENotify(var Msg: TMessage); message WM_IME_NOTIFY;
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
  buffer: array[0..200] of WideChar;

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

procedure TForm1.WMIMENotify(var Msg: TMessage);
const
  IMN_OPENCANDIDATE_CH = 269;
  IMN_CLOSECANDIDATE_CH = 270;
var
  candiform: CANDIDATEFORM;
  imc: HIMC;
  cPos: TPoint;
begin
  case Msg.WParam of
    //IMN_SETOPENSTATUS:
    //  UpdateImeWindow(Sender);
    { show candidate window. it need japanese and chinese input method }
    IMN_OPENCANDIDATE_CH,
    IMN_OPENCANDIDATE:
      begin
        imc:=ImmGetContext(Form1.Handle);
        try
          if imc<>0 then
          begin
            if GetCaretPos(cPos) then
            begin
              candiform.dwIndex:=0;
              candiform.dwStyle:=CFS_FORCE_POSITION;

              candiform.ptCurrentPos.X:=cPos.X;
              candiform.ptCurrentPos.Y:=cPos.Y+Form1.Canvas.TextHeight('g')+1;

              ImmSetCandidateWindow(imc,@candiform);
            end;
          end;
        finally
          ImmReleaseContext(Form1.Handle,imc);
        end;
      end;
  end;
end;

procedure TForm1.WMIMEComposition(var Msg: TMessage);
const
  IME_COMPFLAG = GCS_COMPSTR or GCS_COMPATTR or GCS_CURSORPOS;
  IME_RESULTFLAG = GCS_RESULTCLAUSE or GCS_RESULTSTR;
var
  IMC: HIMC;
  imeCode, imeReadCode, len, ImmGCode, astart, alen: Integer;
begin
  AddMessages(Msg);
  imeCode:=Msg.lParam and (IME_COMPFLAG or IME_RESULTFLAG);
  { check compositon state }
  if imeCode<>0 then
  begin
    IMC := ImmGetContext(Form1.Handle);
    try
       ImmGCode:=Msg.wParam;
        { check escape key code }
        if ImmGCode<>$1b then
        begin
          { for janpanese IME, process result and composition separately.
            It comes together. Caret position doesn't implemented.
            Candidate window need caret position for showing window. }
          { delete last char in buffer }
          if LastImeLen>0 then
            if Length(buf)>0 then
              Delete(buf,Length(buf)-LastImeLen+1,LastImeLen);
          { insert result string }
          if imecode and IME_RESULTFLAG<>0 then
          begin
            len:=ImmGetCompositionStringW(IMC,GCS_RESULTSTR,@buffer[0],sizeof(buffer)-sizeof(WideChar));
            if len>0 then
              len := len shr 1;
            buffer[len]:=#0;
            buf:=buf+buffer;
            LastImeLen:=0;
          end;
          { insert composition string }
          if imeCode and IME_COMPFLAG<>0 then begin
            len:=ImmGetCompositionStringW(IMC,GCS_COMPSTR,@buffer[0],sizeof(buffer)-sizeof(WideChar));
            if len>0 then
              len := len shr 1;
            buffer[len]:=#0;
            buf:=buf+buffer;
            LastImeLen:=len;
          end;
          { print string }
          PaintBox1.Canvas.TextOut(1,1,UTF8Encode(buf+'  '));
        end;
    finally
      ImmReleaseContext(Form1.Handle,IMC);
    end;
  end;
  Msg.Result:= -1;
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

