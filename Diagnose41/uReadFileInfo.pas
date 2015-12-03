unit uReadFileInfo;

interface
uses Classes;
function GetFirstSubStr(var SubStr,InputStr:string;Delimiter:char):boolean;
function TranslateToValidNumber(InputStr:string):String;
function AlreadyExist(NewItems:string;Destination:TStrings):boolean;
//function 

implementation

function GetFirstSubStr(var SubStr,InputStr:string;Delimiter:char):boolean;
var TempStr:string;
    PosSpl:integer;
begin
if (Length(InputStr)>=1) then Result:=True else Result:=False;
if Result then
 begin
  PosSpl:=Pos(Delimiter,InputStr);
  if (PosSpl=0) and (Delimiter=#9) then PosSpl:=length(InputStr)+1;
  if PosSpl = 0 then begin Result:=False; exit; end;
  SubStr:=Copy(InputStr,1,PosSpl-1);
  SetLength(TempStr,Length(InputStr));
  TempStr:=InputStr;
  SetLength(InputStr,Length(TempStr)-PosSpl);
  InputStr:=Copy(TempStr,PosSpl+1,Length(InputStr));
 end;

end;

function TranslateToValidNumber(InputStr:string):String;
var i:integer;
    s:string;
  begin
    s:='';
   for i:=1 to Length(InputStr) do
     if (ord(InputStr[i])>43) and (ord(InputStr[i])< 70) then s:=s+InputStr[i];
    if s<>'' then REsult:=s else
    Result:='0';
  end;

function AlreadyExist(NewItems:string;Destination:TStrings):boolean;
var i:integer;
begin
Result:=False;
 for i:=0 to Destination.Count-1 do
  if Destination[i] = NewItems then result:=True; 
end;

end.
