program Project1;

uses
  Windows,
  ShellApi,
  Messages,
  SysUtils,
  CommCtrl,
  OLE2,
  ShlObj,
  ComObj,
  shlwapi,
  Classes;

{$R *.RES}

var
  Msg        : TMsg;
  wClass  : TWndClass;
  hMainHandle: HWND;
  hTreeHandle: HWND;
  hViewLHandle: HWND;


  //Variables para obtener discos y datos sobre ellos
  listofDrivesDir: TStringList;
  DriveList: TStringList;
  DirListName: TStringList;
  DirListDate: TStringList;
  DirListSize: TStringList;
  DirListType: TStringList;

  //Variables para manejo del path
  gPath: String;
  tPath: String;
  curSelect: String;
  curCopyArchivo: String;
  curCopyArchivoName: String;
  curCopyCarpeta: String;
  curCopyCarpetaName: String;
  curMoverArchivo: String;
  curMoverArchivoName: String;

  //Variables para los botones
  AddArchivo: HWND;
  AddCarpeta: HWND;
  PasteArchivo: HWND;
  DeleteArchivo: HWND;
  DeleteCarpeta: HWND;
  CutArchivo: HWND;
  CutCarpeta: HWND;
  RenameArchivo: HWND;
  RenameCarpeta: HWND;
  textBox: HWND;


//preparar las listas de datos para el ListView
procedure ListFileDir(Path: string);
var
  SR: TSearchRec;
  SRS: WIN32_FIND_DATAW;
  tem: HWND;
  temp: cardinal;
  temp2: string;
  modifiedresult: SYSTEMTIME;
begin
  DirListName.Clear;
  DirListDate.Clear;
  DirListSize.Clear;
  DirListType.Clear;
  Path:= Path+'*.*';
  tem:= FindFirstFileW( PWideChar(Path) , SRS);
    repeat
    //22, 65568, 2526711808, 8211, 2550136833,8214,268435457
      if NOT(SRS.dwFileAttributes AND FILE_ATTRIBUTE_SYSTEM = FILE_ATTRIBUTE_SYSTEM) AND
         NOT(SRS.dwFileAttributes AND FILE_ATTRIBUTE_HIDDEN = FILE_ATTRIBUTE_HIDDEN) then
      begin
        temp2:= '';
        DirListName.Add(SRS.cFileName); // SAVING THE NAME

        temp:= ( (SRS.nFileSizeHigh*(MAXDWORD)+1) + SRS.nFileSizeLow ) ;//SIZE IS IN BYTES
        DirListSize.Add(temp.ToString );

        if NOT(SRS.dwFileAttributes AND FILE_ATTRIBUTE_DIRECTORY = FILE_ATTRIBUTE_DIRECTORY) then
          begin
            DirListType.Add('File');
          end
        else
          begin
            DirListType.Add('Directory');
          end;

        FileTimeToSystemTime(SRS.ftLastWriteTime,modifiedresult);
        temp2:= temp2+modifiedresult.wDay.ToString;
        temp2:= temp2+'/';
        temp2:= temp2+modifiedresult.wMonth.ToString;
        temp2:= temp2+'/';
        temp2:= temp2+modifiedresult.wYear.ToString;
        DirListDate.Add(temp2); //SAVING MODIFIED DATE



      end;

    until FindNextFileW(tem, SRS) = FALSE;
    Windows.FindClose(tem);
  end;

//Muestra paths de los volumenes
procedure DisplayVolumePaths( VolumeName: PWideChar);
var
  CharCount: DWORD;
  CC: Cardinal;
  Names: array[0..MAX_PATH] of Char;
  NameIdx: PWideChar;
  Success: BOOL;

begin
  CharCount:= MAX_PATH + 1;
  //Names := nil;
  NameIdx := nil;
  Success := FALSE;

  while True do
  begin

    //Names := PWideChar(BYTE(CharCount * sizeof(WCHAR)));

    //Obtaining all the paths for the volume
    Success:=GetVolumePathNamesForVolumeNameW(VolumeName,@Names,MAX_PATH,CharCount);

    if Success then
    begin
      break;
    end;

    if NOT( GetLastError = ERROR_MORE_DATA) then
    begin
      break;
    end;

    //FreeMem(Names);
    Names := #0;

  end;

  //Displaying the paths
  if(Success) then
  begin

    NameIdx := Names;


    while NOT(NameIdx[0] = #0) do
    begin
      WriteLn(NameIdx);
      listofDrivesDir.Add(NameIdx);
      NameIdx:= NameIdx+Length(NameIdx);
    end;

  end;

  if NOT(Names = nil) then
  begin
    //FreeMem(Names);
    Names:= #0;
  end;


end;

//Lista todos los discos
procedure listingDisks();//Lista toda la informacion de los discos presentes
var
  CharCount: DWORD;
  DeviceName: array[0..MAX_PATH-1] of WideChar;
  Error: DWORD;
  FindHandle: HWND;
  Found: BOOL;
  Index: size_t;
  Success: BOOL;
  VolumeName: array[0..MAX_PATH-1] of WideChar;

begin
  //Declaraciones de variables iniciales
  CharCount:= 0;
  DeviceName:= '';
  Error:= ERROR_SUCCESS;
  FindHandle:= INVALID_HANDLE_VALUE;
  Found:= FALSE;
  Index:= 0;
  Success:= FALSE;
  VolumeName:= '';

  //Enumerando todos los volumenes del sistema
  FindHandle := FindFirstVolumeW(VolumeName, Length(VolumeName)-1);
  //VolumeName:= '';
  //FindNextVolumeW(FindHandle, VolumeName, Length(VolumeName)-1);
  
  if FindHandle = INVALID_HANDLE_VALUE then
  begin
    Error := GetLastError();
    WriteLn('FindFirstVolumeW failed with this error code');
    WriteLn(Error);
  end;

  WriteLn('First Volume');
  WriteLn(VolumeName);

  while True do
  begin
    //Limpiando los backslash
    Index:= Length(VolumeName)-212;
   

    if NOT(VolumeName[0]= '\') or
       NOT(VolumeName[1]= '\') or
       NOT(VolumeName[2]= '?') or
       NOT(VolumeName[3]= '\') or
       NOT(VolumeName[Index]= '\')then
    begin
      Error:= ERROR_BAD_PATHNAME;
      WriteLn('FindFirstVolumeW/FindNextVolumeW returned a bad path:');
      WriteLn(VolumeName);
      break;
    end;

    //removing last backslash
    VolumeName[Index] := #0;
    CharCount := QueryDosDeviceW(@VolumeName[4],DeviceName,Length(DeviceName)-1);
    VolumeName[Index] := '\';

    if CharCount = 0 then
    begin
      Error:= GetLastError();
      Write('QueryDosDeviceW failed with error: ');
      WriteLn(Error);
      break;
    end;

    Write('Found a device: ');
    WriteLn(DeviceName);
    Write('Paths: ');
    DisplayVolumePaths(@VolumeName);//Parece que si funciona!

    //Al siguiente Volumen
    Success:= FindNextVolumeW(FindHandle, VolumeName, Length(VolumeName)-1);

    if NOT(Success) then
    begin
      Error := GetLastError();

      if NOT(Error = ERROR_NO_MORE_FILES) then
      begin
        Write('FindNextVolumeW failed with error: ');
        WriteLn(Error);
        break;
      end;

      WriteLn('Finished printing all disks');
      Error:= ERROR_SUCCESS;
      break;
      
    end;

  end;


end;


function InsertItemInListView(hWndListView: HWND; cantItems: integer): integer;
var
  Lvi: tagLVITEMW;
  index: integer;
begin
  index:= 0;

  Lvi.mask := LVIF_TEXT;
  Lvi.cchTextMax :=256;
  Lvi.stateMask := 0;
  Lvi.state := 0;

  //Creando todas las filas con el nombre de archivo
  while index < cantItems do
  begin
    Lvi.iItem:=index;//Control Filas
    Lvi.iSubItem := 0;//Control Columnas
    Lvi.pszText:= PWideChar(DirListName[index]);//Texto
    SendMessage(hWndListView, LVM_INSERTITEM,0,LPARAM(@Lvi));
    index:= index+1;
  end;

  index:= 0;
  //rellenamos segunda columna
  while index < cantItems do
  begin
    Lvi.iItem:=index;//Control Filas
    Lvi.iSubItem := 1;//Control Columnas
    Lvi.pszText:= PWideChar(DirListSize[index]);//Texto
    SendMessage(hWndListView, LVM_SETITEM,0,LPARAM(@Lvi));
    index:= index+1;
  end;

  index:= 0;
  //rellenamos segunda columna
  while index < cantItems do
  begin
    Lvi.iItem:=index;//Control Filas
    Lvi.iSubItem := 2;//Control Columnas
    Lvi.pszText:= PWideChar(DirListType[index]);//Texto
    SendMessage(hWndListView, LVM_SETITEM,0,LPARAM(@Lvi));
    index:= index+1;
  end;

  index:= 0;
  //rellenamos segunda columna
  while index < cantItems do
  begin
    Lvi.iItem:=index;//Control Filas
    Lvi.iSubItem := 3;//Control Columnas
    Lvi.pszText:= PWideChar(DirListDate[index]);//Texto
    SendMessage(hWndListView, LVM_SETITEM,0,LPARAM(@Lvi));
    index:= index+1;
  end;
    index:=0;

end;

function getPathForListView(m_hListView: HWND; item: integer): LPCWSTR;
var
  lv: TLVITEMW;
  test: array[0..100] of PWideChar;
begin
  lv.mask := LVIF_TEXT;
  lv.iItem := item;
  lv.iSubItem:= 0;

  lv.pszText:= @test;
  lv.cchTextMax:= 100;

  ListView_GetItem(m_hListView, lv);


  WriteLn('Seeing what we got in getPathForLV: ');
  WriteLn(lv.pszText);
  WriteLn(lv.lParam.ToString());

  Result:= lv.pszText;
end;

procedure UpdategPath();
var
  temp: string;
begin
  WriteLn('UpdatePath');
  gPath:= gPath.Remove(gPath.LastIndexOf('\'));
  WriteLn(gPath);
  gPath:= gPath.Remove(gPath.LastDelimiter('\')+1);
  WriteLn(gPath);

end;

procedure loadOrExecSelected(hListV: HWND);
var
  filename: LPCWSTR;
  fd: WIN32_FIND_DATA;
  temp: LongBool;
  tempPath: String;
  tempFileName: String;

begin
  //DirListName.Clear;
  //DirListDate.Clear;
  //DirListSize.Clear;
  //DirListType.Clear;

  filename:= getPathForListView(hListV, ListView_GetSelectionMark(hListV));

  tempFileName:= filename;
  Write('Filepath: ');
  WriteLn(filename);


  //preparando el path
  //funcion que reduce el path cuando es ..
  if tempFileName = '..' then
  begin
    updategPath();
    //llamada a procedimiento de reduccion
  end;

  //a partir de aqui, trabajamos con respecto al gPath actualizado para movernos en directorios
  //y un tempPath:= gPath + filename para abrir archivos
  //tempPath:= gPath;
  //tempPath:= tempPath + filename;
  temp := GetFileAttributesExW(filename, GetFileExInfoStandard, @fd);
   Write('TempFileName: ');
   WriteLn(tempFileName);
   Write('Attributes: ');
   WriteLn(fd.dwFileAttributes.ToString);

  if NOT( temp = TRUE ) then
  begin

    if PathIsDirectoryW(PWideChar(gPath+tempFileName)) then
    begin
      WriteLn('Abriendo un Directorio');
      if NOT(tempFileName = '..') AND
         NOT(tempFileName = '.') then
      begin
        WriteLn('Concatenando filename y gPath');
        gPath:= gPath + tempFileName;
        gPath:= gPath + '\';
        WriteLn(gPath);
      end;


      ListView_DeleteAllItems(hListV);
      ListFileDir(gPath);
      InsertItemInListView(hListV, Length(DirListName.ToStringArray));
    end
    else
    begin
      tempPath:= gPath + tempFileName;
      WriteLn('Abriendo un File');
      WriteLn(tempFileName);
      WriteLn(tempPath);
      ShellExecute(0, 'open',PWideChar(tempPath), nil, nil, SW_SHOWNORMAL);
    end;

  end;
  WriteLn('Did we got here?');


end;


function ListView(hwndParent: HWND): HWND;
var
 rClient: TRect;
 hwndListV: HWND;
 initrec: TInitCommonControlsEx;

  parentW: integer;
  nHeight: integer;
  nWidth: integer;
  y: integer;

  //columnas de la listView
  lvCol1: tagLVCOLUMNW;
  lvCol2: tagLVCOLUMNW;
  lvCol3: tagLVCOLUMNW;
  lvCol4: tagLVCOLUMNW;

begin
  InitCommonControls();

  //Definicion del tamano
  GetClientRect(hwndParent, rClient);

  parentW := rClient.Right - rClient.Left;
  parentW := parentW div 4;
  nHeight := rClient.Bottom;
  nWidth := (rClient.Right - rClient.Left);
  nWidth := nWidth * 2 div 3 +1;
  y := 0;

  //Implementacion de la lista
 //createListView(parentWidth / 4, y, nWidth, nHeight, hWnd);
  hwndListV := CreateWindow(WC_LISTVIEW,
                           '',
                           WS_CHILD or WS_VISIBLE or WS_BORDER or LVS_REPORT or WS_HSCROLL or WS_VSCROLL,
                           rClient.left + 200 + 2,
                           0,
                           rClient.right - (rClient.left + 200 + 2),
                           (rClient.bottom - rClient.top) - (80 + 80),
                           hwndParent,
                           0,
                           hInstance,
                           nil);

  //Definiendo algunas columnas como testeo
  //Probablemente las cambie a futuro

  //Columna de Nombre
  lvCol1.mask := LVCF_FMT or LVCF_TEXT or LVCF_WIDTH;
	lvCol1.fmt := LVCFMT_LEFT;

	lvCol1.cx := 130;
	lvCol1.pszText := 'Nombre';
	ListView_InsertColumn(hwndListV, 0, lvCol1);

  //Columna de Tamano
	lvCol2.mask := LVCF_FMT or LVCF_TEXT or LVCF_WIDTH;
	lvCol2.fmt := LVCFMT_LEFT or LVCF_WIDTH;
	lvCol2.cx := 130;
	lvCol2.pszText := 'Size';
	ListView_InsertColumn(hwndListV, 1, lvCol2);

  //Columna de Tipo
  lvCol3.mask := LVCF_FMT or LVCF_TEXT or LVCF_WIDTH;
	lvCol3.fmt := LVCFMT_CENTER;
	lvCol3.cx := 130;
	lvCol3.pszText := 'Type';
	ListView_InsertColumn(hwndListV, 2, lvCol3);

  //Columna de Modificado
  lvCol4.mask := LVCF_FMT or LVCF_TEXT or LVCF_WIDTH;
	lvCol4.fmt := LVCFMT_CENTER;
	lvCol4.cx := 339;
	lvCol4.pszText := 'Modificado';
	ListView_InsertColumn(hwndListV, 3, lvCol4);

	Result := hwndListV;

end;

procedure updateTreeView();
var
  tvInsert: TV_INSERTSTRUCT;
  hDisks: HTREEITEM;
  hDrive: HTREEITEM;
  temp: LPARAM;
  cantDiscos: integer;
  i: integer;
begin
  i:=0;
  cantDiscos:= Length(listofDrivesDir.ToStringArray());
  //ingreso de objetos al Arbol
  temp:= 0;
  tvInsert.hParent:= nil;
  tvInsert.hInsertAfter:= TVI_ROOT;
  tvInsert.item.mask := TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM;
	tvInsert.item.pszText := 'Local PC';
	tvInsert.item.lParam := temp;
  hDisks:= TreeView_InsertItem(hTreeHandle, tvInsert);

  while i< cantDiscos do
  begin
    WriteLn('How do yo do?');
    tvInsert.hParent:= hDisks;
    tvInsert.item.pszText:= PWideChar(listofDrivesDir[i]);
    tvInsert.item.lParam:= 1;

    hDrive:= TreeView_InsertItem(hTreeHandle, tvInsert);
    i:=i+1;
  end;
  TreeView_Expand(hTreeHandle, hDisks, TVE_EXPAND);
  TreeView_SelectItem(hTreeHandle, hDisks);

end;

function TreeView(hwndParent: HWND): HWND;
var
  rClient: TRect;
  hwndTreeV: HWND;
  initrec: TInitCommonControlsEx;

  parentW: integer;
  parentH: integer;

begin

  InitCommonControls();

  //Definicion del tamano
  GetClientRect(hwndParent, rClient);
  parentW := rClient.Right - rClient.Left;
  parentH := rClient.Bottom - rClient.Top;
  parentH := parentH div 4;

  //Llamado a la funcion
  hwndTreeV := CreateWindowEx(0,
                             WC_TREEVIEW,
                             'Tree View',
                             WS_CHILD or WS_VISIBLE or WS_BORDER or WS_SIZEBOX or WS_VSCROLL or WS_TABSTOP or TVS_HASLINES or TVS_LINESATROOT or TVS_HASBUTTONS or TVS_SHOWSELALWAYS,
                             0,//X
                             0,//Y
                             parentH,//width
                             parentW,//height
                             hwndParent,
                             0,
                             hInstance,
                             nil);

  //inicializar contenidos que absorbera el tree view
  //preparar funcion para lista de drives
  //loadMyComputerToTreeView(hwndTreeV);

  Result:= hwndTreeV;

end;

procedure updateCurSel(hListV: HWND);
var
  filename: LPCWSTR;
  tempFileName: String;

begin

  filename:= getPathForListView(hListV, ListView_GetSelectionMark(hListV));
  tempFileName:= filename;
  curSelect:= tempFileName;
  //Write('updateCurSel: ');
  //WriteLn(curSelect);
end;

procedure addButton();
begin
AddArchivo := CreateWindow( 'BUTTON', '+ Archivo',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        200,//x
                        520,//y
                        90,//width
                        30,//height
                        hMainHandle,//parentWindow
                        100,//hMenu
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

AddCarpeta := CreateWindow( 'BUTTON', '+ Carpeta',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        200,//x
                        560,//y
                        90,//width
                        30,//height
                        hMainHandle,//parentWindow
                        101,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

            CreateWindow( 'BUTTON', 'Copiar Archivo',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        300,//x
                        520,//y
                        100,//width
                        30,//height
                        hMainHandle,//parentWindow
                        102,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

PasteArchivo := CreateWindow( 'BUTTON', 'Pegar Archivo',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        300,//x
                        560,//y
                        100,//width
                        30,//height
                        hMainHandle,//parentWindow
                        103,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

DeleteArchivo := CreateWindow( 'BUTTON', 'Borrar Archivo',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        410,//x
                        520,//y
                        100,//width
                        30,//height
                        hMainHandle,//parentWindow
                        104,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

DeleteCarpeta := CreateWindow( 'BUTTON', 'Borrar Carpeta',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        410,//x
                        560,//y
                        100,//width
                        30,//height
                        hMainHandle,//parentWindow
                        105,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

CutArchivo := CreateWindow( 'BUTTON', 'Cortar',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        520,//x
                        520,//y
                        100,//width
                        30,//height
                        hMainHandle,//parentWindow
                        106,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

CutCarpeta := CreateWindow( 'BUTTON', 'Mover',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        520,//x
                        560,//y
                        100,//width
                        30,//height
                        hMainHandle,//parentWindow
                        107,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

RenameArchivo := CreateWindow( 'BUTTON', 'Renombrar',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        630,//x
                        520,//y
                        110,//width
                        30,//height
                        hMainHandle,//parentWindow
                        108,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

RenameCarpeta := CreateWindow( 'BUTTON', 'Shortcut',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        630,//x
                        560,//y
                        110,//width
                        30,//height
                        hMainHandle,//parentWindow
                        109,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);
//Creando el TextBox
textBox := CreateWindowEx(WS_EX_CLIENTEDGE, 'edit', '',
                              WS_CHILD or WS_VISIBLE or WS_TABSTOP or WS_BORDER or ES_LEFT,
                              200, //x
                              610, //y
                              200, //w
                              24,	//h
                              hMainHandle,
                               110,
                              GetWindowLong(hMainHandle, GWL_HINSTANCE),
                               nil);

           CreateWindow( 'BUTTON', 'Copiar Carpeta',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        750,//x
                        520,//y
                        112,//width
                        30,//height
                        hMainHandle,//parentWindow
                        111,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

           CreateWindow( 'BUTTON', 'Pegar Carpeta',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        750,//x
                        560,//y
                        112,//width
                        30,//height
                        hMainHandle,//parentWindow
                        112,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

           CreateWindow( 'BUTTON', 'Link Simbolico',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        870,//x
                        520,//y
                        112,//width
                        30,//height
                        hMainHandle,//parentWindow
                        113,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

           CreateWindow( 'BUTTON', 'Link Duro',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        870,//x
                        560,//y
                        112,//width
                        30,//height
                        hMainHandle,//parentWindow
                        114,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);

           CreateWindow( 'BUTTON', 'Junction',
                        WS_TABSTOP or WS_VISIBLE or WS_CHILD or BS_DEFPUSHBUTTON,
                        990,//x
                        520,//y
                        112,//width
                        30,//height
                        hMainHandle,//parentWindow
                        115,
                        GetWindowLong(hMainHandle, GWL_HINSTANCE),
                        nil);



end;

//
procedure addArchive();
var
  temph: HWND;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  WriteLn(GetDlgItemText(hMainHandle, id, name, longi));

  temph := CreateFile(PWideChar(gPath+name), FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, 0, nil,
  CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);

  CloseHandle(temph);

  ListView_DeleteAllItems(hViewLHandle);
  ListFileDir(gPath);
  InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

end;

procedure addDirectory();
var
  temph: LongBool;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  WriteLn(GetDlgItemText(hMainHandle, id, name, longi));

  temph := CreateDirectoryW(PWideChar(gPath+name),nil);


  if NOT(temph = TRUE) then
  begin
    MessageBox(hMainHandle,'El directorio ya existe o no se tienen los permisos' +
                           'de escritura adecuados', 'Error', MB_OK);
  end;

  ListView_DeleteAllItems(hViewLHandle);
  ListFileDir(gPath);
  InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

end;

procedure deleteArchive();
begin
  //Borrado permanente
  if NOT(PathIsDirectoryW(PWideChar(gPath+curSelect))) then //si no es directorio, es archivo
  begin

    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin

      if(MessageBox(hMainHandle, 'Are you sure you want to permanently delete this file?', 'Delete', MB_YESNO) = IDYES) then
      begin
       DeleteFileW(PWideChar(gPath+curSelect));
       //limpiamos las listas para actualizar los datos

       curSelect:= '';
       //ListFileDir(gPath);
       //InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
      ListView_DeleteAllItems(hViewLHandle);
      ListFileDir(gPath);
      InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

      end;
    end;
  end;
  if NOT(curSelect = '') then
  begin
    MessageBox(hMainHandle, 'El objeto seleccionado no es un Archivo','Error', MB_OK);
  end;


end;

procedure renombrar();  //No implementada aun
var
  temph: LongBool;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  WriteLn(GetDlgItemText(hMainHandle, id, name, longi));

  temph := MoveFileExW(PWideChar(gPath+curSelect),PWideChar(gPath+name),MOVEFILE_WRITE_THROUGH);


  if NOT(temph = TRUE) then
  begin
    MessageBox(hMainHandle,'El nombre de archivo ya existe o no se tienen los permisos' +
                           'de escritura adecuados', 'Error', MB_OK);
  end;

  ListView_DeleteAllItems(hViewLHandle);
  ListFileDir(gPath);
  InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

end;

procedure deleteDirectory();
var
  fileOperation: SHFILEOPSTRUCTW;
  result: integer;
begin
  //Borrado permanente
  if PathIsDirectoryW(PWideChar(gPath+curSelect)) then //si no es directorio, es archivo
  begin

    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin

      if(MessageBox(hMainHandle, 'Are you sure you want to permanently delete this directory?', 'Delete', MB_YESNO) = IDYES) then
      begin
      fileOperation.wFunc := FO_DELETE;
      fileOperation.pFrom := PWideChar(gPath+curSelect);
      fileOperation.fFlags := FOF_NO_UI or FOF_NOCONFIRMATION;
      result:= SHFileOperationW(fileOperation);

      if NOT(result = 0) then
      begin
        MessageBox(hMainHandle,'Error al tratar de eliminar el directorio', 'Error', MB_OK);
      end;

       //limpiamos las listas para actualizar los datos
      curSelect:= '';
      ListView_DeleteAllItems(hViewLHandle);
      ListFileDir(gPath);
      InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

      end;
    end;
  end;
  if NOT(curSelect = '') then
  begin
    MessageBox(hMainHandle, 'El objeto seleccionado no es un Directorio','Error', MB_OK);
  end;

end;

procedure addHardLink();
var
  temph: LongBool;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  WriteLn(GetDlgItemText(hMainHandle, id, name, longi));

   if NOT(PathIsDirectoryW(PWideChar(gPath+curSelect))) then //si no es directorio, es archivo
  begin

    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin
       temph:= CreateHardLinkW(PWideChar(gPath+name),PWideChar(gPath+curSelect),nil);

       if temph = FALSE then
       begin
          MessageBox(hMainHandle, 'Error. No se pudo crear el hard link', 'Error', MB_OK);
       end;

      curSelect:= '';
      ListView_DeleteAllItems(hViewLHandle);
      ListFileDir(gPath);
      InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
    end;
  end;

  if NOT(curSelect = '') then
  begin
    MessageBox(hMainHandle, 'El objeto seleccionado no es un Archivo','Error', MB_OK);
  end;

end;

procedure addSymbolLink();
var
  temph: LongBool;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  WriteLn(GetDlgItemText(hMainHandle, id, name, longi));

   if NOT(PathIsDirectoryW(PWideChar(gPath+curSelect))) then //si no es directorio, es archivo
  begin

    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin
       temph:= CreateSymbolicLinkW(PWideChar(gPath+name),PWideChar(gPath+curSelect),0);

       if temph = FALSE then
       begin
          Write('Error: ');
          WriteLn(GetLastError().ToString());
          MessageBox(hMainHandle, 'Error. No se pudo crear el Symbolic link del archivo', 'Error', MB_OK);
       end;

      curSelect:= '';
      ListView_DeleteAllItems(hViewLHandle);
      ListFileDir(gPath);
      InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
    end
    else
    begin
      MessageBox(hMainHandle, 'El objeto seleccionado no es valido','Error', MB_OK);
    end;

  end
  else
  begin
    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin
       temph:= CreateSymbolicLinkW(PWideChar(gPath+name),PWideChar(gPath+curSelect), SYMBOLIC_LINK_FLAG_DIRECTORY);

       if temph = FALSE then
       begin
          MessageBox(hMainHandle, 'Error. No se pudo crear el Symbolic link del directorio', 'Error', MB_OK);
       end;

      curSelect:= '';
      ListView_DeleteAllItems(hViewLHandle);
      ListFileDir(gPath);
      InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
    end
    else
    begin
      MessageBox(hMainHandle, 'El objeto seleccionado no es un valido','Error', MB_OK);
    end;


  end;

end;

procedure addShortCut();
var
  pShellLink: IShellLink;
  pPersistFile: IPersistFile;

begin
  CoInitialize(pShellLink);
  CoCreateInstance( Ole2.TGUID(CLSID_ShellLink), nil, CLSCTX_ALL,
                   Ole2.TGUID(IID_IShellLink), pShellLink);

  pShellLink.SetPath(PWideChar(gPath+curSelect));
  pShellLink.SetDescription(PWideChar('Creado con el explorador21511028'));

  pShellLink.QueryInterface( System.TGUID(IID_IPersistFile), pPersistFile);
  pPersistFile.Save(PWideChar(gPath+curSelect+'.lnk'), TRUE);

  pPersistFile.Release;

  curSelect:= '';
  ListView_DeleteAllItems(hViewLHandle);
  ListFileDir(gPath);
  InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

end;

//curselect es el archivo que copiaremos
//solo prepararemos los archivos para el paste
//hay que filtrar que no sea un directorio
procedure prepareCopyArchivo();
begin


   if NOT(PathIsDirectoryW(PWideChar(gPath+curSelect))) then //si no es directorio, es archivo
  begin

    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin
       curCopyArchivo:= gPath + curSelect;
       curCopyArchivoName:= curSelect;
       Write('Copy Archive: ');
       WriteLn(curCopyArchivo);
       WriteLn(curCopyArchivoName);
      
    end;
  end
  else
  begin
    MessageBox(hMainHandle, 'El objeto seleccionado no es un Archivo','Error', MB_OK);
  end;

end;

procedure CopyArchivo();
var
  temph: LongBool;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  GetDlgItemText(hMainHandle, id, name, longi);


  if name[0]='' then
  begin
    //en caso de que no se haya decidido cambiar el nombre
    temph := CopyFileW(PWideChar(curCopyArchivo), PWideChar(gPath+curCopyArchivoName),TRUE);
    if NOT(temph = TRUE) then
    begin
      MessageBox(hMainHandle, 'No se pudo copiar el archivo. Revise que el nombre' +
                              'no exista en el directorio de destino y que posee' +
                              'los permiso necesarios para esta operacion', 'Error', MB_OK);
    end;

    //actualizando ListView
    curSelect:= '';
    ListView_DeleteAllItems(hViewLHandle);
    ListFileDir(gPath);
    InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
  end
  else
  begin
    //en caso de que si se ingreso un nombre
    temph := CopyFileW(PWideChar(curCopyArchivo), PWideChar(gPath+name),TRUE);
    if NOT(temph = TRUE) then
    begin
      MessageBox(hMainHandle, 'No se pudo copiar el archivo. Revise que el nombre' +
                              'no exista en el directorio de destino y que posee' +
                              'los permiso necesarios para esta operacion', 'Error', MB_OK);
    end;

    //actualizando ListView
    curSelect:= '';
    ListView_DeleteAllItems(hViewLHandle);
    ListFileDir(gPath);
    InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
  end;


end;

procedure prepareCopyCarpeta();
begin

   if PathIsDirectoryW(PWideChar(gPath+curSelect)) then //si no es directorio, es archivo
  begin

    if NOT(curSelect = '..') AND
       NOT(curSelect = '.') then
    begin
       curCopyCarpeta:= gPath + curSelect;
       curCopyCarpetaName:= curSelect;
       Write('Copy Carpeta: ');
       WriteLn(curCopyCarpeta);
       WriteLn(curCopyCarpetaName);

    end;
  end
  else
  begin
    MessageBox(hMainHandle, 'El objeto seleccionado no es un Directorio','Error', MB_OK);
  end;

end;

procedure CopyCarpeta();
var
  temph: integer;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
  s: SHFILEOPSTRUCTW;
begin
  id:= 110;
  longi:= 30;
  GetDlgItemText(hMainHandle, id, name, longi);


  if name[0]='' then
  begin
    //en caso de que no se haya decidido cambiar el nombre
    s.wFunc:= FO_COPY;
    s.fFlags:= FOF_SILENT;
    s.pTo:= PWideChar(gPath+curCopyCarpetaName);
    s.pFrom:= PWideChar(curCopyCarpeta);

    temph := SHFileOperation(s);

    if NOT(temph = 0) then
    begin
      MessageBox(hMainHandle, 'No se pudo copiar la carpeta. Revise que el nombre' +
                              'no exista en el directorio de destino y que posee' +
                              'los permiso necesarios para esta operacion', 'Error', MB_OK);
    end;

    //actualizando ListView
    curSelect:= '';
    ListView_DeleteAllItems(hViewLHandle);
    ListFileDir(gPath);
    InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
  end
  else
  begin
    //en caso de que si se ingreso un nombre
    s.wFunc:= FO_COPY;
    s.fFlags:= FOF_SILENT;
    s.pTo:= PWideChar(gPath+name);
    s.pFrom:= PWideChar(curCopyCarpeta);

    temph := SHFileOperation(s);

    if NOT(temph = 0) then
    begin
      MessageBox(hMainHandle, 'No se pudo copiar la carpeta(name not changed). Revise que el nombre' +
                              'no exista en el directorio de destino y que posee' +
                              'los permiso necesarios para esta operacion', 'Error', MB_OK);
    end;

    //actualizando ListView
    curSelect:= '';
    ListView_DeleteAllItems(hViewLHandle);
    ListFileDir(gPath);
    InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
  end;


end;

procedure prepareMover();
begin
  if NOT(curSelect = '..') AND
     NOT(curSelect = '.') then
    begin
       curMoverArchivo:= gPath + curSelect;
       curMoverArchivoName:= curSelect;
       Write('Mover: ');
       WriteLn(curMoverArchivo);
       WriteLn(curMoverArchivoName);

    end
    else
    begin
      MessageBox(hMainHandle, 'El objeto seleccionado no es valido', 'Error', MB_OK);
    end;
end;

procedure MoveObject();
var
  temph: LongBool;
begin
  if NOT(curMoverArchivo = '') then
  begin
    temph := MoveFileExW(PWideChar(curMoverArchivo),PWideChar(gPath+curMoverArchivoName), MOVEFILE_WRITE_THROUGH);

    if NOT(temph = TRUE) then
    begin
      MessageBox(hMainHandle, 'No se pudo mover el archivo/Carpeta. Revise que el nombre' +
                              'no exista en el directorio de destino y que posee' +
                              'los permiso necesarios para esta operacion', 'Error', MB_OK);
    end;

    //actualizando ListView
    curSelect:= '';
    curMoverArchivo:='';
    curMoverArchivoName:='';
    ListView_DeleteAllItems(hViewLHandle);
    ListFileDir(gPath);
    InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
  end
  else
  begin
    MessageBox(hMainHandle, 'No se selecciono ningun archivo o carpeta', 'Error', MB_OK);
  end;

end;

procedure updateDiskDisplay();
var
  buffer: array[0..127] of char;
  ine: integer;
  item: tagTVITEMW;
  temp: HTREEITEM;
begin
  temp := TreeView_GetSelection(hTreeHandle);

  if temp = nil then
  begin
    Write('Nothing Selected');
    exit;
  end;
  //item:= 0;

  item.hItem:= temp;
  item.mask:= TVIF_TEXT;
  item.cchTextMax:= 128;
  item.pszText:= buffer;

  if TreeView_GetItem(hTreeHandle, item) then
  begin
    Write('Text: ');
    WriteLn(item.pszText);
    gPath:= String(item.pszText);
    curSelect:= '';
    ListView_DeleteAllItems(hViewLHandle);
    ListFileDir(gPath);
    InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

  end;

end;

procedure addJunction();
var
 Command : String;
 Parameters : String;
  name: array[0..30] of char;
  id: integer;
  longi: integer;
begin
  id:= 110;
  longi:= 30;
  WriteLn(GetDlgItemText(hMainHandle, id, name, longi));
   Command := 'mklink';
   Parameters := ' /J \' + name + ' ' + gPath;

    if PathIsDirectoryW(PWideChar(gPath+curSelect)) then //si no es directorio, es archivo
    begin

        if NOT(curSelect = '..') AND
        NOT(curSelect = '.') then
        begin
          ShellExecute(hMainHandle, nil, PChar(Command) , PChar(Parameters), nil, SW_SHOWNORMAL);
          curSelect:= '';
          ListView_DeleteAllItems(hViewLHandle);
          ListFileDir(gPath);
          InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));

        end
        else
        begin
          MessageBox(hMainHandle,'Objeto invalido. Debe ser un directorio', 'Error', MB_OK);
        end;

    end
    else
    begin
       MessageBox(hMainHandle,'Objeto invalido. Debe ser un directorio', 'Error', MB_OK);
    end;

end;

function WindowProc(hWnd: HWND;Msg: UINT;wParam: WPARAM; lParam: LPARAM):Integer; stdcall;
var
  temp: integer;
  notifyMess: PNMHDR;

begin
  if Msg = WM_DESTROY then
    PostQuitMessage(0);
    Result := DefWindowProc(hWnd,Msg,wParam,lParam);

  if Msg = WM_NOTIFY then
  begin
    notifyMess:= PNMHDR(lParam);


    case notifyMess.code of
      NM_DBLCLK:
      begin
        if notifyMess.hwndFrom = hViewLHandle then
        begin
          //verificar si es carpeta o archivo y hacer lo correspondiente
          loadOrExecSelected(hViewLHandle);
        end;

        if notifyMess.hwndFrom = hTreeHandle then
        begin
          WriteLn('Double click on the tree!');
          updateDiskDisplay();
        end;
      end;

      NM_CLICK:
      begin
        WriteLn('Left Clicl');
        updateCurSel(hViewLHandle);
      end;

    end;

  end;

  //Eventos de los Botones
  if Msg = WM_COMMAND then
  begin
    WriteLn('Un boton xd');
    notifyMess:= PNMHDR(lParam);

    case LOWORD(wParam) of
      100: //AddArchivo
      begin
        //llamar funcion para crear nuevo archivo
        addArchive();
      end;
      101: //AddCarpeta
      begin
        addDirectory();
      end;
      102: //CopyArchivo
      begin
        prepareCopyArchivo();
      end;
      103: //PasteArchivo
      begin
        CopyArchivo();
      end;
      104: //DeleteArchivo
      begin
        deleteArchive();
      end;
      105: //DeleteCarpeta
      begin
        deleteDirectory();
      end;
      106: //Cortar
      begin
        WriteLn('Cortar');
        prepareMover();
      end;
      107:  //Mover
      begin
        WriteLn('Mover');
        MoveObject();
      end;
      108: //RenameArchivo
      begin
        renombrar();
      end;
      109: //Shortcut
      begin
        addShortCut();
      end;
      111:  //CopyCarpeta
      begin
        WriteLn('CopyCarpeta');
        prepareCopyCarpeta();
      end;
      112:  //PasteCarpeta
      begin
        WriteLn('PasteCarpeta');
        CopyCarpeta();
      end;
      113:  //Link Simbolico
      begin
        addSymbolLink();
      end;
      114:  //Link Duro
      begin
        addHardLink();
      end;
      115:  //Junction
      begin
        WriteLn('Junction');
        addJunction();
      end;
    end;
  end;

end;


begin
  DirListName:= TStringList.Create;
  DirListSize:= TStringList.Create;
  DirListType:= TStringList.Create;
  DirListDate:= TStringList.Create;
  listofDrivesDir:= TStringList.Create;

  //create the window
  wClass.lpszClassName:= 'CN';
  wClass.lpfnWndProc := @WindowProc;
  wClass.hInstance := hInstance;
  wClass.hbrBackground := 1;

  RegisterClassW(wClass);
  hMainHandle := CreateWindow(wClass.lpszClassName,
                                'Explorador - 21511028',
                                WS_OVERLAPPEDWINDOW or WS_VISIBLE,
                                0,//X
                                0,//Y
                                1366,//Width
                                700,//Length
                                0,
                                0,
                                hInstance,
                                nil
                                );


  //ShowWindow(hMainHandle, SW_SHOWNORMAL);
  listingDisks();
  Write('Cantidad Discos: ');
  WriteLn(Length(listofDrivesDir.ToStringArray()));
  hTreeHandle := TreeView(hMainHandle);
  updateTreeView();
  //hay que rellenar el TreeView con la lista de Discos

  hViewLHandle := ListView(hMainHandle);

  gPath:='C:\Users\Alexa\Desktop\';
  ListFileDir(gPath);

  InsertItemInListView(hViewLHandle, Length(DirListName.ToStringArray));
  addButton();


  //message loop
  while GetMessage(Msg,0,0,0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

end.
