unit IBAN_Utils;

interface

uses
  Classes;

function GetIBAN(inSiglaPais, inCCC: AnsiString): AnsiString;

//UA
function GetIBanFromUAAccount(Mfo: AnsiString; Acc: AnsiString): AnsiString;

type
  TUABankAccount = record
    MFO: AnsiString;
    Account: AnsiString;
  end;

function GetUaAccountFromIBan(aValue: AnsiString): TUABankAccount;

    // Valida un IBAN (Generico todos los paises UE)
function IsValidIBAN(inFull: AnsiString; Errores: TStrings=nil): Boolean;

implementation

uses
  SysUtils,
  Iban_Types;

{ TIBANUtils }

function GetIBAN(inSiglaPais, inCCC: AnsiString): AnsiString;
var
  IBAN: TrBancoIBANInfo;
begin
  IBAN := TrBancoIBANInfo_BuildEmpty(inSiglaPais);
  IBAN.DC := TrBancoIBANInfo_GetDigitoControl(IBan, inCCC);

  Result := TrBancoIBANInfo_ToIBAN(IBan);
end;

function GetIBanFromUAAccount(Mfo, Acc: AnsiString): AnsiString;
var
  S: AnsiString;
begin
  SetLength(S, 25);
  FillChar(S[1], 25, '0');
  if Length(Mfo) > 0 then
    Move(Mfo[1], S[1], Length(Mfo));
  if Length(Acc) > 0 then
    Move(Acc[1], S[Length(S) - Length(Acc) + 1], Length(Acc));
  Result := GetIBAN('UA', S) + S;
end;

function GetUaAccountFromIBan(aValue: AnsiString): TUABankAccount;
var
  s: AnsiString;
  i: integer;
begin
  aValue := Trim(aValue);
  if UpperCase(Copy(aValue, 1, 2)) <> 'UA' then
    raise Exception.Create('GetUaAccountFromIBan: IBan is not Ukrainian');
  if Length(aValue) <> 29 then
    raise Exception.Create('GetUaAccountFromIBan: Invalid Ukrainian IBan Length');

  if not IsValidIBAN(aValue) then
    raise Exception.Create('GetUaAccountFromIBan: Invalid IBan checksum');

  s := copy(aValue, 5, Length(aValue));
  Result.MFO := copy(aValue, 5, 6);
  for i := 11 to Length(aValue) do
    if aValue[i] <> '0' then begin
      Result.Account := copy(aValue, i, Length(aValue));
      break;
    end;
end;

function IsValidIBAN(inFull: AnsiString; Errores: TStrings=nil): Boolean;
var
  Cuenta: TrBancoCuentaInfo;
  IBAN: TrBancoIBANInfo;
begin
  // Descomponemos la cuenta
  Cuenta := TrBancoCuentaInfo_Build(inFull);

  // Descomponemos el IBAN
  IBAN := TrBancoIBANInfo_Build(Cuenta.IBAN);

  // Valida
  Result := TrBancoIBANInfo_IsValid(IBAN, Cuenta.CCC, Errores);
end;

end.
