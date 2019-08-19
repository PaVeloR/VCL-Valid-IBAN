unit IBAN_Funcs;

interface

uses
  Classes;

type
  // Funciones Genericas
  TIBANFuncs = class
  public
    class function GetNumbersOnly(value: string): string;
    class function GetAlphaNumericsOnly(value: string): string;

    class function Mod97(value: String): Integer;

    class procedure AddNotNil(value: string; Lista: TStrings=nil);
  end;

implementation

uses
  SysUtils;

{ TIBANFuncs }

class function TIBANFuncs.GetNumbersOnly(value: string): string;

  function IsNumber(Caracter: Char): Boolean;
  begin
     Result := Caracter in ['0'..'9'];
  end;

  var
  i: Integer;
begin
  Result := '';

  Value := Trim(Value);
  for i:=1 to Length(Value) do
  begin
     if IsNumber(Value[i]) then
        Result := Result + Value[i];
  end;
end;

class function TIBANFuncs.GetAlphaNumericsOnly(value: string): string;

  function IsAlphaNumeric(Caracter: Char): Boolean;
  begin
     Result := (Caracter in ['A'..'Z']) or
               (Caracter in ['a'..'z']) or
               (Caracter in ['0'..'9']);
  end;

var
  i: Integer;
begin
  Result := '';

  Value := Trim(Value);
  for i:=1 to Length(Value) do
  begin
     if IsAlphaNumeric(Value[i]) then
        Result := Result + Value[i];
  end;
end;

class function TIBANFuncs.Mod97(value: String): Integer;
begin
  Result := 0;
  while Length(value) > 0 do
  begin
     Result := StrToIntDef(IntToStr(Result) + Copy(value,1,6), 0) mod 97;
     Delete(value,1,6);
  end;
end;

class procedure TIBANFuncs.AddNotNil(value: string; Lista: TStrings=nil);
begin
  if Assigned(Lista) then
     Lista.Add(value);
end;

end.
