function varargout = EDF_View(varargin)
%      EDF_VIEW MATLAB code for EDF_View.fig
%      EDF_VIEW, by itself, creates a new EDF_VIEW or raises the existing
%      singleton*.
%
%      H = EDF_VIEW returns the handle to a new EDF_VIEW or the handle tof
%      the existing singleton*.
%
%      EDF_VIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EDF_VIEW.M with the given input arguments.
%
%      EDF_VIEW('Property','Value',...) creates a new EDF_VIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EDF_View_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EDF_View_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EDF_View

% Last Modified by GUIDE v2.5 26-Jan-2015 16:52:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @EDF_View_OpeningFcn, ...
    'gui_OutputFcn',  @EDF_View_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);

    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    
% End initialization code - DO NOT EDIT

%------------------------------------------------------ EDF_View_OpeningFcn
% --- Executes just before EDF_View is made visible.
function EDF_View_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EDF_View (see VARARGIN)

% Choose default command line output for EDF_View
handles.output = hObject;
%------------------------------------------------------- Set Default Values
% Define Window PopUpTime Menu Entries
handles.epoch_menu = {' 5 sec'; '10 sec'; '15 sec'; '20 sec'; '25 sec'; ...
    '30 sec'; ' 1 min'; ' 2 min'; ' 5 min'; '10 min'; '20 min'; ...
    '30 min'; '60 min'};
handles.epoch_menu_values = [5; 10; 15; 20; 25; 30; 60; 120; 300; 600; ...
    1200; 1800; 3600];
handles.epoch_menu_value = 6;
handles.epoch_menu_num_tick_sections = [5; 5; 5; 6; 5; 5;
    6; 6; 5; 5; 5; 6; 6];

set(handles.PopMenuWindowTime,'String',handles.epoch_menu);
set(handles.PopMenuWindowTime,'Value',handles.epoch_menu_value);

% Set epoch count text strings to null
set(handles.textTotalEpochs,'String',' ');
set(handles.textCurrent30secEpochs,'String',' ');


% Set GUI status text to null
set(handles.TextInfo, 'String',' ');
set(handles.TextSignalValue, 'String',' ');
set(handles.EditEpochNumber, 'String',' ');

% Set EDF list font to fixed width
fontName = get(0,'FixedWidthFontName');
set(handles.ListBoxPatientInfo, 'FontName', fontName);

% Constants 
handles.RIGHT_ARROW_KEY = 29;
handles.LEFT_ARROW_KEY = 28;
handles.UP_ARROW_KEY = 30;
handles.DOWN_ARROW_KEY = 31;
handles.CONTROL_MODIFIER = 'control';

% Load and display button 
%Coloca una imagen en cada bot�n
[a,map]=imread('start.jpg');
[r,c,d]=size(a); 
x=ceil(r/30); 
y=ceil(c/30); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pb_GoToStart,'String','');
set(handles.pb_GoToStart,'CData',g);

[a,map]=imread('left.jpg');
[r,c,d]=size(a); 
x=ceil(r/30); 
y=ceil(c/30); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pbLeftEpochButton,'String','');
set(handles.pbLeftEpochButton,'CData',g);

[a,map]=imread('right.jpg');
[r,c,d]=size(a); 
x=ceil(r/30); 
y=ceil(c/30); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pbRightButton,'String','');
set(handles.pbRightButton,'CData',g);

[a,map]=imread('end.jpg');
[r,c,d]=size(a); 
x=ceil(r/30); 
y=ceil(c/30); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(handles.pbGoToEnd,'String','');
set(handles.pbGoToEnd,'CData',g);

%---------------------------------------------------------- Operating Flags
handles.EDF_LOADED = 0;
handles.XML_LOADED = 0;
handles.hasAnnotation = 0;
handles.EDF_CHECK = 0; %%% TODO
% TODO Next Step Flags: read from configuration file
handles.hasSleepStages = 0;
% handles.categories = []; % array of available categories
%--------------------------------------------------------------------------


% GUI Status Varaibles
handles.c_axes =[];
handles.ChSelectionH =[];
handles.FilterSettingH =[];
handles.ActiveCh = [];
handles.Axes1OrgPos = get(handles.axes1,'outerposition');
handles.SliderOrgPos = get(handles.SliderTime,'position');
handles.FileInfo = [];
handles.SelectedCh = [];
handles.FilterPara = [];
handles.Sel = 1; % Select first signal
handles.eventIndexInCategory = []; % for each category, this list contain the event index in the annotation

% Subset of channel selection information
handles.ChInfo = [];
handles.FlagSelectedCh = 0;
handles.FlagChInfo = 0;

% Clear hypnogram and signal axes labels
set(handles.axes1,'xTickLabel','','yTickLabel','');
set(handles.axes2,'xTickLabel','','yTickLabel','');
handles.sleep_stage_width = 30;
handles.minimum_cursor_width = 20;
handles.auto_scale_height = 2;
handles.auto_scale_factor = [];

%--------------------------------------------------------------------------
% Clear axes1 (signals) and axes2(hypnogram)
% Clear axes following second call to viewer, may want to allow multiple
% singleton

% Clear signal 
cla(handles.axes1);
set(handles.axes1,'XGrid','off')
set(handles.axes1,'YGrid','off')

% Clear hypnogram text
cla(handles.axes2);
set(handles.axes2,'XGrid','off')
set(handles.axes2,'YGrid','off')

% Clear header list box
set(handles.ListBoxPatientInfo, 'string', '  ');
set(handles.ListBoxComments, 'Value', 1);

% Clear list boz
set(handles.ListBoxComments, 'string', '  ');
set(handles.ListBoxComments, 'Value', 1);

%--------------------------------------------------------------------------
% Adding new variables intended to speed up access time while scrolling
% Will take longer to load.

% Varaibles to change figure title
figureDefaultTitle = 'EDF View';
set(handles.figure1, 'name', figureDefaultTitle);
handles.figureDefaultTitle = figureDefaultTitle;

%--------------------------------------------------------------------------
% Adding varaibles to accessesing multiple edf's in the same folder faster
handles.openStartFolder = cd;
% 2014-11-3, change 'handles.fileSeperator = '\';' to
% 'handles.fileSeperator = filesep' by Wei
% handles.fileSeperator = '\';
handles.fileSeperator = filesep; %
handles.openStartFolder = [handles.openStartFolder, handles.fileSeperator];


% Update handles structure
guidata(hObject, handles);
% UIWAIT makes EDF_View wait for user response (see UIRESUME)
% uiwait(handles.figure1);
global FilePath;
global FileName;
global XmlFilePath;
global XmlFileName;

global needOpenDialog;
%  disp(needOpenDialog); default is 0
if (~needOpenDialog)
    % Step#1: Visualize Edf
    disp('')
    tic
    if (~(strcmp(FilePath,'') || strcmp(FileName, '')))
        MenuOpenEDF_Callback(hObject, eventdata, handles);
        % Step#2: Visualize Xml
        if (~(strcmp(XmlFilePath,'') || strcmp(XmlFileName, '')))
            MenuOpenXML_Callback(hObject, eventdata, handles);
        end
    end
end
needOpenDialog = logical(1);


%------------------------------------------------------- EDF_View_OutputFcn
% --- Outputs from this function are returned to the command line.
function varargout = EDF_View_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% ---------------------------------------------------- MenuOpenEDF_Callback
function MenuOpenEDF_Callback(hObject, eventdata, handles)
% hObject    handle to MenuOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%% TODO: 
%%% 1. If handles.EDF_CHECK == 0, disable gui compoenent that calls
%%%     responsible callbacks
%%% 2. Using configuration file to do the tasks
handles = guidata(hObject);

global needOpenDialog;
global FilePath;
global FileName;

set(handles.pmAnnotations, 'string', {}); 
set(handles.ListBoxComments, 'string', {});

% Openfile start path
if (needOpenDialog)
% Openfile start path
    openStartFolder = handles.openStartFolder;
    fileSpec = strcat(openStartFolder,'*.edf');
    [FileName, FilePath] = uigetfile(fileSpec,'Open EDF File');
% InterfaceObj = findobj(gcf, 'Enable', 'on');
end

if FileName == 0 & FilePath == 0
    return
end

tic

try
    belClass = BlockEdfLoadClass([FilePath FileName]);
    belClass = belClass.blockEdfLoad; 
    belClass = belClass.CheckEdf;
    fprintf('Checking: %s\n', [FilePath FileName]);
    % belClass.DispCheck % Access checking information you want to look at lines 321-327 on BlockEdfLoadClass
    if ~isempty(belClass.errMsg) && belClass.mostSeriousErrValue <= 4
        belClass.DispCheck 
        ErrMsg = []; %belClass.errSummary;
        ErrMsg = [ErrMsg, showErrorMessages(belClass.errList)];
%         for i=1:length(belClass.errList)            
%             ErrMsg = [ErrMsg, belClass.errList(i)]; %%% TODO to be changed
%         end  
        % errordlg(ErrMsg, 'Warning', 'modal');
        warndlg(ErrMsg, belClass.errSummary, 'modal');
    end
    if belClass.mostSeriousErrValue > 4
        ErrMsg = 'Fatal Error: Cannot load';  
        errordlg(ErrMsg, 'Fatal Errors', 'modal');
        % EDF check failed
        handles.EDF_CHECK = 0;
        return
    else
        handles.EDF_CHECK = 1;
    end
    fprintf('Checking passed.\n')
catch exception
    errMsg = sprintf('Could not load: %s\nFile cannot be read', [FilePath FileName]);
    errordlg(errMsg, 'Fatal Error', 'modal'); %%% TODO: Use errordlg(message, 'XML errors') instead    
    return;
end

if ~(length(FilePath)==1)
    % Store file name
    handles.FileName=[FilePath FileName];
    handles.openStartFolder = FilePath;
    
    % Set menu flags on (dad, 2012/07/27)
    set(handles.MenuOpenXML,'enable','on');
    set(handles.MenuChSelection,'enable','on');
    set(handles.MenuFilter,'enable','on');

    set(handles.figure1,'pointer', 'watch');

    %channel info
    tempEdfHandles = EdfInfo(handles.FileName);

    handles.FileInfo  = tempEdfHandles.FileInfo;
    handles.ChInfo    = tempEdfHandles.ChInfo;
    
    handles.FlagChInfo = 1;
    % Save state
    guidata(hObject, handles);
    
    % handles.ChInfo.nr is a vector contains numbers of samples in each
    % data record
    numOfChannels = length(handles.ChInfo.nr); % numOfSamples => numOfChannels

    % Initialize to be selected channels
    Temp = [(1:numOfChannels)' zeros(numOfChannels,1)];
   
    handles.SelectedCh = Temp;
    handles.FlagSelectedCh = 1;
    
    %[Original] FilterPara = [];
    FilterPara = cell(1, numOfChannels); % preallocate cell array, by Wei, 2014-11-05
    for i=1:numOfChannels
        FilterPara{i}.A              = 1;
        FilterPara{i}.B              = 1;
        FilterPara{i}.HighValue      = 1;
        FilterPara{i}.LowValue       = 1;
        FilterPara{i}.NotchValue     = 1;
        FilterPara{i}.ScalingFactor  = 1;
        Index = findstr(handles.ChInfo.Labels(i,:),'ECG');
        Index = [Index findstr(handles.ChInfo.Labels(i,:),'SaO2')];
        Index = [Index findstr(handles.ChInfo.Labels(i,:),'PLTH')];
        if ~isempty(Index)
            FilterPara{i}.Color      = 'r';
        else
            Index = findstr(handles.ChInfo.Labels(i,:),'Leg');
            if ~isempty(Index)
                FilterPara{i}.Color      = 'g';
            else
                
                FilterPara{i}.Color      = 'k';
            end
        end
    end
    
    handles.FilterPara = FilterPara;        
    
    %[Original] Temp = []; Temp => EdfTextHeader;need comment TODO, go back
    % Header in an array, EdfHeaderDescriptionArray
    EdfHeaderDescriptionArray = [];
    
    %%% change variable 'TempText' to reflect the meaning
    TempText = handles.FileInfo.LocalPatientID;
    TempText(TempText==32)=[];
    %[Original] Temp, Temp => EdfTextHeader
    EdfHeaderDescriptionArray{1}=['Patient Name : ' TempText];
    
    TempText = handles.FileInfo.LocalRecordID;
    TempText(TempText==32)=[];
    %[Original] Temp, Temp => EdfTextHeader
    EdfHeaderDescriptionArray{2}=['Patient ID   : ' TempText];
    %[Original] Temp, Temp => EdfTextHeader
    EdfHeaderDescriptionArray{3}=['Start Date   : ' handles.FileInfo.StartDate];
    Temp1=handles.FileInfo.StartTime;
    Temp1([3 6])='::';
    %[Original] Temp, Temp => EdfTextHeader
    EdfHeaderDescriptionArray{4}=['Start Time   : ' Temp1];
    
    
    Counter = 5;
    
    for i=1:length(handles.ChInfo.nr)
        Counter = Counter + 1;
        Temp1 = handles.ChInfo.Labels(i,:);
        if ~isempty(Temp1)
            while Temp1(end)==32 & length(Temp1) > 1
                Temp1(end)=[];
            end
        end
        
        Temp2 = handles.ChInfo.PhyDim(i,:);
        if ~isempty(Temp2)
            while Temp2(end)==32 & length(Temp2) > 1
                Temp2(end)=[];
            end
        end
        
        SamplingRate = fix(handles.ChInfo.nr(i) / handles.FileInfo.DataRecordDuration);
        
        %[Original] Temp, Temp => EdfHeaderDescriptionArray
        EdfHeaderDescriptionArray{Counter} = [Temp1 ' : ' num2str(handles.ChInfo.PhyMin(i)) ' to ' ...
            num2str(handles.ChInfo.PhyMax(i)) ' ' Temp2 ' (' num2str(handles.ChInfo.DiMin(i)) ' to ' ...
            num2str(handles.ChInfo.DiMax(i)) '), SR : ' num2str(SamplingRate)];
        
    end
    
    
    % Next couple of lines buggy for sleep heart health 
    edfHeaderString =  CreateListBoxEdfHeaderString ...
        (hObject, eventdata, handles);
    set(handles.ListBoxPatientInfo,'string',edfHeaderString);
    
    % Get file description, which contains name/date/bytes/isdir/datenum
    %[Original] Temp, Temp => EdfFileAttributes
    EdfFileAttributes = dir(handles.FileName);
    %%%[Original] Temp, Temp => EdfFileAttributes; TODO: determine the total
    %time later from EDF file
    handles.TotalTime = (EdfFileAttributes.bytes - handles.FileInfo.HeaderNumBytes) ...
        / 2  / sum(handles.ChInfo.nr) * handles.FileInfo.DataRecordDuration;
    
    %[Original] Temp, Temp => popup_id; TODO => popMenuWindowTime_value
    popMenuWindowTime_value = get(handles.PopMenuWindowTime,'value');
    %[Original] Temp, Temp => WindowTimeIndexFromList
    WindowTime = handles.epoch_menu_values(popMenuWindowTime_value);
    
    %[Original] Temp, Temp => MaxTime
    MaxTime = handles.TotalTime - WindowTime;
    set(handles.SliderTime, 'max', MaxTime, 'SliderStep', [0.2 1] * WindowTime / MaxTime, 'value', 0)
    
    % Update Flags and Variables before making external calls
    handles.EDF_LOADED = 1;
    handles.hasAnnotation = 0 ;
    handles.XML_LOADED = 0;
    
    % Update figure title
    figureTitle = sprintf('%s: %s',handles.figureDefaultTitle, FileName);
    set(handles.figure1, 'Name', figureTitle);
    
    % Clear Hynogram and Annotations
    cla(handles.axes2);
    set(handles.ListBoxComments, 'String', sprintf(' \n'));
    set(handles.ListBoxComments, 'Value', 1);
    
    % Update data and plot
    handles=DataLoad(handles);
    guidata(hObject, handles);
    handles = UpDatePlot(hObject, handles);
    guidata(hObject, handles);
    
    % Let user know load has been completed
    set(handles.figure1,'pointer', 'arrow');
end
disp('Time opening EDF:');
toc


%--------------------------------------------- CreateListBoxEdfHeaderString
function EdfHeaderString = CreateListBoxEdfHeaderString ...
    (hObject, eventdata, handles)

    % Create debug string
    DEBUG = 0;
    
    %[Original] Temp = []; Temp => EdfTextHeader
    EdfTextHeader=[];
    
    %[Original] TempText
%     TextLocalPatientID = strtrim(handles.FileInfo.LocalPatientID);
    TextLocalPatientID = strtrim(handles.FileInfo.LocalPatientID);
%     TextLocalPatientID(TextLocalPatientID==32)=[]; % TODO, trim string
    %[Original] Temp = []; Temp => EdfTextHeader
    EdfTextHeader{1}=['Patient Name : ' TextLocalPatientID];
    
    %[Original] TempText
    TextLocalRecordID = handles.FileInfo.LocalRecordID;
    TextLocalRecordID(TextLocalRecordID==32)=[];
    %[Original] Temp = []; Temp => EdfTextHeader
    EdfTextHeader{2}=['Patient ID   : ' TextLocalRecordID];
    
    %[Original] Temp = []; Temp => EdfTextHeader
    EdfTextHeader{3}=['Start Date   : ' handles.FileInfo.StartDate];
    %[Original] Temp1; Temp1 => EdfStartTime
    EdfStartTime = handles.FileInfo.StartTime;
    EdfStartTime([3 6])='::'; % change start time from format '21.45.00' to '21:45:00'
    %[Original] Temp = []; Temp => EdfTextHeader
    EdfTextHeader{4}=['Start Time   : ' EdfStartTime];
    
    
    Counter = 5;
    
    for i=1:length(handles.ChInfo.nr)
        if DEBUG == 1
           fprintf('--- CreateListBoxEdfHeaderString Loop (%.0f)',i);  
        end
        
        Counter = Counter + 1;
        %[Original] Temp1; Temp1 => ChannelLabel
        ChannelLabel = handles.ChInfo.Labels(i,:);
        if ~isempty(ChannelLabel)
            while ChannelLabel(end)==32 && length(ChannelLabel)>1 % changed from '&' to '&&'
                ChannelLabel(end)=[];
            end
        end
        
        %[Original] Temp2; Temp2 => ChannelPhyDim
        ChannelPhyDim = handles.ChInfo.PhyDim(i,:);
        if ~isempty(ChannelPhyDim)
            while ChannelPhyDim(end)==32 && length(ChannelPhyDim)>1 % changed from '&' to '&&'
                ChannelPhyDim(end)=[];
            end
        end
        
        SamplingRate = fix(handles.ChInfo.nr(i)/handles.FileInfo.DataRecordDuration);
        
        % Create signal substring
        signalStr = '          ';
        signalStr(1:length(ChannelLabel)+1) = [ChannelLabel ':'];
        
        % Create physical dimension string
        phyMinValueStr = num2str(handles.ChInfo.PhyMin(i));
        phyMinStr = '    ';
        %phyMinValueStr
        %%%  Double check this value 
        % phyMinStr(end-length(phyMinValueStr)+1:end) = phyMinValueStr;
        phyMinStr = phyMinValueStr;
        % handles.ChInfo.PhyMax(i)
        phyMaxValueStr = num2str(handles.ChInfo.PhyMax(i));
        phyMaxStr = '    ';
        phyMaxStr(1:length(phyMaxValueStr)) = phyMaxValueStr;
        phyStr = sprintf('%s to %s',phyMinStr, phyMaxStr);
        
        % Create physical dimension string
        digMinValueStr = num2str(handles.ChInfo.DiMin(i));
        digMinStr = '                ';
        digMinStr(end-length(phyMinValueStr) + 1:end) = phyMinValueStr;
        digMaxValueStr = num2str(handles.ChInfo.DiMax(i));
        digMaxStr = '      ';
        digMaxStr(1:length(digMaxValueStr)) = digMaxValueStr;
        digStr = sprintf('%s to %s',digMinStr, digMaxStr);
        
        % Sampling rate string
        samRateStr = num2str(SamplingRate);
        
        lineStr = sprintf('%s %s (%s), SR:  %s', ...
            signalStr, phyStr, digStr, samRateStr);
        
        %[Original] Temp = []; Temp => EdfTextHeader
        EdfTextHeader{Counter} = lineStr;
        
    end
% Create header string   
%[Original] Temp = []; Temp => EdfTextHeader
EdfHeaderString = EdfTextHeader;


%----------------------------------------------- PopMenuWindowTime_Callback
% --- Executes on selection change in PopMenuWindowTime.
function PopMenuWindowTime_Callback(hObject, eventdata, handles)
% hObject    handle to PopMenuWindowTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopMenuWindowTime contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopMenuWindowTime

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Get menu entry
popup_id = get(handles.PopMenuWindowTime,'value'); %TODO popup_id => PopMenuWindowTime_value
%[Original] epoch_length; variable name conflict with previous function
WindowTime = handles.epoch_menu_values(popup_id);

%[Original] Temp; Temp => MaxTime
MaxTime = handles.TotalTime - WindowTime;
if  MaxTime < get(handles.SliderTime,'value')
    set(handles.SliderTime, 'max', MaxTime, 'SliderStep', [0.2 1] * WindowTime / MaxTime, 'value', MaxTime)
else
    set(handles.SliderTime, 'max', MaxTime, 'SliderStep', [0.2 1] * WindowTime / MaxTime)
end

handles = DataLoad(handles);
% save GUI state
guidata(hObject,handles); 
handles = UpDatePlot(hObject,handles);
guidata(hObject, handles);


%------------------------------------------------------ SliderTime_Callback
% --- Executes on slider movement.
function SliderTime_Callback(hObject, eventdata, handles)
% hObject    handle to SliderTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Get slider value
sliderValue = round(get(hObject,'value'));
set(hObject,'value',sliderValue);

% Add annotation if they exist
if handles.hasAnnotation
    % find the closest comments
    %%% change variable 'Temp' to reflect the meaning
    %[Original] Temp = []; Temp => StartTimes; TODO ScoredEvent_StartTime;
    StartTimes = [];
    for i = 1:length(handles.ScoredEvent)
        StartTimes(i) = handles.ScoredEvent(i).Start;
    end
    StartTimes = StartTimes - get(handles.SliderTime, 'value');
    [StartTimes, Index] = min(abs(StartTimes));
    set(handles.ListBoxComments, 'value', Index);
end

% Get, update, and display data
handles=DataLoad(handles);
guidata(hObject,handles);
handles = UpDatePlot(hObject,handles);
guidata(hObject, handles);


%----------------------------------------------------------------- DataLoad
function handles = DataLoad(handles)
% DataLoad rewritten to access data loaded with block load.

% Access epoch
popup_id = get(handles.PopMenuWindowTime,'value'); % index of menu window time corresponding to sec value
WindowTime = handles.epoch_menu_values(popup_id);
Time = get(handles.SliderTime,'value');

FileName = handles.FileName;

fid=fopen(FileName,'r');

SkipByte=handles.FileInfo.HeaderNumBytes+fix(Time/handles.FileInfo.DataRecordDuration) ...
    *sum(handles.ChInfo.nr)*2;
fseek(fid,SkipByte,-1);

% Data=[]; 2014-11-03, preallocate cell array, by Wei
Data = cell(handles.FileInfo.SignalNumbers);
for i=1:handles.FileInfo.SignalNumbers
    Data{i}=[];
end

% Sec/handles.DatarecordDuration is the number of
for i=1 : WindowTime/handles.FileInfo.DataRecordDuration
    for j=1:handles.FileInfo.SignalNumbers
        Data{j}= [Data{j} fread(fid,[1 handles.ChInfo.nr(j)],'int16') ];
    end
end
fclose('all');

handles.Data = Data;
handles=DataNormalize(handles);
Data = handles.Data;

handles.Data=[];
SelectedCh = handles.SelectedCh;
FilterPara = handles.FilterPara;


% construct the selected referential and differential channels
for i=1:size(SelectedCh,1)
    if SelectedCh(i,2)==0
        % referential
        handles.Data{i}=Data{SelectedCh(i,1)};
    else
        % differential
        handles.Data{i}=Data{SelectedCh(i,1)}-Data{SelectedCh(i,2)};
    end
    
    % Filtering
    handles.Data{i} = filter(FilterPara{i}.B,FilterPara{i}.A,handles.Data{i});
    
end


function handles = DataNormalize(handles)

for i=1:length(handles.Data)
    % remove the mean
    handles.Data{i}=handles.Data{i}-(handles.ChInfo.DiMax(i)+handles.ChInfo.DiMin(i))/2;
    handles.Data{i}=handles.Data{i}./(handles.ChInfo.DiMax(i)-handles.ChInfo.DiMin(i));
    if handles.ChInfo.PhyMin(i)>0
        handles.Data{i}=-handles.Data{i};
    end
end


%--------------------------------------------------------------- UpDatePlot
function handles = UpDatePlot(hObject, handles)
%%% hasSleepStages = 0; % TODO 
% set the epoch number
% each epoch has been considered as 30 sec
% get  current epoch length
% Set epcoh values based on slider time
SliderTime = get(handles.SliderTime, 'value');
epochTime30Sec = fix(SliderTime / 30) + 1;
popup_id = get(handles.PopMenuWindowTime, 'value');
epoch_length = handles.epoch_menu_values(popup_id);
epoch = fix(SliderTime/epoch_length) + 1; 
SliderMax = get(handles.SliderTime, 'Max');
epochMax = fix(SliderMax/epoch_length) + 1; 
epochMax30Sec = fix(SliderMax/30) + 1; 

set(handles.EditEpochNumber, 'string', num2str(epoch));
totalString = sprintf('of %.0f (%.0f)', epochMax, epochMax30Sec);
set(handles.textTotalEpochs,'String', totalString);
epochsString = sprintf('%.0f (%.0f)', epoch, epochTime30Sec);
set(handles.textCurrent30secEpochs, 'String', epochsString);

% Plot the data
axes(handles.axes1);
c_axes = handles.c_axes;

% not sure why this is need, throws an exception when clicking on the 
% histogram
cla
hold on

% get the window width
popup_id = get(handles.PopMenuWindowTime,'value');
WindowTime = handles.epoch_menu_values(popup_id);

SelectedCh = handles.SelectedCh;

% Identify channels to plot   %%% TODO
%[Original] SelectedChMap = [];
SelectedChMap = cell(length(SelectedCh), 1);
for i=1:size(SelectedCh,1)
    if SelectedCh(i,2) == 0
        SelectedChMap{i,1} = handles.ChInfo.Labels(SelectedCh(i,1),:);
    else
        SelectedChMap{i,1} = [handles.ChInfo.Labels(SelectedCh(i,1),:) '-' handles.ChInfo.Labels(SelectedCh(i,2),:)];
    end
    SelectedChMap{i,1}((SelectedChMap{i,1}==' '))=[];
end

% Process Annotations, if present
if handles.hasAnnotation
    % plot sleep stage line
    popup_id = get(handles.PopMenuWindowTime,'Value');
    epoch_width = handles.epoch_menu_values(popup_id);
    epoch_width = max(epoch_width, handles.minimum_cursor_width);
    if handles.hasSleepStages %%% TODO
        set(handles.LineSleepStage,...=
            'xData',[-1 -1 1 1 -1] * epoch_width / 2 + get(handles.SliderTime,'value') + epoch_width/2);
        set(handles.LineSleepStage,'FaceAlpha',0.5);
        set(handles.LineSleepStage,'EdgeColor', 'r');
    end
    
    % Get scored event time
    %[Original] Start = [];
    Start = [];
    for i=1:length(handles.ScoredEvent)
        Start(i) = handles.ScoredEvent(i).Start;
    end
    
    CurrentTime = get(handles.SliderTime,'value');
        
    if ~handles.PlotType  % handles.PlotType is 0 for PhysioMIMI file
        % Annotation plot        
        % Forward Plot
        Index = find(Start > CurrentTime & Start < (CurrentTime + WindowTime));
        
        if ~isempty(Index)            
            ChNum=3; %% Will display channels on 5, 6 channel
            %[Original] Start =[];
            Start = [];
            for i=1:length(Index)
                Start(i) = handles.ScoredEvent(Index(i)).Start - CurrentTime;
                %%% change variable 'Temp' to reflect the meaning
                Temp = Start(i) + handles.ScoredEvent(Index(i)).Duration;
                
                if Temp > WindowTime
                    Temp = WindowTime;
                end
                
                fill([Start(i)  Temp Temp Start(i)], ...
                    [-ChNum-3/2 -ChNum-3/2 -ChNum-1/2 -ChNum-1/2 ]...
                    ,[190 222 205]/255);   % TODO: fill green bar under selected chanel
                
                plot([Start(i)  Temp Temp Start(i) Start(i)], ...
                    [-ChNum-3/2 -ChNum-3/2 -ChNum-1/2 -ChNum-1/2 -ChNum-3/2]...
                    ,'Color',[1 1 1]);
            end
        end
        
        % Annotation text
        if ~isempty(Index)
            for i=1:3:length(Index)
                text(Start(i),-ChNum-0.65,handles.ScoredEvent(Index(i)).EventConcept,'FontWeight','bold','FontSize',9)
            end
        end
    
        
        % Reverse plot added --- Jan 22, 2013
        %[Original] Temp = []; Temp => EndTime; ScoredEvent_EndTime TODO
        %[Original] Start = [];
        EndTime = [];
        Start = [];
        for i=1:length(handles.ScoredEvent)
            EndTime(i)=handles.ScoredEvent(i).Start+handles.ScoredEvent(i).Duration;
            Start(i)=handles.ScoredEvent(i).Start;
        end
        IndexReverse = find((EndTime)>=CurrentTime & EndTime <= (CurrentTime+WindowTime));
        IndexReverse = [IndexReverse find(Start<=CurrentTime & EndTime >= (CurrentTime+WindowTime) )];
        
        
        for i = 1:length(Index)
            IndexReverse(IndexReverse == Index(i)) = [];
        end
        
        
        Start = Start(IndexReverse) - CurrentTime;        
        if ~isempty(IndexReverse)
            
            ChNum = [];
            for j = IndexReverse
                ChNum = [ChNum 6];
            end
            
            for i = 1:length(IndexReverse)
                Temp = Start(i) + handles.ScoredEvent(IndexReverse(i)).Duration;
                
                fill([0  Temp Temp 0], ...
                    [-ChNum(i)-3/2 -ChNum(i)-3/2 -ChNum(i)-1/2 -ChNum(i)-1/2 ]+2 ...
                    ,[190 222 205]/255);   %%% TODO: fill green bar under selected channel
                
                plot([0  Temp Temp 0 0], ...
                    [-ChNum(i)-3/2 -ChNum(i)-3/2 -ChNum(i)-1/2 -ChNum(i)-1/2 -ChNum(i)-3/2]+2 ...
                    ,'Color',[1 1 1]);
                text(0,-ChNum(i)-0.65+2,handles.ScoredEvent(IndexReverse(i)).EventConcept,'FontWeight','bold','FontSize',9)
            end
        end                        
    else                
        % Forward Plot
        Index = find(Start>CurrentTime & ...
            Start < (CurrentTime+WindowTime));
        
        if ~isempty(Index)
            Start = Start(Index)-CurrentTime;
            ChNum = [];
            for j = Index
                for i=1:size(handles.ChInfo.Labels,1)
                    if  strncmp(upper(handles.ChInfo.Labels(i,:)),[upper(handles.ScoredEvent(j).InputCh) ' '],...
                            length(handles.ScoredEvent(j).InputCh+1))
                        ChNum=[ChNum i];
                    end
                end
            end
            
            for i=1:length(Index)
                Temp=Start(i)+handles.ScoredEvent(Index(i)).Duration;
                
                if Temp>WindowTime
                    Temp=WindowTime;
                end
                
                if ~isempty(ChNum)
                    ChNum = ChNum(end);
                    fill([Start(i)  Temp Temp Start(i)], ...
                        [-ChNum-3/2 -ChNum-3/2 -ChNum-1/2 -ChNum-1/2 ]+2 ...
                        ,[190 222 205]/255);   %%% TODO: fill gree...
                    
                    plot([Start(i)  Temp Temp Start(i) Start(i)], ...
                        [-ChNum-3/2 -ChNum-3/2 -ChNum-1/2 -ChNum-1/2 -ChNum-3/2]+2 ...
                        ,'Color',[1 1 1]);

                    text(Start(i),-ChNum-0.65+2,handles.ScoredEvent(Index(i)).EventConcept,'FontWeight','bold','FontSize',9)
                end
            end                        
        end
        
        % Reverse Plot
        %[Original] Temp = []; Temp => EndTime
        %[Original] EndTime = []; Start = []
        EndTime = [];
        Start = [];
        for i=1:length(handles.ScoredEvent)
            EndTime(i) = handles.ScoredEvent(i).Start + handles.ScoredEvent(i).Duration;
            Start(i) = handles.ScoredEvent(i).Start;
        end
        IndexReverse = find((EndTime)>=CurrentTime & EndTime <= (CurrentTime+WindowTime));
        IndexReverse = [IndexReverse find(Start<=CurrentTime & EndTime >= (CurrentTime+WindowTime) )];
        
        for i=1:length(Index)
            IndexReverse(IndexReverse==Index(i))=[];
        end
        
        Start = Start(IndexReverse)-CurrentTime;
        if ~isempty(IndexReverse)
            
            ChNum=[];
            for j=IndexReverse
                for i=1:size(handles.ChInfo.Labels,1)
                    % Check for each signal that has the prefix of the
                    % assoicated values
                    if  strncmp(upper(handles.ChInfo.Labels(i,:)),[upper(handles.ScoredEvent(j).InputCh) ' '],...
                            length(handles.ScoredEvent(j).InputCh+1))
                        ChNum=[ChNum i];
                    end
                end
            end
            
            for i=1:length(IndexReverse)
                Temp=Start(i)+handles.ScoredEvent(IndexReverse(i)).Duration;
                if length(ChNum)>1
                    ChNum = ChNum(1);
                end
                
                if ~isempty(ChNum)
                    fill([0  Temp Temp 0], ...
                        [-ChNum-3/2 -ChNum-3/2 -ChNum-1/2 -ChNum-1/2 ]+2 ...
                        ,[190 222 205]/255); %%% Fill green bar under selected channel

                    plot([0  Temp Temp 0 0], ...
                        [-ChNum-3/2 -ChNum-3/2 -ChNum-1/2 -ChNum-1/2 -ChNum-3/2]+2 ...
                        ,'Color',[1 1 1]);                

                    text(0,-ChNum-0.65+2,handles.ScoredEvent(IndexReverse(i)).EventConcept,'FontWeight','bold','FontSize',9);
                end
            end  
        end
    end
    
% Set epoch values based on slider time
SliderTime = get(handles.SliderTime,'value');
epochTime30Sec = fix(SliderTime/30)+1;
epochPopupValue = get(handles.PopMenuWindowTime,'value');
epoch_length = handles.epoch_menu_values(epochPopupValue);
epoch = fix(SliderTime/epoch_length)+1; 
SliderMax = get(handles.SliderTime,'Max');
epochMax = fix(SliderMax/epoch_length)+1; 
epochMax30Sec  = fix(SliderMax/30)+1; 

set(handles.EditEpochNumber,'string',num2str(epoch));
totalString = sprintf('of %.0f (%.0f)',epochMax, epochMax30Sec);
set(handles.textTotalEpochs,'String',totalString);
epochsString = sprintf('%.0f (%.0f)',epoch,epochTime30Sec);
set(handles.textCurrent30secEpochs,'String',epochsString);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Signals Plot
% FilterPara = evalin('base','FilterPara');
FilterPara = handles.FilterPara;

Counter = 0;
scaled_data_range = [];
auto_scale_factor = handles.auto_scale_factor;
for i=1:size(SelectedCh,1)
    % Get data, recenter and plot
    Time = [0:size(handles.Data{i},2)-1]/size(handles.Data{i},2)*WindowTime;
    PlotColor = FilterPara{i}.Color;
    Y = (handles.Data{i}*FilterPara{i}.ScalingFactor-Counter - ...
        mean(handles.Data{i}*FilterPara{i}.ScalingFactor-Counter))+(1-i);
    plot(Time,Y,'LineWidth',0.01,'color',PlotColor);
    
    % Not sure is this is still being used, 1/27/2013, dad
    Counter = Counter + 1 ;
        
    % Store Current Scaling Factor
    auto_scale_factor (i) = FilterPara{i}.ScalingFactor;
    scaled_data_range = [scaled_data_range;...
        [min(handles.Data{i}*FilterPara{i}.ScalingFactor),...
         max(handles.Data{i}*FilterPara{i}.ScalingFactor)]];    
end

% Determine Optimal Range
data_range = scaled_data_range(:,2) - scaled_data_range(:,1);
index = find(data_range ~= 0);
handles.auto_scale_factor(index) = handles.auto_scale_height./data_range(index);
guidata(hObject, handles);

% Stage information
if handles.hasSleepStages %%% TODO
 if and(handles.hasAnnotation, epoch_length == 30)
     % plot sleep states
     %%% TODO temporal approach to handles index out of range error
%      if get(handles.SliderTime, 'value') + WindowTime > length(handles.SleepStages)
%          newVal = length(handles.SleepStages) - WindowTime;
%      else 
%          newVal = get(handles.SliderTime, 'value');
%      end
     Temp=handles.SleepStages([1:WindowTime]+get(handles.SliderTime,'value'));
%      Temp=handles.SleepStages([1:WindowTime]+newVal);
     Temp = Temp - min(Temp);
     if max(Temp)>0
         Temp = Temp / max(Temp) - 0.25;
     end
     plot([0:length(Temp)-1],Temp+1,'linewidth',1.5,'color','k')
     
     % comment for sleep stage
     if sum(abs(diff(Temp))>0)
         % there is more than one sleep state
         Index = [1 find(diff(Temp))+1];
         
         for i=1:length(Index)
             TempState = (handles.SleepStages(get(handles.SliderTime,'value')+Index(i)));
             switch TempState
                 case 5
                     TempState = 'W';
                 case 4
                     TempState = 'N1';
                 case 3
                     TempState = 'N2';
                 case 2
                     TempState = 'N3';
                 case 1
                     TempState = 'N4';
                 case 0
                     TempState = 'N5';
             end
             
             if Temp(Index(i))>0
                 text(Index(i),Temp(Index(i))+0.75,['State: ' TempState],'fontweight','bold');
             else
                 text(Index(i),Temp(Index(i))+1.25,['State: ' TempState],'fontweight','bold');
             end
         end
         
     else
         TempState = handles.SleepStages(get(handles.SliderTime,'value')+1);
         switch TempState
             case 5
                 TempState = 'W';
             case 4
                 TempState = 'N1';
             case 3
                 TempState = 'N2';
             case 2
                 TempState = 'N3';
             case 1
                 TempState = 'N4';
             case 0
                 TempState = 'N5';
         end
         
         text(WindowTime/2,1.5,['State ' TempState],'fontweight','bold')
     end
end
end

% Set the yTick
YTick = [(-length(handles.Data)+1):0];
set(handles.axes1,'YTick',YTick);

% Set the ylim

ylim([-length(handles.Data) 2]);
set(handles.axes1,'YTickLabel',SelectedChMap([length(SelectedChMap):-1:1]))


% Set the xTick based on the window size
epoch_menu_value = get(handles.PopMenuWindowTime,'value');
epoch_length = handles.epoch_menu_values(epoch_menu_value);
epoch_menu_num_tick_sections = ...
    handles.epoch_menu_num_tick_sections(epoch_menu_value);
increment = 1/epoch_menu_num_tick_sections;

XTick=[0:increment:1]*epoch_length;
Temp = XTick + get(handles.SliderTime,'value');
Temp = datestr(Temp/86400,'HH:MM:SS');
set(handles.axes1,'XTick',XTick,'xTickLabel',Temp,'xlim',[0 epoch_length]);

hold off
grid on

% change the color of xtick and ytick
xtick = get(handles.axes1,'XTick');
ytick = get(handles.axes1,'YTick');
xlim = get(handles.axes1,'XLim');
ylim1 = get(handles.axes1,'YLim');

% Copy the existing axis along with children
set(handles.axes1,'TickLength',[1e-100 1])
c_axes = copyobj(handles.axes1,handles.figure1);
% assignin('base','c_axes',c_axes);
handles.c_axes = c_axes;

% Remove copy of objects
delete(get(c_axes,'Children'))

% Set color XColor to red and only show the grid
set(c_axes, 'Color', 'none', 'XColor', [192 192 1]/255, 'XGrid', 'on', ...
    'YColor',[192 192 1]/255, 'YGrid','on','XTickLabel',[], ...
    'YTickLabel',[],'XTick',xtick,'YTick',ytick,'XLim',xlim,'YLim',ylim1);



% Set epoch numbers

% Update handles
% (list handle updates here)
guidata(hObject, handles);


% ------------------------------------------------ MenuChSelection_Callback
function MenuChSelection_Callback(hObject, eventdata, handles)
% hObject    handle to MenuChSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Create Channel Selection Structure
channelSelectionStruct.ChSelectionH = handles.ChSelectionH;
channelSelectionStruct.SelectedCh = handles.SelectedCh;
channelSelectionStruct.ChInfo = handles.ChInfo;
channelSelectionStruct.FilterPara = handles.FilterPara;

channelSelectionStruct.FlagSelectedCh = handles.FlagSelectedCh;
channelSelectionStruct.FlagChInfo = handles.FlagChInfo;

% Open Channel Selection Dialog Box
channelSelectionStruct = ChSelection(channelSelectionStruct);


% Update local handle 
handles.ChSelectionH = channelSelectionStruct.ChSelectionH;
handles.SelectedCh = channelSelectionStruct.SelectedCh;
handles.ChInfo = channelSelectionStruct.ChInfo;
handles.FilterPara = channelSelectionStruct.FilterPara;
% 
handles.FlagSelectedCh = channelSelectionStruct.FlagSelectedCh;
handles.FlagChInfo = channelSelectionStruct.FlagChInfo;
% 
handles=DataLoad(handles);
guidata(hObject,handles);
handles = UpDatePlot(hObject, handles);


% ----------------------------------------------------- MenuFilter_Callback
function MenuFilter_Callback(hObject, eventdata, handles)
% hObject    handle to MenuFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Create structure containing filter settings
filterSettingsStruct.FilterSettingH = handles.figure1;
filterSettingsStruct.SelectedCh = handles.SelectedCh;
filterSettingsStruct.ChInfo = handles.ChInfo;
filterSettingsStruct.FileInfo = handles.FileInfo;
filterSettingsStruct.FilterPara = handles.FilterPara;
filterSettingsStruct.Sel = handles.Sel;

% Open Filter Setting GUI
filterSettingsStruct = FilterSettings(filterSettingsStruct);

% Get filter setting information
% Create structure containing filter settings
handles.FilterSettingH = filterSettingsStruct.FilterSettingH;
handles.SelectedCh = filterSettingsStruct.SelectedCh;
handles.ChInfo = filterSettingsStruct.ChInfo;
handles.FileInfo = filterSettingsStruct.FileInfo;
handles.FilterPara = filterSettingsStruct.FilterPara;
handles.Sel = filterSettingsStruct.Sel;

% Load and plot data
handles=DataLoad(handles);
guidata(hObject,handles);
handles = UpDatePlot(hObject, handles);
% assignin('base','FilterSettingH',[]);

% turn this off; since UpDatePlot updates handles, may have to create a
% return structure
% handles.FilterSettingH = handles.FilterSettingH;
guidata(hObject, handles);

%------------------------------------------------- ListBoxComments_Callback
% --- Executes on selection change in ListBoxComments.
function ListBoxComments_Callback(hObject, eventdata, handles)
% hObject    handle to ListBoxComments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ListBoxComments contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListBoxComments

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end
handles = guidata(hObject); %%%

Sel = get(hObject,'value');
fprintf('listbox size: %d\n', length(handles.eventIndexInCategory));
SelNum = handles.eventIndexInCategory(Sel);
fprintf('Selected index: Sel#: %d\n',Sel);
fprintf('selected event number: SelNum# %d\n', SelNum);
fprintf('handles.ScoredEvent size: # %d\n', length(handles.ScoredEvent));
fprintf('Sleep Stages Number: # %d\n', length(handles.SleepStages));
% Change tooltip

set(handles.ListBoxComments, 'ToolTip', handles.ScoredEvent(SelNum).ToolTip);

popMenuWindowTime_value = get(handles.PopMenuWindowTime, 'value');
ListOfPopMenuWindowTimes = get(handles.PopMenuWindowTime, 'string');
CurrentPopMenuWindowTime = ListOfPopMenuWindowTimes{popMenuWindowTime_value};
WindowTime = str2num(CurrentPopMenuWindowTime(1:end-3));

% added check field(handles.ScoredEvent), Wei, 2014-11-09
% bug fixed: when select non-exist list of events after loading EDF file
% and before loading annotation(XML) file
if isfield(handles, 'ScoredEvent') % added check field(handles.ScoredEvent)
    CurrentPopMenuWindowTime = WindowTime - handles.ScoredEvent(SelNum).Duration; % Sel has problems TODO%%%

    if CurrentPopMenuWindowTime > 0 %%%[Original] has problems TODO
        Time = handles.ScoredEvent(SelNum).Start-CurrentPopMenuWindowTime/2;%
    else
        Time = handles.ScoredEvent(SelNum).Start; %[Original]
    end
    set(handles.SliderTime,'value',fix(Time)); %[Original]
    fprintf('Selected slider value: #: %d\n', get(handles.SliderTime, 'value'));
end

if get(handles.SliderTime, 'value') <= length(handles.SleepStages) - WindowTime
    % Fixed bug: updataPlot error issue(sliderTime value exceeds sleepstages length)
    handles=DataLoad(handles);
    guidata(hObject,handles);
    handles = UpDatePlot(hObject,handles);
    guidata(hObject, handles);
end

%-------------------------------------------------- figure1_CloseRequestFcn
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure


% Original program used the workspace to pass variable information. Which 
% can cause the program to hang.  Added Try- catch to by pass hanging
% code.  A good fix is to save infomration in handles.

try
%     Temp=evalin('base','ChSelectionH');
%     if ~isempty(Temp)
%         delete(Temp);
%     end
%     
%     Temp=evalin('base','FilterSettingH');
%     if ~isempty(Temp)
%         delete(Temp);
%     end
    
    close('ChSelection.fig');
    
    % Note: Not sure what these values are
    % Saved to handles just in case
    %%% what is ChSelectionH?
    ChSelectionH = handles.ChSelectionH;
    if ~isempty(ChSelectionH)
        delete(ChSelectionH);
    end

    FilterSettingH = handles.FilterSettingH;
    if ~isempty(FilterSettingH)
        delete(FilterSettingH);
    end    
    
catch err
    % just close
    
end

try
    
    % Note: Not sure what these values are
    % Saved to handles just in case
    ChSelectionH = handles.ChSelectionH;
    if ~isempty(ChSelectionH)
        delete(ChSelectionH);
    end

    FilterSettingH = handles.FilterSettingH;
    if ~isempty(FilterSettingH)
        delete(FilterSettingH);
    end    
    
catch err
    % just close

end

try 
    delete(hObject);
catch err
    % just close
end

%------------------------------------------------- EditEpochNumber_Callback
function EditEpochNumber_Callback(hObject, eventdata, handles)
% hObject    handle to EditEpochNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditEpochNumber as text
%        str2double(get(hObject,'String')) returns contents of EditEpochNumber as a double

Temp = get(handles.PopMenuWindowTime,'value');
Temp1 = get(handles.PopMenuWindowTime,'string');
Temp = Temp1{Temp};
WindowTime = str2num(Temp(1:end-3));

if WindowTime<30
    WindowTime = 30;
end

EpochNumber = str2num(get(hObject,'string'));
MaxEpoch = (handles.TotalTime - WindowTime)/30+1;

if EpochNumber>MaxEpoch
    EpochNumber = MaxEpoch;
    set(hObject,'string',num2str(EpochNumber));
end

set(handles.SliderTime,'value',(EpochNumber-1)*30);

if handles.hasAnnotation
    % find the closest comments
    Temp=[];
    for i=1:length(handles.ScoredEvent)
        Temp(i)=handles.ScoredEvent(i).Start;
    end
    Temp = Temp - get(handles.SliderTime,'value');
    [Temp Index]=min(abs(Temp));
    set(handles.ListBoxComments,'value',Index);
end

handles=DataLoad(handles);
guidata(hObject,handles);
handles = UpDatePlot(hObject,handles);

guidata(hObject, handles);

% ---------------------------------------------------- MenuOpenXML_Callback
function MenuOpenXML_Callback(hObject, eventdata, handles)
% hObject    handle to MenuOpenXML (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
handles = guidata(hObject);

if handles.EDF_CHECK == 0
    return
else
    % should clean last open file cache, wei wang, Jan, 15, 2015
    %handles.hasSleepStages = 0;    
    %handles.eventIndexInCategory = [];
    clearOpenCache;
    set(handles.pmAnnotations, 'string', ''); 
    set(handles.ListBoxComments, 'string', '');
end

global needOpenDialog;
global XmlFilePath;
global XmlFileName;

%[Original] Temp; Temp => EdfFileName
EdfFileName = handles.FileName;
EdfFileName([-3:0] + end) = [];
if needOpenDialog
    [FileNameAnn, FilePath] = uigetfile([EdfFileName '*.xml'],'Open XML File');
else
    FileNameAnn = XmlFileName;
    FilePath = XmlFilePath;
end

if FileNameAnn == 0 & FilePath == 0
    return
end
%%% structure to be considered

try 
    annObj = loadPSGAnnotationClass([FilePath, FileNameAnn]);    
    % annObj.loadFile process:
    %   1. Open file
    %   2. parseNodes, including check of tag existance
    %   3. validateEvents, validate fields and event names
    annObj.errMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
	annObj = annObj.loadFile;
	handles.ScoredEvent = annObj.ScoredEvent;
    handles.EpochLength = annObj.EpochLength;
    handles.SleepStages = annObj.sleepStageValues; 
    fprintf('Event Number: %d\n', length(handles.ScoredEvent));
    fprintf('Epoch Length: %d\n', handles.EpochLength);
    fprintf('Stage Number: %d\n', length(handles.SleepStages));
    
    if ~isempty(annObj.errMap) %annObj.errList
        % display errors
          result = values(annObj.errMap);
          msg = {};
          for i=1:length(result)
              msg{end+1} = result{i};
          end
          disp('----------------------')
          for i=1:length(msg)
              disp(msg{i});
          end
          errordlg(msg, 'XML Event Error', 'modal');
    end
%     fprintf('Available event types: %s', annObj.availableEventTypes);
    availableEventTypes = {'All'};
    for i=1:length(annObj.availableEventTypes)
        if ~isempty(annObj.availableEventTypes{i})
            availableEventTypes{end+1} = annObj.availableEventTypes{i};
        end
    end
    disp(availableEventTypes);
    handles.availableEventTypes = availableEventTypes;
    guidata(hObject, handles);
    set(handles.pmAnnotations, 'string', availableEventTypes);    % record and show event types(in array)
    
    % Display basic info:
    numScoredEvents = length(annObj.ScoredEvent);
    fprintf('============== Basic info =================\n')
    fprintf('Number of scored events = %0.0f\n',numScoredEvents);
    fprintf('Number of epochs = %0.0f\n',length(handles.SleepStages));
    fprintf('Epoch length = %0.0f\n', handles.EpochLength);
    fprintf('===========================================\n')
catch exception
 	errMsg = sprintf('Could not load: %s', [FilePath, FileNameAnn]);
    errordlg(errMsg, 'Fatal Error', 'modal')
end

handles.hasAnnotation = 1;
% if there is ann file
if ~(sum(FileNameAnn == 0)) % if this file name is not empty string, use ~isempty() instead
    % check for the version of xml
    Fid = fopen([FilePath FileNameAnn], 'r');
    % TODO should use fileread(filename)
    Temp = fread(Fid,[1 inf],'uint8'); % not efficient
    fclose(Fid);
    isPSG = strfind(Temp,'PSGAnnotation');
    isCompumedics = strfind(Temp,'Compumedics');
   
    % Determine file type
    if isempty(isPSG)
        % it is compumedics ann file
        %%% What is hasAnnotationType stands for, for example 1(or 0) 
        handles.hasAnnotationType = 1;
        [handles.ScoredEvent, handles.SleepStages, handles.EpochLength]=...
            readXML_Com([FilePath FileNameAnn]);
        handles.PlotType = 1;
         
        %%% change variable 'Temp' to reflect the meaning
        Temp = [];
        for i=1:length(handles.SleepStages)
            Temp = [Temp ones(1,30) * handles.SleepStages(i)];
        end
        handles.SleepStages = Temp;
    else
        % it is PhysiMIMI file
        if ~isempty(isCompumedics)
            handles.hasSleepStages = 1; %%% TODO set hasSleepStages 
            handles.PlotType = 1; %%% Added 1-30-2015
        end

        handles.hasAnnotationType = 0;
        % handles.ScoredEvent is an array of event structure
        % eventStruct = struct('EventConcept','Start','Duration','SpO2Baseline','SpO2Nadir');
        handles.PlotType = 1;
    end
    
    % Create list box contents TODO: extract into another function
    % ListBox Comments annotation %%% TODO
    Temp = cell(1, length(handles.ScoredEvent));
    handles.eventIndexInCategory(1) = 1;
    for i=1:length(handles.ScoredEvent)
       Temp1 = fix(handles.ScoredEvent(i).Start / 30) + 1;
       Temp{i}= [num2str(Temp1) ' - ' datestr(handles.ScoredEvent(i).Start/86400,'HH:MM:SS - ') handles.ScoredEvent(i).EventConcept];
       handles.eventIndexInCategory(i) = i;
    end
    set(handles.ListBoxComments, 'string', Temp);
    
    % Plot histogram
    if handles.hasSleepStages
        handles = plotHistogram(hObject, handles);
    else
        % turn off histogram
        turnOffHistogram(handles)
    end
    
    % Record xml load
    handles.XML_LOADED = 1;
    guidata(hObject, handles);
    
    handles=DataLoad(handles);
    guidata(hObject,handles);
    handles = UpDatePlot(hObject, handles);
    guidata(hObject, handles);
else
    if handles.XML_LOADED == 0
    end
end

%------------------------------------------------ figure1_WindowKeyPressFcn
% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Select the signal to present
Loc=get(handles.axes1,'CurrentPoint');
Sel = round(Loc(1,2));
if Sel>0
    Sel = 0;
end
Sel = abs(Sel)+1;

% Get current character
currentCharacter = get(hObject,'CurrentCharacter')+0;

% Process current character
if currentCharacter == handles.UP_ARROW_KEY
    % Process up arrow key, increase signal scaling factor
    RESCALE_ALL_SIGNALS = 0;
    
    % check if ctrl key is set
    if ~isempty(eventdata.Modifier)
       % Modifier key is set, check if control key is set
       if strcmp(eventdata.Modifier{1},'control') == 1
           RESCALE_ALL_SIGNALS = 1;
       end    
    end
  
    % Get filter parameters
    FilterPara = handles.FilterPara;
    
    % Reset parametrs based on key combinations
    if RESCALE_ALL_SIGNALS == 0
        FilterPara{Sel}.ScalingFactor = ...
            fix(FilterPara{Sel}.ScalingFactor * 115)/100;
    else
        
        for s = 1:length(FilterPara)
            FilterPara{s}.ScalingFactor = ...
                fix(FilterPara{s}.ScalingFactor * 115)/100;
        end
    end
    
    % Save new filter paramters and update plot
    handles.FilterPara = FilterPara;
    guidata(hObject,handles);
    handles = UpDatePlot(hObject,handles);
    guidata(hObject,handles);
elseif currentCharacter == handles.DOWN_ARROW_KEY
    % Process down arrow key, decrease signal scale
    
    % Set signals to rescale
    RESCALE_ALL_SIGNALS = 0;
    
    % check if ctrl key is set
    if ~isempty(eventdata.Modifier)
       % Modifier key is set, check if control key is set
       if strcmp(eventdata.Modifier{1},'control') == 1
           RESCALE_ALL_SIGNALS = 1;
       end    
    end
    
    % FilterPara = evalin('base','FilterPara');
    FilterPara = handles.FilterPara;
    
    % Reset parametrs based on key combinations
    if RESCALE_ALL_SIGNALS == 0
        FilterPara{Sel}.ScalingFactor = ...
            fix(FilterPara{Sel}.ScalingFactor * 85)/100;
    else
        
        for s = 1:length(FilterPara)
            FilterPara{s}.ScalingFactor = ...
                fix(FilterPara{s}.ScalingFactor * 85)/100;
        end
    end    
    
    
    % Save new scaling factors and update plot
    handles.FilterPara = FilterPara;
    guidata(hObject,handles);
    handles = UpDatePlot(hObject,handles);
    guidata(hObject,handles);
elseif currentCharacter == handles.RIGHT_ARROW_KEY
    % Process right arrow
    
    % Get display epoch width
    epochPopupIndex = get(handles.PopMenuWindowTime,'value');
    WindowTime = handles.epoch_menu_values(epochPopupIndex);
    
    % Get slider Information (time)
    Value = get(handles.SliderTime,'value');
    Value = fix(Value/WindowTime)*WindowTime;
    maxSliderValue = get(handles.SliderTime,'max'); 
    
    % If slife value is in a valid range
    if Value<=(maxSliderValue-WindowTime)
        
        set(handles.SliderTime,'value',fix(Value+WindowTime));
        
        if handles.hasAnnotation
            % find the closest comments
            Temp=[];
            for i=1:length(handles.ScoredEvent)
                Temp(i)=handles.ScoredEvent(i).Start;
            end
            Temp = Temp - get(handles.SliderTime,'value');
            [Temp, Index]=min(abs(Temp));
            set(handles.ListBoxComments,'value',Index);
        end
        
        handles=DataLoad(handles);
        guidata(hObject,handles);
        handles = UpDatePlot(hObject,handles);
        guidata(hObject,handles);
    end
elseif currentCharacter == handles.LEFT_ARROW_KEY
    % Process left arrow key

    % Get display epoch width
    epochPopupIndex = get(handles.PopMenuWindowTime,'value');
    WindowTime = handles.epoch_menu_values(epochPopupIndex);
    
    % Get slider Information (time)
    Value = get(handles.SliderTime,'value');
    Value = fix(Value/WindowTime)*WindowTime;
    maxSliderValue = get(handles.SliderTime,'max'); 
    
    % Process key if new time in a ballid range
    if and(Value>=WindowTime, Value >=0)
        set(handles.SliderTime,'value',fix(Value-WindowTime));
        
        if handles.hasAnnotation
            % find the closest comments
            Temp=[];
            for i=1:length(handles.ScoredEvent)
                Temp(i)=handles.ScoredEvent(i).Start;
            end
            Temp = Temp - get(handles.SliderTime,'value');
            [Temp, Index]=min(abs(Temp));
            set(handles.ListBoxComments,'value',Index);
        end
        
        handles=DataLoad(handles);
        guidata(hObject,handles);
        handles = UpDatePlot(hObject,handles);
        guidata(hObject,handles);
    end
end

% Update changes to handles
guidata(hObject, handles);


%---------------------------------------------- figure1_WindowButtonDownFcn
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

%-----------------------------------------------------------------histogram
% Get location of cursor at Window's button down
Loc=get(handles.axes2,'CurrentPoint');

xLim = get(handles.axes2,'xlim');
yLim = get(handles.axes2,'ylim');

% Check if button down is in histogram window
% Click to go to sleep point of sleep axes
if (Loc(3)>yLim(1) & Loc(3)<yLim(2) & Loc(1)>xLim(1) & Loc(1)<xLim(2))
    
    
    % Get slider limits
    Max = get(handles.SliderTime,'max');
    Time = fix(Loc(1));
    
    % Adjust time accoring to window width
    epoch_popup_menu_value = get(handles.PopMenuWindowTime,'Value');
    epoch_width = handles.epoch_menu_values(epoch_popup_menu_value);
    Time = floor(Time/epoch_width)*epoch_width;
    if Time<0
        Time = 0;
    elseif Time> Max
        Time = Max;
    end
    set(handles.SliderTime,'value',Time);
    
    if handles.hasAnnotation
        % find the closest comments
        Temp=[];
        for i=1:length(handles.ScoredEvent)
            Temp(i)=handles.ScoredEvent(i).Start;
        end
        Temp = Temp - get(handles.SliderTime,'value');
        [Temp Index]=min(abs(Temp));
        set(handles.ListBoxComments,'value',Index);
    end
    
    handles=DataLoad(handles);
    guidata(hObject,handles);
    handles = UpDatePlot(hObject,handles);
    guidata(hObject,handles);
end


%--------------------------------------------------------- Time Series Plot
% Get current position in time plots
Loc=get(handles.axes1,'CurrentPoint');
xLim = get(handles.axes1,'xlim');
yLim = get(handles.axes1,'ylim');

% check is current point is in time series plot
if (Loc(3)>yLim(1) & Loc(3)<yLim(2) & Loc(1)>xLim(1) & Loc(1)<xLim(2))
    
    
    Sel = round(Loc(1,2));
    if Sel>0
        Sel = 0;
    end
    Sel = abs(Sel)+1;
    
    handles.ActiveCh = Sel;
    
    % ChInfo = evalin('base','ChInfo');
    % SelectedCh = evalin('base','SelectedCh');
    ChInfo = handles.ChInfo;
    SelectedCh = handles.SelectedCh;
    
    
    if Sel > size(SelectedCh,1)
        Sel = size(SelectedCh,1);
    end
    
    SelectedChMap=[];
    
    for i=1:size(SelectedCh,1)
        if SelectedCh(i,2)==0
            SelectedChMap{i,1} = handles.ChInfo.Labels(SelectedCh(i,1),:);
        else
            SelectedChMap{i,1} = [handles.ChInfo.Labels(SelectedCh(i,1),:) '-' handles.ChInfo.Labels(SelectedCh(i,2),:)];
        end
        SelectedChMap{i,1}((SelectedChMap{i,1}==' '))=[];
    end
    
    set(handles.TextInfo,'string',['Active Ch : ' SelectedChMap{Sel,1}]);        
end

% User selected outside view
if Loc(1)<0
    % Filter call seemed to cause an error
%     Sel = round(Loc(1,2));
% 
%     FilterSettings(Sel);
%     handles=DataLoad(handles);
%     
%     handles = UpDatePlot(hObject,handles);
%     handles.FilterSettingH = FilterSettingH;
end

guidata(hObject,handles);


%-------------------------------------------- figure1_WindowButtonMotionFcn
% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Get current axis
Loc=get(handles.axes1,'CurrentPoint');

% Get window width
epochPopupIndex = get(handles.PopMenuWindowTime,'Value');
WindowTime = handles.epoch_menu_values(epochPopupIndex);


if ~isempty(handles.ActiveCh) & Loc(1)>0 & Loc(1)<WindowTime
    
    if handles.ActiveCh >length(handles.Data)
        handles.ActiveCh = 1;
    end
    
    Sel=fix(Loc(1)/WindowTime*length(handles.Data{handles.ActiveCh}));
    
    if Sel ==0 | length(handles.ActiveCh)<Sel
        Sel = 1;
    end
    
    Data = handles.Data{handles.ActiveCh}(Sel);
    
    SelectedCh = handles.SelectedCh;
    
    Ch = SelectedCh(handles.ActiveCh,1);
    
    % get back the digital value
    if handles.ChInfo.PhyMin(Ch)>0
        Data=-Data;
    end
    Data = Data*(handles.ChInfo.DiMax(Ch)-handles.ChInfo.DiMin(Ch));
    Data = Data+(handles.ChInfo.DiMax(Ch)+handles.ChInfo.DiMin(Ch))/2;
    
    % scale the data to get the actual value
    Slope  = (handles.ChInfo.PhyMax(Ch)-handles.ChInfo.PhyMin(Ch))/(handles.ChInfo.DiMax(Ch)-handles.ChInfo.DiMin(Ch));
    
    Value = (Data-handles.ChInfo.DiMin(Ch))*Slope + handles.ChInfo.PhyMin(Ch);
    
    Text = ['Signal value : ' num2str(Value,'%.2f') ' ' handles.ChInfo.PhyDim(Ch,:) ];
    
    set(handles.TextSignalValue,'string',Text);
end


%----------------------------------------------- CheckBoxSleepAxes_Callback
% --- Executes on button press in CheckBoxSleepAxes.
function CheckBoxSleepAxes_Callback(hObject, eventdata, handles)
% hObject    handle to CheckBoxSleepAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Hint: get(hObject,'Value') returns toggle state of CheckBoxSleepAxes
clc

% Adjusted values taken from guide window
% A quick hack, adjustments should be extracted from components directly
extendedSignalAxisPos = ...
    [0.060203283815480846, 0.0660377358490566, ...
     0.91, 0.753369272237197];
 extendedSliderPos = ...
    [0.06411258795934324, 0.006738544474393531, ...
     0.924941360437842,   0.02425876010781671];

% Process Mizimize Signal Check Box Selection
if get(hObject,'value')
    % Maximize signal check box is checked
    
    % Make unnecessary  widgit invisible
    set(handles.axes2,'visible','off');
    set(handles.ListBoxComments,'visible','off');
    set(handles.pmAnnotations,'visible','off');
    
    % Extend top boarder of signal axis to cover hypnogram axis
    % axis([xmin xmax ymin ymax])
    TempAxes1  = get(handles.axes1,'outerposition');
    TempAxes2  = get(handles.axes2,'outerposition');
    %%% change variable 'Temp' to reflect the meaning
    Temp = [TempAxes1(1) -0.029 TempAxes1(3) 0.94];
    
    % Save extended signal axis position
    set(handles.axes1,'position',extendedSignalAxisPos);
    set(handles.SliderTime,'position',extendedSliderPos);
else
    % Maximize signal check box is off, show annotation widgets
    set(handles.axes2,'visible','on');
    set(handles.ListBoxComments,'visible','on');
    set(handles.pmAnnotations,'visible','on');
    
    % Resize compionents to default view
    set(handles.axes1,'outerposition',handles.Axes1OrgPos);
    set(handles.SliderTime,'position',handles.SliderOrgPos);
end

handles = UpDatePlot(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in pbRightButton.
function pbRightButton_Callback(hObject, eventdata, handles)
% hObject    handle to pbRightButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if handles.EDF_LOADED == 1
    
    % Get display epoch width
    epochPopupIndex = get(handles.PopMenuWindowTime,'value');
    WindowTime = handles.epoch_menu_values(epochPopupIndex);
    
    % Get slider Information (time)
    Value = get(handles.SliderTime,'value');
    Value = fix(Value/WindowTime)*WindowTime;
    maxSliderValue = get(handles.SliderTime,'max');
    
    % If slife value is in a valid range
    if Value<=(maxSliderValue-WindowTime)
        
        set(handles.SliderTime,'value',fix(Value+WindowTime));
        
        if handles.hasAnnotation
            % find the closest comments
            %%% change variable 'Temp' to reflect the meaning
            Temp=[];
            for i=1:length(handles.ScoredEvent)
                Temp(i)=handles.ScoredEvent(i).Start;
            end
            Temp = Temp - get(handles.SliderTime,'value');
            [Temp Index]=min(abs(Temp));
            set(handles.ListBoxComments,'value',Index);
        end
        
        handles=DataLoad(handles);
        guidata(hObject,handles);
        handles = UpDatePlot(hObject,handles);
        guidata(hObject,handles);
    end
    
end


% --- Executes on button press in pbLeftEpochButton.
function pbLeftEpochButton_Callback(hObject, eventdata, handles)
% hObject    handle to pbLeftEpochButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if handles.EDF_LOADED == 1
    
    % Get display epoch width
    epochPopupIndex = get(handles.PopMenuWindowTime,'value');
    WindowTime = handles.epoch_menu_values(epochPopupIndex);
    
    % Get slider Information (time)
    Value = get(handles.SliderTime,'value');
    Value = fix(Value/WindowTime)*WindowTime;
    maxSliderValue = get(handles.SliderTime,'max');
    
    % Process key if new time in a ballid range
    if and(Value>=WindowTime, Value >=0)
        set(handles.SliderTime,'value',fix(Value-WindowTime));
        
        if handles.hasAnnotation
            % find the closest comments
            Temp=[];
            for i=1:length(handles.ScoredEvent)
                Temp(i)=handles.ScoredEvent(i).Start;
            end
            Temp = Temp - get(handles.SliderTime,'value');
            [Temp Index]=min(abs(Temp));
            set(handles.ListBoxComments,'value',Index);
        end
        
        handles=DataLoad(handles);
        guidata(hObject,handles);
        handles = UpDatePlot(hObject,handles);
        guidata(hObject,handles);
    end
    
end


% --- Executes on button press in pb_GoToStart.
function pb_GoToStart_Callback(hObject, eventdata, handles)
% hObject    handle to pb_GoToStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.EDF_LOADED == 1
    % Get display epoch width
    epochPopupIndex = get(handles.PopMenuWindowTime,'value');
    WindowTime = handles.epoch_menu_values(epochPopupIndex);
    
    % Get slider Information (time)
    Value = 0;
    Value = fix(Value/WindowTime)*WindowTime;
    maxSliderValue = get(handles.SliderTime,'max');
    
    % Set slider value
    set(handles.SliderTime,'value',Value);
    
    % Set annotations
    if handles.hasAnnotation
        % find the closest comments
        Temp=[];
        for i=1:length(handles.ScoredEvent)
            Temp(i)=handles.ScoredEvent(i).Start;
        end
        Temp = Temp - get(handles.SliderTime,'value');
        [Temp Index]=min(abs(Temp));
        set(handles.ListBoxComments,'value',Index);
    end
    
    handles=DataLoad(handles);
    guidata(hObject,handles);
    handles = UpDatePlot(hObject,handles);
    guidata(hObject,handles);
end


% --- Executes on button press in pbGoToEnd.
function pbGoToEnd_Callback(hObject, eventdata, handles)
% hObject    handle to pbGoToEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.EDF_LOADED == 1
    % Get display epoch width
    epochPopupIndex = get(handles.PopMenuWindowTime,'value');
    WindowTime = handles.epoch_menu_values(epochPopupIndex);
    
    % Get slider Information (time)
    maxSliderValue = get(handles.SliderTime,'max');
    Value = maxSliderValue;
    Value = fix(Value/WindowTime)*WindowTime;
    
    % Set slider value
    set(handles.SliderTime,'value',Value);
    
    % Set annotations
    if handles.hasAnnotation
        % find the closest comments
        Temp=[];
        for i=1:length(handles.ScoredEvent)
            Temp(i)=handles.ScoredEvent(i).Start;
        end
        Temp = Temp - get(handles.SliderTime,'value');
        [Temp Index]=min(abs(Temp));
        set(handles.ListBoxComments,'value',Index);
    end
    
    handles=DataLoad(handles);
    guidata(hObject,handles);
    handles = UpDatePlot(hObject,handles);
    guidata(hObject,handles);
end


% --- Executes on button press in pbAutoScale.
function pbAutoScale_Callback(hObject, eventdata, handles)
% hObject    handle to pbAutoScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if EDF file check failed, then return
if handles.EDF_CHECK == 0 
    return
end

% Use the auto scale values to set the scale

% Signals Plot

% Load Current Scale Factors
auto_scale_factor = handles.auto_scale_factor;

% FilterPara = evalin('base','FilterPara');
SelectedCh = handles.SelectedCh;
FilterPara = handles.FilterPara;
    
% If scale factors are set set fitlering parameters
if ~isempty(handles.Data)

    % Get data for current epoch
    Data = handles.Data;
    
    % Get data range and define scaling factor
    numSignals = length(Data);
    dmin = @(x)min(Data{x});  
    dmax = @(x)max(Data{x}); 
    dmean = @(x)mean(Data{x});
    DataMin = arrayfun(dmin, [1:numSignals])';
    DataMax = arrayfun(dmax, [1:numSignals])';
    DataMean = arrayfun(dmean, [1:numSignals])';
    DataRange = DataMax-DataMin;
    
    % Compute scale for each signal, check for divide by zerp
    index = find(DataRange~=0);
    scalingFactor = zeros(numSignals,1);
    if ~isempty(index)
        scalingFactor(index) = ...
           4*DataRange(index)./(DataMean(index)-DataMin(index));
    end
    
    % Set each scale parameter
    for c=1:size(SelectedCh,1)
        % Get data  and plot
        % Previous Approach

        FilterPara{c}.ScalingFactor = auto_scale_factor(c);
        
        % Epoch by Epoch Scale
        FilterPara{c}.ScalingFactor = scalingFactor(c);
    end
    
    % Update paramters and replot
    handles.FilterPara = FilterPara;
    guidata(hObject, handles);
    handles = UpDatePlot(hObject, handles);  
    guidata(hObject, handles);

% autoscale button not working 
%     % Set each scale parameter
%     for c=1:size(SelectedCh,1)
%         % Get data  and plot
%         FilterPara{c}.ScalingFactor = auto_scale_factor(c);
%     end
%     
%     % Update paramters and replot
%     handles.FilterPara = FilterPara;
%     guidata(hObject, handles);
%     handles = UpDatePlot(hObject, handles);  
%     guidata(hObject, handles);
end
handles.auto_scale_factor = auto_scale_factor;
handles.FilterPara = FilterPara;
guidata(hObject, handles);


% --- Executes on selection change in pmAnnotations.
function pmAnnotations_Callback(hObject, eventdata, handles)
% hObject    handle to pmAnnotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pmAnnotations contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pmAnnotations
% set(hObject, 'String', {'Red', 'Green', 'White'});

% display selected item:
% set(hObject, 'Value', 1);
set(handles.ListBoxComments, 'string', '');
categories = handles.availableEventTypes;
disp(categories);
index_selected = get(hObject, 'Value');
if index_selected(1) == 1
    % Selected 'All' category
    Temp = cell(1, length(handles.ScoredEvent));
    handles.eventIndexInCategory(1) = 1;
    for i=1:length(handles.ScoredEvent)
       Temp1 = fix(handles.ScoredEvent(i).Start / 30) + 1;
       Temp{i}= [num2str(Temp1) ' - ' datestr(handles.ScoredEvent(i).Start/86400,'HH:MM:SS - ') handles.ScoredEvent(i).EventConcept];
       handles.eventIndexInCategory(i) = i;
    end
%     set(handles.ListBoxComments, 'string', Temp);
else
    fprintf('selected value: %d', index_selected);
    values_selected = {};
    for i = 1:length(index_selected)
        values_selected{end+1} = categories{index_selected(i)}; % first index is 'All' events
    end
    disp('----------------------------------')
    disp(values_selected)
    disp('----------------------------------')

    Temp = {};
    handles.eventIndexInCategory(1) = 1;
    j = 2;
    for i=1:length(handles.ScoredEvent)
        % if event is one of the selected values
        if i == 1 % first event 'Record Start Time'
            Temp1 = fix(handles.ScoredEvent(i).Start / 30) + 1;
            Temp{end+1}= [num2str(Temp1) ' - ' datestr(handles.ScoredEvent(i).Start/86400,'HH:MM:SS - ') handles.ScoredEvent(i).EventConcept]; %, 'EventNumber #', num2str(i)];
        end
        eventCategory = handles.ScoredEvent(i).EventType;
        if ismember(eventCategory, values_selected)
            Temp1 = fix(handles.ScoredEvent(i).Start / 30) + 1;
            Temp{end+1}= [num2str(Temp1) ' - ' datestr(handles.ScoredEvent(i).Start/86400,'HH:MM:SS - ') handles.ScoredEvent(i).EventConcept]; %, 'EventNumber #', num2str(i)];
            handles.eventIndexInCategory(j) = i;
            j = j + 1;
        end
    end
end
fprintf('list box list size: %d\n', length(handles.eventIndexInCategory));
    
if ~isempty(Temp)
    set(handles.ListBoxComments, 'string', Temp, 'value', 1);
else
    set(handles.ListBoxComments, 'string', 'No events in this category');
end
fprintf('Number of list item: # %d\n', numel(get(handles.ListBoxComments, 'string')));
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function pmAnnotations_CreateFcn(hObject, ~, handles)
% hObject    handle to pmAnnotations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ========================= Helper Functions =====================================
% ========================= By Wei Wang, 2015 ====================================
function handles = clearOpenCache(handles) 
    handles.hasSleepStages = 0;    
    handles.eventIndexInCategory = [];
    % clear pmAnnotations list box
    
function handles = turnOffHistogram(handles)
%Do not show histogram
    % focus on axes2
    axes(handles.axes2)
    % reset axes
    cla reset
    % clear x/y tick labels
%     set(gca,'xtick',[])
%     set(gca,'xticklabel',[])
%     set(gca, 'ytick', [])
%     set(gca, 'yticklabel', [])
    hold off

function handles = plotHistogram(hObject, handles)
% plot histogram according to the configuration, refactored by wei, 2015-1-14
% global hasSleepStages;
    axes(handles.axes2)
    cla
    hold off      
    plot(handles.SleepStages, 'LineWidth', 1.5, 'color','k');
    hold on
    set(handles.axes2,'xTick',[0 length(handles.SleepStages)],'xlim',[0 length(handles.SleepStages)],'xticklabel',''...
        ,'fontweight','bold','yTick',[0:5],'ylim',[-0.5 5.5],'color',[205 224 247]/255,'yTickLabel',{'R','','N3','','N1','W'})
    hold on
    
    % Higlight current window in historgram
    epoch_width = get(handles.PopMenuWindowTime,'Value');
    epoch_width = handles.epoch_menu_values(epoch_width);
    epoch_width= max(epoch_width,handles.minimum_cursor_width);
    x = [-1 -1 1 1 -1]*epoch_width/2+2+epoch_width/2;
    y = [0 5 5 0 0];
    
    handles.LineSleepStage =  fill(x,y,'r','EdgeColor', 'r','FaceAlpha',0.5);
    guidata(hObject, handles);
    hold off
    
function [eventTypes, events, stages]=loadMappingFile(mappingFile)
%loadMappingFile Load PSG annotation event mapping. To be deleted: in
%loadPSGAnnotationClass
%   Read from csv, and output list of eventTypes, events and stages
events = [];
stages = [];
eventTypes = [];
try
   fid = fopen(mappingFile, 'r') ;
   tline = fgetl(fid);
   while ischar(tline)
       % use two "%*s" because in some csv file, the fourth(last) column
       % contains ',' which is the delimiter in csv file
       line = textscan(tline, '%s %s %s %*s %*s', 'delimiter', ',', 'CollectOutput', false);       
       eventType = line{1}{1};
       eventConcept = line{3}{1};
       if strcmp(eventType, 'EventType') == 0
           eventTypes{end+1} = eventType;
       end
       if strcmp(eventType, 'EpochLength') == 0 & strcmp(eventType, 'EventType') == 0
           events{end+1} = eventConcept;
           if strcmp(eventType, 'Staging') == 1
               stages{end+1} = eventConcept;
           end
       end
       tline = fgetl(fid);
   end

   events = unique(events);
   stages = unique(stages);
   eventTypes = unique(eventTypes);
   
   fclose(fid);
catch exception
    disp(exception)
    events = [];
    stages = [];
    eventTypes = [];
end

function msg=showErrorMessages(errroList) 
    % For EDF error handling
    errMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for i=1:length(errroList)
        fields = parseLine(errroList{i});
        %disp('===============================')
        if isKey(errMap, fields{1})
            errMap(fields{1}) = [errMap(fields{1}), '    ->', fields{2}, char(10)];
            %disp(errMap(fields{1}));
        else 
            %errMap(fields{1}) = [fields{1}, char(10), '    ->', fields{2}, char(10)];
            errMap(fields{1}) = [fields{1}, char(10), fields{2}, char(10)];
            %disp(errMap(fields{1}));
        end
    end
    result = values(errMap);
    msg = {};
    for i=1:length(result)
        msg{end+1} = result{i};
    end
    disp('----------------------')
    for i=1:length(msg)
        disp(msg{i})
    end

    
function output=parseLine(line)
    output = {};
    message = strsplit(line, ',');
    msgSize = length(message);
    if msgSize == 2
        output = message;
    elseif msgSize == 1
        output = {message{1}, ''};
    end    

% ========================= Helper Functions END =================================
