unit IBAN_Utils;

interface

uses
  Classes;

type
  TIBANUtils = class
  public
    // Genera un IBAN para una CCC. EJ: "ES17"
    class function GetIBAN(inSiglaPais, inCCC: string): string;

    class function GetUAIBan(Mfo: string; Acc: string): string;

    // Valida un IBAN (Generico todos los paises UE)
    class function IsValidIBAN(inFull: String; Errores: TStringList=nil): Boolean;
  end;

implementation

uses
  SysUtils,
  Iban_Types;

{ TIBANUtils }

class function TIBANUtils.GetIBAN(inSiglaPais, inCCC: string): string;
var
  IBAN: TrBancoIBANInfo;
begin
  IBAN := TrBancoIBANInfo_BuildEmpty(inSiglaPais);
  IBAN.DC := TrBancoIBANInfo_GetDigitoControl(IBan, inCCC);

  Result := TrBancoIBANInfo_ToIBAN(IBan);
end;

class function TIBANUtils.GetUAIBan(Mfo, Acc: string): string;
var
  S: string;
begin
  SetLength(S, 25);
  FillChar(S[1], 25, '0');
  if Length(Mfo) > 0 then
    Move(Mfo[1], S[1], Length(Mfo));
  if Length(Acc) > 0 then
    Move(Acc[1], S[Length(S) - Length(Acc) + 1], Length(Acc));
  Result := TIBANUtils.GetIBAN('UA', S) + S;
end;

class function TIBANUtils.IsValidIBAN(inFull: String; Errores: TStringList=nil): Boolean;
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
