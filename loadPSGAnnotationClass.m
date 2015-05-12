classdef loadPSGAnnotationClass 
    
    %---------------------------------------------------- Public Properties
    properties (Access = public)
        % Input
        fileName = ''; % eg: '123.edf'   
        vendorName = ''; % eg: 'Embla'
        sleepStageValues = []; %%% TODO issue, 2015-2-18
        annotationType = ''; % eg: 'PSGAnnotation', 'CMPStudyConfig'
        isSDO = 0;
        
        % Optional Parameters
        errMsg = {};
        % Error list
        errList = {};
        errMap = containers.Map('KeyType', 'char', 'ValueType', 'char');        
    end
    %------------------------------------------------- Dependent Properties
    properties (Dependent = true)        
        % PhysioMiMi Terms
        xmlEntries                        % XMl entry types
        ScoredEvent                       % Scored event structure list
        EventList                         % List of events
        EventTypes                        % Unique event entry types
        EventStart                        % Event start list
        SleepStages
        EpochLength
    end
    %------------------------------------------------- Protected Properties
    properties (Access = protected)  
        AnnotationType = ''; % eg: 'PSGAnnotation'
        EventConcepts = [];
        EventStages = [];
        
        % Lights off/on text
        lightsOffText = 'Lights Off';
        lightsOnText = 'Lights On';
        
        % PhysioMiMi Terms
        xmlEntriesP                   % XML Doc Entries
        ScoredEventP                  % Scored event data structure list
        EventListP                    % List of events names(EventConcepts)
        EventTypesP                   % Unique event names(categories)
        EventCategoryListP            % Event categories
        EventCategoryP                % Unique event categories
        EventStartP                   % Event start list
        SleepStagesP                  % Sleep Stages list
        EpochLengthP                  % Epoch Length  
    end
    %------------------------------------------------------- Public Methods
    methods
        %------------------------------------------------------ Constructor
        function obj = loadPSGAnnotationClass(varargin)
            if nargin == 1
                obj.fileName = varargin{1};
            else
                fprintf('obj = loadPSGAnnotationClass (filename)') % (fileName) to (filename)
            end 
        end
        
        %---------------------------------------------------------
        %available event names for public usage
        function eventNameList = availableEventNames(obj)
            % remove stages:
            eventNameList = obj.EventTypesP; %%% Added unique func, TODO
        end
        function eventTypeList = availableEventTypes(obj)
            eventTypeList = obj.EventCategoryP;
        end
        %--------------------------------------------------------- loadFile
        function obj = loadFile(obj)
            % Load Grass file
            fileName = obj.fileName;
            fid = fopen(fileName);      
            
            % Process if file is open
            if fid > 0
                fileTxt = fread(fid)';
            else
                msg = sprintf('Could not open %s', fileName);
                error(msg);
            end
            
            %----------------------------------------------- Resolve 'SDO'
            % Temp = fread(fid,[1 inf],'uint8'); % not efficient
            obj.isSDO = strfind(fileTxt,'SDO:');
            %-----------------------------------------------------
            
            % Pass loaded information to object
            try
                xdoc = xmlread(fileName);
            catch
                errMsg{end+1} = 'Failed to read XML file';
                error('Failed to read XML file %s.',xmlfile);
            end
            
            [ScoredEvent, SleepStageNames, EpochLength, obj.sleepStageValues] = ...
                parseAndValidateNodes(xdoc);            
           
            % Get event information
            eventListF = @(x)ScoredEvent(x).EventConcept;
            EventListP = arrayfun(eventListF,[1:length(ScoredEvent)],...
                'UniformOutput', 0)';
            EventTypesP = unique(EventListP);
            
            eventCategoryF = @(x)ScoredEvent(x).EventType;
            EventCategoryListP = arrayfun(eventCategoryF,[1:length(ScoredEvent)],...
                'UniformOutput', 0)';
            EventCategoryP = unique(EventCategoryListP);
            
            eventStartF = @(x)ScoredEvent(x).Start;
            EventStartP = arrayfun(eventStartF,[1:length(ScoredEvent)],...
                'UniformOutput', 0)';

            % Pass key varaibles to obj
            obj.ScoredEventP = ScoredEvent;
            obj.SleepStagesP = SleepStageNames';
            obj.EpochLengthP  = EpochLength;
            
            % Pass detail information to obj
            obj.EventListP = EventListP;
            obj.EventTypesP = EventTypesP;
            obj.EventStartP = EventStartP;
            obj.EventCategoryP = EventCategoryP;
            
            fid = fclose(fid);
        
            %------------------------------------ Parse and validate nodes
            function [ScoredEvent, SleepStageNames, EpochLength, SleepStageValues] = ...
                    parseAndValidateNodes(xmldoc)
                fprintf('\n>>> Parsing annotation file... \n')
                % Function parses each XML node
                xmlVersion = xmldoc.getXmlVersion;
                xmlEncoding = xmldoc.getXmlEncoding;
                rootNode = xmldoc.getFirstChild;
                rootNodeTag = rootNode.getTagName;
                obj.AnnotationType = rootNodeTag;
                
                Temp = xmldoc.getElementsByTagName('EpochLength');
                EpochLength = str2double(Temp.item(0).getTextContent);
                
                TempVendor = xmldoc.getElementsByTagName('SoftwareVersion');
                obj.vendorName = TempVendor.item(0).getTextContent;                               

                events = xmldoc.getElementsByTagName('ScoredEvent');
                % Add check code to deal with the missing subfield(Start/Duration, etc)
                if events.getLength > 0
                    SleepStageNames = {};
                    SleepStageValues = [];
                    ScoredEvent = struct(...
                        'EventType', '', ...
                        'EventConcept', '', ...
                        'Start', [], ...
                        'Duration', [], ...
                        'InputCh', '', ...
                        'SpO2Baseline', [], ...
                        'SpO2Nadir', [], ...
                        'ToolTip', '' ...
                    );

                    stagesNameVector = {...
                        'Stage 1 sleep',...
                        'Stage 2 sleep',...
                        'Stage 3 sleep',...
                        'Stage 4 sleep',...
                        'REM sleep',...
                        'Wake',...
                        'Movement'
                    };
                    
                    for i = 0 : events.getLength - 1
                        
                        eventConceptText = '';
                        nadirNum = [];
                        baselineNum = [];
                        startNum = [];
                        durationNum = [];
                        hasDesaturation = [];
                        eventValid = 1;
                        InputChName = '';
                        %%% First check if the event has predefined event
                        %%% length, if not report error(May need a report event error mechanism)
                        try
                            eventConceptNode = events.item(i).getElementsByTagName('EventConcept');
                            eventConceptText = char(eventConceptNode.item(0).getTextContent);
                            tooltip = eventConceptText;
                            if i ~= 0
                                tmp = strsplit(eventConceptText, '|');
                                eventConceptText = tmp{2};
                                tooltip = tmp{1};
                            end
                            
                            eventTypeNode = events.item(i).getElementsByTagName('EventType');
                            eventTypeText = char(eventTypeNode.item(0).getTextContent);
                            if i~= 0
                                tmp = strsplit(eventTypeText, '|');
                                eventTypeText = tmp{2};
                                typeTooltip = tmp{1};
                            end
                            obj.EventConcepts{end+1} = eventConceptText;
                            if strcmp(eventTypeText, 'Stages') == 1
                                obj.EventStages{end+1} = eventConceptText;
                                SleepStageNames{end+1} = eventConceptText;
                            end
                            
                            if i ~= 0 & strcmp(eventTypeText, 'Stages') == 0
                                try
                                    InputChName = char(events.item(i).getElementsByTagName('SignalLocation').item(0).getTextContent);
                                    % is InputChName is empty, how to deal with it:
                                catch
                                    % No input tag found
                                end
                            end
                            
                            % Check if EventConcept contains these stages:
%                             Temp = strfind(eventConceptText,'Desaturation');
                            Temp = strfind(tooltip,'desaturation');
                            if ~isempty(Temp)
                                hasDesaturation = 1;
                                % change str2num to str2double todo
                                try
                                    nadirNode = events.item(i).getElementsByTagName('SpO2Nadir');
                                    nadirNum = str2num(nadirNode.item(0).getTextContent);
                                catch ex3
                                    obj = obj.logErr('Cannot found <SpO2Nadir> tag', i);
                                    continue
                                end
                                try
                                    baselineNode = events.item(i).getElementsByTagName('SpO2Baseline');
                                    baselineNum = str2num(baselineNode.item(0).getTextContent);
                                catch ex4
                                    obj = obj.logErr('Cannot found <SpO2Baseline> tag', i);
                                    continue
                                end
                            end
                        catch ex0
                            obj = obj.logErr('Cannot found <EventConcept> tag', i);                            
                            continue % ignore this event
                        end
                        try
                            startNode = events.item(i).getElementsByTagName('Start');
                            startNum = str2num(startNode.item(0).getTextContent);
                        catch ex1
                            obj = obj.logErr('Cannot found <Start> tag', i);
                            continue
                        end
                        try
                            durationNode = events.item(i).getElementsByTagName('Duration');
                            durationNum = str2num(durationNode.item(0).getTextContent);
                        catch ex2
                            obj = obj.logErr('Cannot found <Duration> tag', i);
                            continue
                        end
                        
                        if strcmp(stagesNameVector(1),tooltip)==1
                            fprintf('sleep stage name: %s', eventConceptText);
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)+3];
                        elseif strcmp(stagesNameVector(2),tooltip)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)+2];
                        elseif strcmp(stagesNameVector(3),tooltip)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)+1];
                        elseif strcmp(stagesNameVector(4),tooltip)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)];
                        elseif strcmp(stagesNameVector(5),tooltip)==1
                            SleepStageValues = [SleepStageValues, zeros(1,durationNum)];
                        elseif strcmp(stagesNameVector(6),tooltip)==1
                            SleepStageValues = [SleepStageValues, zeros(1,durationNum)+5];
                            % end
                        else
                        end
                        
                        ithScoredEvent = struct(...
                            'EventType', eventTypeText, ...
                            'EventConcept', eventConceptText, ...
                            'Start', startNum, ...
                            'Duration', durationNum, ...
                            'InputCh', InputChName, ...
                            'SpO2Baseline', baselineNum, ...
                            'SpO2Nadir', nadirNum, ...
                            'ToolTip', tooltip ...
                        );
                        %------------------------------------- Validate Events
                        if i ~= 0
                            [eventValid, obj] = validateEvent(obj, ithScoredEvent, i);
                            if eventValid == 0
                                continue % error occurs during validation
                            end
                        end
                        %------------------------------ Construct Event Vector
                        if eventValid == 1
                            if i == 0
                                ScoredEvent(1) = ithScoredEvent;
                            else
                                % if this event is stage event, then do not
                                % include in the handles.ScoredEvent list
%%%                                 if ~obj.isStageEvent(ithScoredEvent)
                                ScoredEvent(end+1) = ithScoredEvent;
                            end                            
                        end   
                        %------------------------------ End
                    end         
                    obj.EventConcepts = unique(obj.EventConcepts);
                    obj.EventStages = unique(obj.EventStages);
                end  % end if    
                fprintf('>>> Done.\n')
            end  % End Embedded Function                 
        end
        %--------------------------------------------- Validate Events
        function [isValid, obj] = validateEvent(obj, eventStruct, eventNum)
            %args: eventStruct is used for validating each of its fields
            %      eventNum is used for displaying error messages
            isValid = 1; % true
            eventErrMsg = '';
            if isempty(eventStruct.EventConcept)
                isValid = 0;
                eventErrMsg = strcat(eventErrMsg, 'Event name not found;');
            end
            if isempty(eventStruct.Start)
                isValid = 0;
                eventErrMsg = strcat(eventErrMsg, 'Start time empty;');
            end
            if isempty(eventStruct.Duration)
                isValid = 0;
                eventErrMsg = strcat(eventErrMsg, 'Duration empty;');
            end
            % if strcmp(eventStruct.EventConcept, 'SRO:SpO2Desaturation')
            if strcmp(eventStruct.EventConcept, 'Desaturation')
                if isempty(eventStruct.SpO2Nadir)
                    isValid = 0;
                    eventErrMsg = strcat(eventErrMsg, 'SpO2Nadir empty;');
                end
                if isempty(eventStruct.SpO2Baseline)
                    isValid = 0;
                    eventErrMsg = strcat(eventErrMsg, 'SpO2Baseline empty;');
                end
            end
            if isValid == 0 && ~isempty(eventErrMsg)
                obj = obj.logErr(eventErrMsg, eventNum);
            end 
        end
        %-------------------------------------------- Log errors
        function obj = logErr(obj, message, eventNumber)
            %Error logging
              if isKey(obj.errMap, message)
                  obj.errMap(message) = [obj.errMap(message), ', ', num2str(eventNumber)];
              else 
                  obj.errMap(message) = [message, char(10), '  --> EventNumber: ', num2str(eventNumber)];
              end
        end
        
        function isStaging = isStageEvent(obj, scoredEvent)
            isStaging = 0;
            eventIndex = find(ismember(obj.EventStages, scoredEvent.EventConcept), 1);
            if eventIndex
                isStaging = 1;
            end
        end
    end
    %---------------------------------------------------- Private functions
    methods (Access=protected) 
    end
    %------------------------------------------------- Dependent Properties
    methods 
        %----------------------------------------------PhysioMiMi Variables
        %------------------------------------------------------- xmlEntries
        function value = get.xmlEntries(obj)
            value = obj.xmlEntriesP;
        end
        %------------------------------------------------------ ScoredEvent
        function value = get.ScoredEvent(obj)
            value = obj.ScoredEventP;
        end
        
        %-------------------------------------------------------- EventList
        function value = get.EventList(obj)
            value = obj.EventListP;
        end
        %------------------------------------------------------- EventTypes
        function value = get.EventTypes(obj)
            value = obj.EventTypesP;
        end
        %------------------------------------------------------- EventStart
        function value = get.EventStart(obj)
            value = obj.EventStartP;
        end                        
        %------------------------------------------------------ SleepStages
        function value = get.SleepStages(obj)
            value = obj.SleepStagesP;
        end
        %------------------------------------------------------ EpochLength
        function value = get.EpochLength(obj)
            value = obj.EpochLengthP;
        end
    end
    %------------------------------------------------- Dependent Properties
    methods(Static)        
        %--------------------------------------------- Read in Events(json)
        function events=readMapConfig(fname)
        % 2014-12-3, Read PSG configuration file in the default directory
            events = {};
            % stages = {}; % to be returned
            try
                fid = fopen(fname);
                raw = fread(fid, inf);
                str = char(raw');
                fclose(fid);
                % Parse scored event in the json file to scored event data
                % structure, eg:
                % {
                %     "EventType":"Staging",
                %     "Event":"1",
                %     "EventConcept":"SRO:Stage1Sleep",
                %     "Notes":"Epoch scored as Stage 1 Sleep"
                % }
                eventData = JSON.parse(str);
                for i = 1:length(eventData)
                    % if strcmp(eventData(i).EventType, 'Staging')
                    %     stages{end+1} = eventData(i).EventConcept
                    % end
                    events{end+1} = eventData{i}.EventConcept;
                end
            catch exception
                disp(exception)
            end
        end
        %--------------------------------------------- Read in Events(csv)
        function [eventMap, events, stages]=testLoadCSV(mappingFile)
            %testLoadCSV Load PSG annotation event mapping
            %   Read from csv, and output list of events and stages
            %   check loading csv
            eventMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
            events = [];
            stages = [];
            try
               fid = fopen(mappingFile, 'r');
               tline = fgetl(fid);
            while ischar(tline)
               % use two "%*s" because in some csv file, the fourth(last) column
               % contains ',' which is the delimiter in csv file
               line = textscan(tline, '%s %s %s %*s %*s', 'delimiter', ',', 'CollectOutput', false);       
               eventType = line{1}{1};
               eventConcept = line{3}{1};
               
               if strcmp(eventType, 'EpochLength') == 0 & strcmp(eventType, 'EventType') == 0
                   events{end+1} = eventConcept;
                   if ~isKey(eventMap, eventConcept)
                       eventMap(eventConcept) = eventType;
                   end
                   if strcmp(eventType, 'Staging') == 1 | strcmp(eventType, 'Sleep Staging') == 1
                       stages{end+1} = eventConcept;
                   end
               end
               
               tline = fgetl(fid);
            end

            events = unique(events);
            stages = unique(stages);
   
            fclose(fid);
            catch exception
                disp(exception)
                events = [];
                stages = [];
            end
        end   
        %--------------------------------------------- set mapping file
        function setMappingFile()
            
        end
        %---------------------------------------------------- GetEventTimes  
        function value = GetEventTimes(eventLabel, EventList, EventStart)
           % Return the time of the specified event
           
           % Define return value
           value = [];
           
           % Check for event typ
           eventIndex = strcmp(eventLabel, EventList);
           
           if ~isempty(eventIndex)
               value = EventStart(eventIndex);
           end 
        end
    end
end
% Staging,0,SRO:Wake,Epoch scored as Wake
% Staging,1,SRO:Stage1Sleep,Epoch scored as Stage 1 Sleep
% Staging,2,SRO:Stage2Sleep,Epoch scored as Stage 2 Sleep
% Staging,3,SRO:Stage3Sleep,Epoch scored as Stage 3 Sleep
% Staging,4,SRO:Stage4Sleep,Epoch scored as Stage 4 Sleep
% Staging,5,SRO:RapidEyeMovement,Epoch scored as REM Sleep
% Staging,6,SRO:MovementTime,Epoch scored as ppt time spent in movement
% Staging,9,SRO:UnscoredEpoch,Unscored epoch
% Staging,10,SRO:ArtifactEpoch,Epoch scored as artifact