unit IBAN_Types;

interface

uses
  Classes;

type
  //{$REGION 'Doc'}
  /////////////////////////////////////////////////////////////////////////////////
  // Doc IBAN:
  //	   https://es.wikipedia.org/wiki/International_Bank_Account_Number
  //	   http://www.lasexta.com/tecnologia-tecnoxplora/ciencia/divulgacion/iban-asi-calculan-numeros-cuenta-bancaria_2014020957fca03d0cf2fd8cc6b0e1a2.html
  //
  // Ejemplos de IBAN:
  //	   https://www.iban.es/ejemplos.html
  //
  // Validador IBAN Online:
  //	   http://es.ibancalculator.com/iban_validieren.html
  /////////////////////////////////////////////////////////////////////////////////
  //    IBAN Completo.: ES1720852066623456789011
  //    IBAN Deglosado: ES17 + 2085    + 2066    + 62 + 34 5678 9011
  //                    IBAN + Entidad + Oficina + DC + Cuenta
  //                          [-------------CCC-ESP----------------]
  /////////////////////////////////////////////////////////////////////////////////
  //    IBAN...: ES17 ("ES" = 2 digitos pais, "17" Digito verificador de toda la CCC)
  //    Entidad: 2085
  //    Oficina: 2066
  //    DC.....: 62
  //    Cuenta.: 3456789011
  /////////////////////////////////////////////////////////////////////////////////
  //    BIC....: ?? Pendiente
  //    SWIFT..: ?? Pendiente
  /////////////////////////////////////////////////////////////////////////////////
  //{$ENDREGION}

  { Info Bancaria de la Cuenta. Generico para UE }
  TrBancoCuentaInfo = record
    IBAN: string; // size(4)                             // Codigo del Pais (ISO 3166-1) + Digito verificador
    CCC: string;  // size(Varia Segun Pais), maxsize(30) // En el caso de España (Entidad + Oficina + DC + Cuenta).

    // HELPERs
  end;

  function TrBancoCuentaInfo_ToFull(var Self: TrBancoCuentaInfo; Sep:string=''): string; // IBAN Completo (ES1720852066623456789011) IBAN-ESP: maxsize(24) | IBAN:maxsize(34)
  function TrBancoCuentaInfo_ToFormatPapel(var Self: TrBancoCuentaInfo): string;
  function TrBancoCuentaInfo_ToFormatElect(var Self: TrBancoCuentaInfo): string;

  function TrBancoCuentaInfo_Build(inIBAN, inCCC: string):TrBancoCuentaInfo; overload;
  function TrBancoCuentaInfo_Build(inFull: string): TrBancoCuentaInfo; overload;
  function TrBancoCuentaInfo_BuildESP(inIBAN, inEntidad, inOficina, inDC, inCuenta: string): TrBancoCuentaInfo;

type
  { Info Bancaria del Codigo del Pais, IBAN = "International Bank Account Number" }
  TrBancoIBANInfo = record
    Pais: string;
    DC: string;

    // HELPERs
  end;

  function TrBancoIBANInfo_ToIBAN(var Self: TrBancoIBANInfo): string;

  function TrBancoIBANInfo_Build(inPais, inDC: string): TrBancoIBANInfo; overload;
  function TrBancoIBANInfo_Build(inIBAN: string): TrBancoIBANInfo; overload;
  function TrBancoIBANInfo_BuildEmpty(inPais: string): TrBancoIBANInfo; overload;

  function TrBancoIBANInfo_GetDigitoControl(var Self: TrBancoIBANInfo; inCCC: string): string;
  function TrBancoIBANInfo_IsValid(var Self: TrBancoIBANInfo; inCCC: String; Errores: TStrings=nil): Boolean;

type
  { Info del CCC = "Código Cuenta Cliente" Española }
  TrBancoCCCInfoESP = record
    Entidad: string;
    Oficina: string;
    DC: string;
    Cuenta: string;

    // HELPERs
  end;

  function TrBancoCCCInfoESP_ToCCC(var Self: TrBancoCCCInfoESP; Sep:string=''): string;
  function TrBancoCCCInfoESP_Build(inEntidad, inOficina, inDC, inCuenta: string): TrBancoCCCInfoESP; overload;
  function TrBancoCCCInfoESP_Build(inCCC: string): TrBancoCCCInfoESP; overload;


implementation

uses
  SysUtils,
  Iban_Funcs;

const
  _PrefixFormatPapelIBAN = 'IBAN';

resourcestring
  IBANInvalidoStr = 'IBAN Inválido';
  PaisIBANInvalidoStr = 'Pais del IBAN Inválido';
  DcIBANInvalidoStr = 'Digito Control del IBAN Inválido';

{ TrBancoCuentaInfo }

function TrBancoCuentaInfo_AddPrefixPapelIBAN(var Self: TrBancoCuentaInfo; Value: string): string; forward;
function TrBancoCuentaInfo_DelPrifixPapelIBAN({var Self: TrBancoCuentaInfo; }Value: string): string; forward;

function TrBancoIBANInfo_PaisToIBANTable(var Self: TrBancoIBANInfo; inPais: string): string; forward;
function TrBancoIBANInfo_ToIBAN_Table(var Self: TrBancoIBANInfo): string; forward;
function TrBancoIBANInfo_GetStrAValidar(var Self: TrBancoIBANInfo; inCCC: string): string; forward;

function TrBancoIBANInfo_IsValid_Pais(var Self: TrBancoIBANInfo; inPais: string): Boolean; forward;
function TrBancoIBANInfo_IsValid_DC(var Self: TrBancoIBANInfo; inCCC: String; Errores: TStrings=nil): Boolean; forward;
function TrBancoIBANInfo_IsValid_Base(var Self: TrBancoIBANInfo; Errores: TStrings=nil): Boolean; forward;



function TrBancoCuentaInfo_AddPrefixPapelIBAN(var Self: TrBancoCuentaInfo; Value: string): string;
begin
  Result := _PrefixFormatPapelIBAN + ' ' + Trim(Value);
end;

function TrBancoCuentaInfo_DelPrifixPapelIBAN({var Self: TrBancoCuentaInfo; }Value: string): string;
var
  AValue: string;
  Prefix: string;
  PrefixSize: Integer;
begin
  Result := Value;

  // Del Prefix IBAN
  AValue     := Trim(Value);
  PrefixSize := Length(_PrefixFormatPapelIBAN);
  Prefix     := Copy(AValue, 1, PrefixSize);

  if SameText(Prefix, _PrefixFormatPapelIBAN) then //Si tiene el prefijo lo quitamos.
  begin
     Result := Copy(AValue, PrefixSize+1, Length(AValue));
     Result := Trim(Result);
  end;
end;

function TrBancoCuentaInfo_ToFull(var Self: TrBancoCuentaInfo; Sep:string=''): string;
begin
  Result := Trim(Self.IBAN) + Sep +
            Trim(Self.CCC);
end;

function TrBancoCuentaInfo_ToFormatElect(var Self: TrBancoCuentaInfo): string;
begin
  Result := TrBancoCuentaInfo_ToFull(Self);
end;

function TrBancoCuentaInfo_ToFormatPapel(var Self: TrBancoCuentaInfo): string;
begin
  // Add Prefix IBAN
  Result := TrBancoCuentaInfo_AddPrefixPapelIBAN(Self, TrBancoCuentaInfo_ToFull(Self, ' ') );
end;

function TrBancoCuentaInfo_Build(inIBAN, inCCC: string): TrBancoCuentaInfo;
begin
  Result.IBAN := inIBAN;
  Result.CCC  := inCCC;
end;

function TrBancoCuentaInfo_Build(inFull: string): TrBancoCuentaInfo;
var
  Value: string;
begin
  // Clean
  Value := inFull;
  Value := TrBancoCuentaInfo_DelPrifixPapelIBAN(Value);
  Value := TIBANFuncs.GetAlphaNumericsOnly(Value);

  // Separa
  Result.IBAN := Copy(Value, 1, 4);
  Result.CCC  := Copy(Value, 5, Length(Value)); //El restante es el CCC
end;

function TrBancoCuentaInfo_BuildESP(inIBAN, inEntidad, inOficina, inDC, inCuenta: string): TrBancoCuentaInfo;
var
  CCCFull: string;
  tmp: TrBancoCCCInfoESP;
begin
  tmp := TrBancoCCCInfoESP_Build(inEntidad, inOficina, inDC, inCuenta);
  CCCFull := TrBancoCCCInfoESP_ToCCC(tmp);
  Result := TrBancoCuentaInfo_Build(inIBAN, CCCFull);
end;

{ TrBancoIBANInfo }

function TrBancoIBANInfo_PaisToIBANTable(var Self: TrBancoIBANInfo; inPais: string): string;

  function CharToDigitTable(const Value: Char): string;
  const
    Initial_A: char = 'A';
  var
    iValue: byte;
  begin
    ////////////////////////////////////////////////////////////////////////////////////////
    // Cambias las letras que queden a numeros segun esta tabla:
    //  A=10, B=11, C=12, D=13, E=14, F=15, G=16, H=17, I=18, J=19, K=20, L=21, M=22,
    //  N=23, O=24, P=25, Q=26, R=27, S=28, T=29, U=30, V=31, W=32, X=33, Y=34, Z=35
    ////////////////////////////////////////////////////////////////////////////////////////
    Result := Value;

    if (Value in ['A'..'Z']) then
    begin
       iValue := (byte(Value) - byte(Initial_A)) + 10;
       result := IntToStr(iValue);
    end;
  end;

var
  i: Integer;
  Valor: string;
begin
  Result := '';
  inPais := AnsiUpperCase(inPais);
  for i:=1 to Length(inPais) do
  begin
     Valor  := CharToDigitTable(inPais[i]);
     Result := Result + Valor;
  end;
end;

function TrBancoIBANInfo_ToIBAN(var Self: TrBancoIBANInfo): string;
begin
  Result := Self.Pais + Self.DC;
end;

function TrBancoIBANInfo_ToIBAN_Table(var Self: TrBancoIBANInfo): string;
begin
  Result := TrBancoIBANInfo_PaisToIBANTable(Self, Self.Pais) + Self.DC;
end;

function TrBancoIBANInfo_Build(inPais, inDC: string): TrBancoIBANInfo;
begin
  Result.Pais := inPais;
  Result.DC   := inDC;
end;

function TrBancoIBANInfo_Build(inIBAN: string): TrBancoIBANInfo;
begin
  // Ej: "ES78"
  inIBAN := Trim(inIBAN);
  Result.Pais := Copy(inIBAN, 1, 2);
  Result.DC   := Copy(inIBAN, 3, 4);
end;

function TrBancoIBANInfo_BuildEmpty(inPais: string): TrBancoIBANInfo;
begin
  Result.Pais := inPais;
  Result.DC   := '00';
end;

function TrBancoIBANInfo_GetStrAValidar(var Self: TrBancoIBANInfo; inCCC: string): string;
begin
  Result := Trim(inCCC) + TrBancoIBANInfo_ToIBAN_Table(Self);
end;

function TrBancoIBANInfo_GetDigitoControl(var Self: TrBancoIBANInfo; inCCC: string): string;
var
  AValidar: string;
  iValue: Integer;
  NewDV: Integer;
begin
  //{$REGION 'Doc_Calc_DC_IBAN'}
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Calculo del DC del IBAN
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //   1) Tomas el numero de cuenta sin espacios ni guiones ni nada (ejemplo aleman, sin digitos de control) :
  //      370400440532013000
  //
  //   2) A�ades al final el pais y digitos de control vacios 00 ('ES00' � 'DE00' en el ejemplo):
  //      370400440532013000DE00
  //
  //   3) Cambias las letras que queden a numeros segun esta tabla:
  //      A=10, B=11, C=12, D=13, E=14, F=15, G=16, H=17, I=18, J=19, K=20, L=21, M=22,
  //      N=23, O=24, P=25, Q=26, R=27, S=28, T=29, U=30, V=31, W=32, X=33, Y=34, Z=35
  //
  //      370400440532013000DE00 se convierte en 370400440532013000131400
  //
  //   4) 370400440532013000131400 mod 97 = 9
  //
  //   5) 98 - 9 = 89
  //      Al final quedaria asi: DE89 37040044 0532013000
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //{$ENDREGION}

  AValidar := TrBancoIBANInfo_GetStrAValidar(Self, inCCC);
  iValue   := TIBANFuncs.Mod97(AValidar);
  NewDV    := 98 - iValue;

  if NewDV < 10 then //Solo para asegurar que tengas 2 digitos.
     Result := '0' + IntToStr(NewDV)
  else
     Result := IntToStr(NewDV);
end;

function TrBancoIBANInfo_IsValid_DC(var Self: TrBancoIBANInfo; inCCC: String; Errores: TStrings=nil): Boolean;
var
  AValidar: string;
begin
  // Generamos la linea para validar
  AValidar := TrBancoIBANInfo_GetStrAValidar(Self, inCCC);

  // Valida
  Result := TIBANFuncs.Mod97(AValidar) = 1;

  if (not Result) then
     TIBANFuncs.AddNotNil(IBANInvalidoStr, Errores);
end;

function TrBancoIBANInfo_IsValid_Pais(var Self: TrBancoIBANInfo; inPais: string): Boolean;

  function IsStringOnly(Caracter: Char): Boolean;
  begin
     Result := (Caracter in ['A'..'Z']) or
               (Caracter in ['a'..'z']);
  end;

var
  i: Integer;
begin
  Result := True;
  for i:=1 to Length(inPais) do
  begin
     if not IsStringOnly(inPais[i]) then
     begin
        Result := False;
        Break;
     end;
  end;
end;

function TrBancoIBANInfo_IsValid_Base(var Self: TrBancoIBANInfo; Errores: TStrings): Boolean;
begin
  Result := True;

  if (Self.Pais = '') or (Length(Self.Pais) < 2) or (not TrBancoIBANInfo_IsValid_Pais(Self, Self.Pais)) then // Tiene que ser solo letras
  begin
     TIBANFuncs.AddNotNil(PaisIBANInvalidoStr, Errores);
     Result := False;
  end;

  if (Self.DC = '') or (Length(Self.DC) < 2) or (StrToIntDef(Self.DC, -1) = -1) then //Tiene que ser Integer
  begin
     TIBANFuncs.AddNotNil(DcIBANInvalidoStr, Errores);
     Result := False;
  end;
end;

function TrBancoIBANInfo_IsValid(var Self: TrBancoIBANInfo; inCCC: String; Errores: TStrings=nil): Boolean;
begin
  if TrBancoIBANInfo_IsValid_Base(Self, Errores) and
     TrBancoIBANInfo_IsValid_DC(Self, inCCC, Errores) then
  begin
     Result := True;
  end
  else
  begin
     Result := False;
  end;
end;

{ TrBancoCCCInfoESP }

function TrBancoCCCInfoESP_ToCCC(var Self: TrBancoCCCInfoESP; Sep:string=''): string;
begin
  Result := Self.Entidad + Sep +
            Self.Oficina + Sep +
            Self.DC      + Sep +
            Self.Cuenta;
end;

function TrBancoCCCInfoESP_Build(inEntidad, inOficina, inDC, inCuenta: string): TrBancoCCCInfoESP;
begin
  Result.Entidad := inEntidad;
  Result.Oficina := inOficina;
  Result.DC      := inDC;
  Result.Cuenta  := inCuenta;
end;

function TrBancoCCCInfoESP_Build(inCCC: string): TrBancoCCCInfoESP;
var
  Value: string;
begin
  Value := TIBANFuncs.GetNumbersOnly(inCCC);

  Result.Entidad := Copy(Value, 1 , 4);
  Result.Oficina := Copy(Value, 5 , 4);
  Result.DC      := Copy(Value, 9 , 2);
  Result.Cuenta  := Copy(Value, 11, Length(Value));
end;

end.
