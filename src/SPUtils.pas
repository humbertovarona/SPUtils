unit SP_Utils;

interface

Uses
  Windows, Classes;

type
   TArrCOMString = Array [0..50] of String;

function get_ListOfVirtualSerialPorts(var VCOMList :  TArrCOMString) : byte;
function get_ListOfPhysicalSerialPorts(var VCOMList :  TArrCOMString) : byte;
function get_ListOfAllSerialPorts(var VCOMList :  TArrCOMString) : byte;
function IsCOMPortActive(StrCOM : String; VCOMList :  TArrCOMString) : boolean;
function IsActiveSerialPort(activePort : String) : boolean;

implementation

Uses
  OS_Functions, SysUtils, Registry;

function get_COMSublist(var VCOMList :  TArrCOMString; IdCOM : String; InitNumberSerialPorts : byte; TopLimit : byte; Reg : TRegistry) : byte;
var
  iCOMPort, LastInitNumberSerialPorts : byte;
  StrVCOM : String;
begin
  LastInitNumberSerialPorts := InitNumberSerialPorts;
  for iCOMPort:=0 to TopLimit do
    begin
      StrVCOM := '\Device\' + IdCOM + inttostr(iCOMPort);
      if Reg.ValueExists(StrVCOM) then
        begin
          inc(InitNumberSerialPorts);
          VCOMList[InitNumberSerialPorts-1]:=Reg.ReadString(StrVCOM);
        end
     end;
  Result := (InitNumberSerialPorts -  LastInitNumberSerialPorts);
end;

function get_COMSublist2(var VCOMList :  TArrCOMString; IdCOM : String; InitNumberSerialPorts : byte; TopLimit : byte; Reg : TRegistry) : byte;
var
  iCOMPort, LastInitNumberSerialPorts : byte;
  StrVCOM : String;
begin
  LastInitNumberSerialPorts := InitNumberSerialPorts;
  for iCOMPort:=0 to TopLimit do
    begin
      if iCOMPort< 10 then
        StrVCOM := '\Device\' + IdCOM + '00' + inttostr(iCOMPort)
      else
        StrVCOM := '\Device\' + IdCOM + '0' + inttostr(iCOMPort);
      if Reg.ValueExists(StrVCOM) then
        begin
          inc(InitNumberSerialPorts);
          VCOMList[InitNumberSerialPorts-1]:=Reg.ReadString(StrVCOM);
        end
    end;
  Result := (InitNumberSerialPorts -  LastInitNumberSerialPorts);
end;

function get_ListOfVirtualSerialPorts(var VCOMList :  TArrCOMString) : byte;

var
  iCOMPort, NumberOfVirtualSerialPorts : byte;
  Reg : TRegistry;
  StrVCOM : String;

  begin
  NumberOfVirtualSerialPorts := 0;
  if Is64BitOS then
    Reg:= TRegistry.Create(KEY_READ)
  else
    Reg:= TRegistry.Create;
  Reg.rootKey:=HKEY_LOCAL_MACHINE;
  Reg.OpenKey('HARDWARE\DEVICEMAP\SERIALCOMM', False);

  NumberOfVirtualSerialPorts := NumberOfVirtualSerialPorts + get_COMSublist(VCOMList, 'VSerial7_', 0, 40, Reg);
  NumberOfVirtualSerialPorts := NumberOfVirtualSerialPorts + get_COMSublist(VCOMList, 'VSerial8_', NumberOfVirtualSerialPorts, 40, Reg);
  NumberOfVirtualSerialPorts := NumberOfVirtualSerialPorts + get_COMSublist(VCOMList, 'VSerial9_', NumberOfVirtualSerialPorts, 40, Reg);
  NumberOfVirtualSerialPorts := NumberOfVirtualSerialPorts + get_COMSublist(VCOMList, 'com0com', NumberOfVirtualSerialPorts, 40, Reg);

  Reg.CloseKey;
  Reg.Free;
  Result := NumberOfVirtualSerialPorts;
end;


function get_ListOfPhysicalSerialPorts(var VCOMList :  TArrCOMString) : byte;

var
  iCOMPort, NumberOfPhysicalSerialPorts : byte;
  Reg : TRegistry;
  StrVCOM : String;

begin
  NumberOfPhysicalSerialPorts := 0;
  if Is64BitOS then
    Reg:= TRegistry.Create(KEY_READ)
  else
    Reg:= TRegistry.Create;
  Reg.rootKey:=HKEY_LOCAL_MACHINE;
  Reg.OpenKey('HARDWARE\DEVICEMAP\SERIALCOMM', False);

  NumberOfPhysicalSerialPorts := NumberOfPhysicalSerialPorts + get_COMSublist(VCOMList, 'Serial', 0, 19, Reg);
  NumberOfPhysicalSerialPorts := NumberOfPhysicalSerialPorts + get_COMSublist(VCOMList, 'UBLOXUSBPort', NumberOfPhysicalSerialPorts, 19, Reg);
  NumberOfPhysicalSerialPorts := NumberOfPhysicalSerialPorts + get_COMSublist2(VCOMList, 'USBSER', NumberOfPhysicalSerialPorts, 19, Reg);
  
  Reg.CloseKey;
  Reg.Free;
  Result := NumberOfPhysicalSerialPorts;
end;

function get_ListOfAllSerialPorts(var VCOMList :  TArrCOMString) : byte;

var
  iCOMPort, NumberOfSerialPorts : byte;
  Reg : TRegistry;
  StrVCOM : String;

begin
  NumberOfSerialPorts := 0;
  if Is64BitOS then
    Reg:= TRegistry.Create(KEY_READ)
  else
    Reg:= TRegistry.Create;
  Reg.rootKey:=HKEY_LOCAL_MACHINE;
  Reg.OpenKey('HARDWARE\DEVICEMAP\SERIALCOMM', False);

  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist(VCOMList, 'Serial', 0, 30, Reg);
  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist(VCOMList, 'UBLOXUSBPort', NumberOfSerialPorts, 19, Reg);
  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist2(VCOMList, 'USBSER', NumberOfSerialPorts, 19, Reg);
  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist(VCOMList, 'VSerial7_', NumberOfSerialPorts, 40, Reg);
  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist(VCOMList, 'VSerial8_', NumberOfSerialPorts, 40, Reg);
  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist(VCOMList, 'VSerial9_', NumberOfSerialPorts, 40, Reg);
  NumberOfSerialPorts := NumberOfSerialPorts + get_COMSublist(VCOMList, 'com0com', NumberOfSerialPorts, 40, Reg);

  
  Reg.CloseKey;
  Reg.Free;
  Result := NumberOfSerialPorts;
end;

function IsCOMPortActive(StrCOM : String; VCOMList :  TArrCOMString) : boolean;
var
  iCOM : byte;
begin
  Result := false;
  for iCOM:=low(VCOMList) to high(VCOMList) do
    if Pos(StrCOM, VCOMList[iCOM]) > 0 then
      begin
        Result:=true;
        break;
      end
end;

function IsActiveSerialPort(activePort : String) : boolean;
var
  Reg : TRegistry;
  ValueNames : TStringList;
  i : integer;
  SerialPort : String;
begin
  Result := false;
  ValueNames := TStringList.Create;
  if Is64BitOS then
    Reg:= TRegistry.Create(KEY_READ)
  else
    Reg:= TRegistry.Create;
  Reg.rootKey:=HKEY_LOCAL_MACHINE;
  Reg.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM');
  Reg.GetValueNames(ValueNames);
  If ValueNames.Count > 0 then
   for i := 0 to ValueNames.Count - 1 do
      begin
         SerialPort := Reg.ReadString(ValueNames[i]);
          if SerialPort = activePort then
		    begin
              Result := true;
			  break
			end
      end
  else
    Result := false;
  ValueNames.Free;
  Reg.CloseKey;
  Reg.Free;
end;

end.
