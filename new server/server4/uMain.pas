unit uMain;
//------------------------------------------------------------------------------
//�������� ������ ���� ��� ����������� mbcli.dll - ������ ������ ������
//22.02.2013 �����: ��������� �.�.
//16.07.2014 - ����������� - ������� ���������� ������ ����� ������
//------------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,ScktComp,ComCtrls, TeeProcs, TeEngine,
   Chart, Series, TeeTools,
  //���� ������������ ���������� ���� units
  uFEP_File,uCommon, Grids,uStringOperation,uNetSend,log4d;

type
  TfMain = class(TForm)
    bbOpen: TBitBtn;
    Timer: TTimer;
    OpenDialog: TOpenDialog;
    pbLoading: TProgressBar;
    lStart: TLabel;
    lEnd: TLabel;
    lCur: TLabel;
    Label1: TLabel;
    cbParam: TComboBox;
    Chart: TChart;
    Series1: TLineSeries;
    ChartTool1: TCursorTool;
    lProcess: TLabel;
    sgModeBus: TStringGrid;
    Memo1: TMemo;
    ServerSocket: TServerSocket;
    lValue: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure bbOpenClick(Sender: TObject);
    procedure cbParamChange(Sender: TObject);
    procedure ChartTool1Change(Sender: TCursorTool; x, y: Integer;
      const XValue, YValue: Double; Series: TChartSeries;
      ValueIndex: Integer);
    procedure ServerSocketClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ServerSocketClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);

  private

    { Private declarations }
  public
    { Public declarations }
     Params:TStrings;
     IndexArray:array of integer;
     CountIndex:integer;
     procedure Subscribe;
     function SendValues():String;
     procedure GetParams(s:string);
     procedure SendParams(s:string);
  end;
  TParam = record
      Id:integer;
      value:real;
      time:string;
      status:integer;
      end;
var
  fMain: TfMain;
  FEPFile:TFEPFile;
  Data: TValueArray;
  SendData:TSendData;
  ReadFileInfo:TReadFileInfo;
  FilesFormatSettings:TFormatSettings;
  CurPosition:double;// ������� ��������� �� ����� �������
  PATH:string;
  TXT,Codes:TextFile;
  logger:TLogLogger;
  Busher_NV2:array of array [0..3] of String;
  procedure GetLastTimeValues(CurPosition:double);

  procedure ShowLastValues;
  procedure LoadKKS;

implementation


{$R *.dfm}

procedure TfMain.FormCreate(Sender: TObject);
begin
  path:=ExtractFilePath(Application.ExeName);

  AssignFile(TXT,PATH+'\ExpFile.txt');

  AssignFile(Codes,PATH+'\Codes.txt');

       TLogBasicConfigurator.Configure;
     TLogLogger.GetRootLogger.Level:= All;
     logger := TLogLogger.GetLogger('myLogger');
     logger.AddAppender(TLogFileAppender.Create('filelogger','log4d.log'));
     //logger.Debug('initializing logging');

  LoadKKS;
  Params:=TStringList.Create;
  SendData:=TSendData.Create;
  ServerSocket.Active:=True;

end;

procedure TfMain.TimerTimer(Sender: TObject);
var i:integer;
begin
 CurPosition:=CurPosition+1;
 if CurPosition>pbLoading.Max then
 begin
   Timer.Enabled:=False;
   MessageDlg('������ �����������!',mtInformation,[mbOk],0);
 end;
 ChartTool1.XValue:=CurPosition;
 GetLastTimeValues(CurPosition);
 if SendData.Initilized then
  begin
   SendData.NewSendData(Data);
   Memo1.Lines.Add(IntToStr(ServerSocket.Socket.ActiveConnections));
  end;
 lCur.Caption:='�����. �����: '+intToStr(Round(ChartTool1.xvalue));
 ShowLastValues;

 lValue.Caption:=SendData.SendStr;
end;

procedure TfMain.bbOpenClick(Sender: TObject);
var i,j,k,Count:integer;
    FieldFepInfo:TFieldFEPInfo;
Found:boolean;
begin
if OpenDialog.Execute then
begin
// set up euro date time format
    GetLocaleFormatSettings(sysutils.Languages.LocaleID[0],FilesFormatSettings);
     FilesFormatSettings.LongDateFormat:='dd.mm.yyyy';
     FilesFormatSettings.ShortDateFormat:='dd.mm.yy';
     FilesFormatSettings.LongTimeFormat:= 'hh:mm:ss.zzz';
     FilesFormatSettings.ShortTimeFormat:= 'hh:mm:ss.zzz';
     FilesFormatSettings.DecimalSeparator:='.';
     FilesFormatSettings.DateSeparator:='.';
     FilesFormatSettings.TimeSeparator:=':';
 
// ---------
 lProcess.Caption:='�������� '+inttoStr(OpenDialog.Files.Count)+' ������';
 ReadFileInfo:=TReadFileInfo.Create;
 FEPFile:=TFEPFile.Create;
 for i:=0 to OpenDialog.Files.Count-1 do
 ReadFileInfo.Add(OpenDialog.Files.Strings[i]);
 for i:=0 to ReadFileInfo.CountFiles-1 do
  for j:=0 to ReadFileInfo.FileInfo[i].CountFields-1 do
  begin
   k:=0;
  while (k<(Length(Busher_NV2)-1)) and (Busher_NV2[k][0]<>ReadFileInfo.FileInfo[i].FieldInfo[j].KKS) do inc(k);
  if (Busher_NV2[k][0]=ReadFileInfo.FileInfo[i].FieldInfo[j].KKS) then
  begin
   FieldFepInfo:= ReadFileInfo.FileInfo[i].FieldInfo[j];
   FieldFepInfo.Checked:=True;
   ReadFileInfo.FileInfo[i].FieldInfo[j]:=FieldFepInfo;
  end;
  end;
// ReadFileInfo.CheckAll;
 FEPFile.LoadFiles(ReadFileInfo,pbLoading);
 pbLoading.Max:=Round((FEPFile.EndTime-FEPFile.StartTime)*86400);
 SetLength(Data,FEPFile.CountFields);
 sgModeBus.RowCount:=FEPFile.CountFields+1;
 for i:=1 to sgModeBus.RowCount-1 do
 sgModeBus.Rows[i].Clear;
 sgModeBus.Cells[0,0]:='��������';
 sgModeBus.Cells[1,0]:='KKS �����';
 sgModeBus.Cells[2,0]:='KKS �����-2';
 sgModeBus.Cells[3,0]:='������������';
 sgModeBus.Cells[4,0]:='��. ���.';
 for i:=0 to FEPFile.CountFields-1 do
 begin
  sgModeBus.Cells[1,i+1]:=FEPFile.Data[i].FieldInfo.KKS;
//  sgModeBus.Cells[2,i+1]:=FEPFile.Data[i].FieldInfo.Name;
  j:=0;
  while (j<(Length(Busher_NV2)-1)) and (Busher_NV2[j][0]<>sgModeBus.Cells[1,i+1]) do inc(j);
  if Busher_NV2[j][0]=sgModeBus.Cells[1,i+1] then
   begin
    sgModeBus.Cells[2,i+1]:=Busher_NV2[j][1];
    sgModeBus.Cells[3,i+1]:=Busher_NV2[j][2];
    sgModeBus.Cells[4,i+1]:=Busher_NV2[j][3];
   end;
 end;
 Rewrite(Codes);
 for i:=0 to FEPFile.CountFields-1 do
 if sgModeBus.Cells[2,i+1]<>'' then
 Writeln(Codes,sgModeBus.Cells[2,i+1]);
 CloseFile(Codes);

 pbLoading.Hide;

 lStart.Caption:='0 ���.';
 lEnd.Caption:=InttoStr( round((FepFile.EndTime - FepFile.StartTime)*86400))+' ���.';
 cbParam.Items.Clear;
 for i:=0 to FEPFile.CountFields-1 do
 cbParam.Items.Add(FepFile.Data[i].FieldInfo.KKS+' '+FepFile.Data[i].FieldInfo.Name+' '+FepFile.Data[i].FieldInfo.MUnit);
 if cbParam.Items.Count>0 then cbParam.ItemIndex:=0;
 cbParamChange(self);
 GetLastTimeValues(0);
 Timer.Enabled:=True;

end;
end;

procedure TfMain.cbParamChange(Sender: TObject);
var i:integer;
begin
 Series1.Clear;
 if FEPFile.CountFields>0 then
 for i:=0 to FEPFile.Data[cbParam.ItemIndex].Count-1 do
 series1.AddXY((FEPFile.Data[cbParam.ItemIndex].Data[i].DateTime-FEPFile.StartTime)*86400,FEPFile.Data[cbParam.ItemIndex].Data[i].Value);
end;

procedure TfMain.ChartTool1Change(Sender: TCursorTool; x, y: Integer;
  const XValue, YValue: Double; Series: TChartSeries; ValueIndex: Integer);
begin
 CurPosition:=ChartTool1.XValue;
 if FEPFIle<>nil then
 GetLastTimeValues(CurPosition);
 lCur.Caption:='�����. �����: '+intToStr(Round(ChartTool1.xvalue));
end;


procedure GetLastTimeValues(CurPosition:double);
var i,j:integer;
begin
 for i:=0 to FEPFile.CountFields-1 do
   if ((FEPFIle.Data[i].Data[0].DateTime-FEPFIle.StartTime)*86400)<=CurPosition
    then
     begin
      j:=0;
      while (j<FEPFIle.Data[i].Count) and
       (((FEPFIle.Data[i].Data[j].DateTime-FEPFIle.StartTime)*86400)<=CurPosition)
       do
       begin
         Data[i].Value:=FEPFIle.Data[i].Data[j].Value;
         Data[i].DateTime:=FEPFIle.Data[i].Data[j].DateTime;
         Data[i].Status:=FEPFIle.Data[i].Data[j].Status;
         inc(j);
       end;
     end;
end;

procedure ShowLastValues;
var i:integer;
begin
 for i:=0 to FEPFile.CountFields-1 do
 begin
  fMain.sgModeBus.Cells[0,i+1]:=FloattoStr(Data[i].Value);
 fMain.sgModeBus.Cells[5,i+1]:=inttoStr(Data[i].Status);
 end;
end;

procedure LoadKKS;
var i:integer;
    tf:textFile;
    s,substr:string;
begin


 AssignFile(tf,Path+'\KKS_Busher_NV.txt');
 Reset(tf);
 while not eof(tf) do
 begin
  ReadLn(tf,s);
  SetLength(Busher_NV2,Length(Busher_NV2)+1);
  for i:=0 to 3 do
   begin
    GetFirstSubStr(Substr,s,#9);
    Busher_NV2[Length(Busher_NV2)-1][i]:=Substr;
   end;
 end;
 CloseFile(tf);
end;

procedure TfMain.ServerSocketClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
  var l,cs:integer;
  ClientName,s,ParamName:string;
begin
  while( Socket.ReceiveLength>0) do
  begin
    s:=s+Socket.ReceiveText;
  end;
  if length(s)>=1 then
  begin
   // logger.Debug('get String - ' + s);
    case s[1] of
      '0': begin memo1.Lines.Add('Client name: '+copy(s,2,l-1));Params.Clear; end;
      '1': begin  SendParams(s) end;
      '2': begin memo1.Lines.Add('<Subscribe>'); SendValues;  end;
    end;
  end;
end;

//���� ��� ��������� � ������� � ���������� ��
procedure TfMain.Subscribe;
var i,numstr:integer;
    s:string;
begin
  s:='0';
  SetLength(IndexArray,0);
  CountIndex:=0;
  SendData.Clear;
  for i:=0 to Params.Count-1 do
  begin
    numstr := StrToInt(Params[i]);
    case Params.Strings[i]=sgModeBus.Cells[2,numstr] of
    False: s:=s+#9+IntToStr(-1);
    True : begin s:=s+#9+IntToStr(numstr); SendData.AddNewIndex(numstr);end;
    end;
  end;

  //�������� ����������
 for i:=0 to ServerSocket.Socket.ActiveConnections-1 do
  ServerSocket.Socket.Connections[i].SendText(s);

  SendData.Initalize(data);
  //Params.Clear;

end;


procedure TfMain.GetParams(s: string);
var
i:integer;
SubStr:string;
begin
  if Length(s)>1 then
  if s[1]='1' then
  begin
   s:=copy(s,2,Length(s)-1);
   while GetFirstSubStr(SubStr,s,#9) do
    Params.Add(SubStr);
  end;
end;
 //�������� id
 procedure TfMain.SendParams(s:string);
 var
   i,retValue,count,countGet,position:integer;
   returnString,kksStr:string;
 begin
   //������ �� id
   returnString:='';
   count:=0;
   countGet:=0;
   if Length(s)>1 then
   if s[1]='1' then
   begin
   s:=copy(s,2,Length(s)-1);

   //��������� ���������� �������� ����������
   countGet:= StrToInt(copy(s,1,Pos(#9,s)-1));
   //logger.Debug('count params = ' + inttostr(countGet));
   //logger.Debug('str - ' + s+ ' len = ' +IntToStr(Length(s)) );
   s:=copy(s,Pos(#9,s)+1,Length(s)-Pos(#9,s));
   while(Length(s)>1)  do
    begin
      position:=Pos(#9,s);
      //�������� �� ������ ��������� kks
      kksStr:=copy(s,1,position-1);
      //������� ��� �� ������
      s:=copy(s,position+1,Length(s)-position);
      //��������� id �� KKS �����
      i:=1;
    //���� ���� kks � ������� � �������
     while (i<sgModeBus.RowCount) and not (kksStr=sgModeBus.Cells[2,i])  do
     begin
        inc(i);
     end;
     //���� ����� �� ���������� ��� id
      if(i<sgModeBus.RowCount) and (kksStr=sgModeBus.Cells[2,i]) then
      begin
       retValue:= i;
       Params.Add(IntToStr(retValue));
      // logger.Debug('retValue = ' + inttostr(retValue));
       end
       //���� �� �����, �� ����������� ��� id = 0
       else
       retValue:=0;
       returnString:=returnString+IntToStr(retValue)+#9;
       inc(count);
    end;
    if(count <> countGet) then
    begin
      returnString:='0';
      params.Clear;
    end;
    //� ������ ������ ��������� ����� - ���������� ��������
    returnString:=IntToStr(count)+ #9+returnString;
       //logger.Debug(' retstring = ' + returnString);
      // logger.Debug('count params - ' + IntToStr(Params.Count));
    // �������� ������ �������
    for i:=0 to ServerSocket.Socket.ActiveConnections-1 do
    begin
       ServerSocket.Socket.Connections[i].SendText(returnString);
    end;
  end;
 end;

function TfMain.SendValues():String;
var
  i,numstr,k,count:integer;
  res:string;
begin

res:='';
count:=0;
for i:=0 to Params.Count-1 do
  begin
       numstr:=StrToInt(Params.Strings[i]);
       res:=res +Params.Strings[i]+' ';
       res:=res + sgModeBus.Cells[0,numstr]+' '+ sgModeBus.Cells[5,numstr]+#9;
       inc(count);
     //�������� ����������
      SendData.Initalize(data);
  end;
  //��������� � ������ ������ ���������� �������
  res:=IntToStr(count)+#9+res;
  //logger.Debug('count params - '+inttoStr(Params.Count)+ 'send values - ' + res);
  //���������� �������
  for k:=0 to ServerSocket.Socket.ActiveConnections-1 do
    ServerSocket.Socket.Connections[k].SendText(res);
end;

procedure TfMain.ServerSocketClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
var
 i:integer;
begin
  Memo1.Lines.Add(Socket.RemoteAddress+ ' - adress');
end;

procedure TfMain.ServerSocketClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  Params.Clear;
end;

end.

