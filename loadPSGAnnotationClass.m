classdef loadPSGAnnotationClass
    
    % TODO list:
    %   1. Change name to loadPSGAnnotationClass
    %   2. add several methods for validate each node's
    %       properties(EventConcept, Start, Duration, etc)
    %   3. Put the default event list in an external xml/json file
    
    %%% Need to check ScoredEvent; SleepStage; SoftwareVersion
    %---------------------------------------------------- Public Properties
    properties (Access = public)
        % Input
        fileName = ''; % eg: '123.edf'   
        vendorName = ''; % eg: 'Embla'
        mappingFn = '';
        % map <ScoredEvent.EventConcept, ScoredEvent.EventType>
        eventMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
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
%         mappingFn = '';
        AnnotationType = ''; % eg: 'PSGAnnotation'
        EventConcepts = [];
        EventStages = [];
        
        % Lights off/on text
        lightsOffText = 'Lights Off';
        lightsOnText = 'Lights On';
        
        % PhysioMiMi Terms
        xmlEntriesP                   % XML Doc Entries
        ScoredEventP                  % Scored event data structure list
        EventListP                    % List of events (EventConcepts)
        EventTypesP                   % Unique event entry types(categories)
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
        function eventTypeList = availableEventNames(obj)
            % remove stages:
            eventTypeList = obj.EventTypesP; %%% Added unique func, TODO
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
            
            [ScoredEvent, SleepStageNames, EpochLength, obj.sleepStageValues] = parseAndValidateNodes(xdoc);            
           
            % Get event information
            eventListF = @(x)ScoredEvent(x).EventConcept;
            EventListP = arrayfun(eventListF,[1:length(ScoredEvent)],...
                'UniformOutput', 0)';
            EventTypesP = unique(EventListP);
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
            
            fid = fclose(fid);   
        
            %------------------------------------ Parse and validate nodes
            function [ScoredEvent, SleepStageNames, EpochLength, SleepStageValues] = parseAndValidateNodes(xmldoc)
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
                
                %%% TODO: should not hard code mapping file name
                %%% TODO: design later
                if ~isempty(obj.isSDO)
                    obj.mappingFn = 'configuration/mapping-SDO.csv';
                else
                    if obj.vendorName == 'Embla'
                        obj.mappingFn = 'configuration/mapping-Embla.csv';
                    end
                    if obj.vendorName == 'Compumedics'
%                         obj.mappingFn = 'configuration/mapping-CHAT.csv';
                        obj.mappingFn = 'configuration/mapping-Compumedics.csv';
                    end
                end
                % Loading mapping file into obj.EventConcepts,
                % obj.EventStages array
                [obj.eventMap, obj.EventConcepts, obj.EventStages] = loadPSGAnnotationClass.testLoadCSV(obj.mappingFn);  %%%TODO

                events = xmldoc.getElementsByTagName('ScoredEvent');
                % Add check code to deal with the missing subfield(Start/Duration, etc)
                if events.getLength > 0
                    SleepStageNames = {};
                    SleepStageValues = [];
                    ScoredEvent = struct(...
                        'EventConcept', '', ...
                        'Start', [], ...
                        'Duration', [], ...
                        'SpO2Baseline', [], ...
                        'SpO2Nadir', [] ...
                    );
                    % Default sleep stage name array. To be improved
%                     stagesNameVector = obj.EventStages;
                    stagesNameVector = readSROevents();
                    for i = 0 : events.getLength - 1
                        eventConceptText = '';
                        nadirNum = [];
                        baselineNum = [];
                        startNum = [];
                        durationNum = [];
                        hasDesaturation = [];
                        eventValid = 1;
                        %%% First check if the event has predefined event
                        %%% length, if not report error(May need a report event error mechanism)
                        try
                            eventConceptNode = events.item(i).getElementsByTagName('EventConcept');
                            eventConceptText = char(eventConceptNode.item(0).getTextContent);
                            % disp(eventConceptText);
                            % Check if EventConcept contains these stages:
                            eventIndex = find(ismember(obj.EventStages, eventConceptText), 1);
                            if ~isempty(eventIndex)
                                SleepStageNames{end+1} = eventConceptText;
                            end
                            % Temp = strfind(eventConceptText,'SRO:SpO2Desaturation'); % change findstr to strfind
                            Temp = strfind(eventConceptText,'Desaturation');
%                             Temp = strfind(eventConceptText,'SRO:SpO2Desaturation');
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
                        
                        if strcmp(stagesNameVector{1},eventConceptText)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)+3];
                        elseif strcmp(stagesNameVector{2},eventConceptText)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)+2];
                        elseif strcmp(stagesNameVector{3},eventConceptText)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)+1];
                        elseif strcmp(stagesNameVector{4},eventConceptText)==1
                            SleepStageValues = [SleepStageValues, ones(1,durationNum)];
                        elseif strcmp(stagesNameVector{5},eventConceptText)==1
                            SleepStageValues = [SleepStageValues, zeros(1,durationNum)];
                        elseif strcmp(stagesNameVector{6},eventConceptText)==1
                            SleepStageValues = [SleepStageValues, zeros(1,durationNum)+5];
                            % end
                        else
                        end
                        
                        ithScoredEvent = struct(...
                            'EventConcept', eventConceptText, ...
                            'Start', startNum, ...
                            'Duration', durationNum, ...
                            'SpO2Baseline', baselineNum, ...
                            'SpO2Nadir', nadirNum ...
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
%%%                                 end
                            end                            
                        end   
                        %------------------------------ End
                    end                    
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
            eventIndex = find(ismember(obj.EventConcepts, eventStruct.EventConcept), 1);
            if isempty(eventIndex)
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
            %   message, the error message to be displayed
            %   eventNumber, the event number where the error occurred                        
%              errmsg = sprintf('ScoredEvent-%0.0f: "%s"\n', eventNumber, message);  
%              fprintf(errmsg);
%              if isempty(obj.errList)
%                  obj.errList{1} = errmsg;
%              else
%                  obj.errList{end+1} = errmsg;
%              end
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
        %-------------------------------------------- Log errors in console
%         function errmsg = logErr(obj, message, eventNumber)
%             %Error logging
%             %   message, the error message to be displayed
%             %   eventNumber, the event number where the error occurred                        
%             errmsg = sprintf('>>> (Error) ScoredEvent-%0.0f: "%s"\n', eventNumber, message);            
%             obj.errList = [obj.errList, errmsg];
% %             disp(errmsg)
% %             errmsg = '>>> (Error) ScoredEvent-' + eventNumber + ': "' + message +'"\n';
%         end
                
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
            if ~isempty(stages)
                %handles.hasSleepStages = 1;
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