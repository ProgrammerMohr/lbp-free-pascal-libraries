unit gpg_cb_clipboard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons;

type

  { TCryptEditForm }

  TCryptEditForm = class(TForm)
     ComboBox1: TComboBox;
     CryptBtn: TButton;
     EditBox: TMemo;
     MenuBtn: TSpeedButton;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  CryptEditForm: TCryptEditForm;

implementation

{$R *.lfm}

end.

