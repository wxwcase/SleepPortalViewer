function StartMe_cmdPars(edfPath, edfName, xmlPath, xmlName) %varargin
%varargin: (edfPath, edfName, xmlPath, xmlName)
    
    % if length(varargin) ~= 4
    %     EDF_View({})
    % else
    %     // ...
    % end
    
    global needOpenDialog;
    needOpenDialog = logical(0);
    
   % global EdfFilePath;
   % global EdfFileName;
    global FilePath;
    global FileName;
    global XmlFilePath;
    global XmlFileName;
    %EdfFilePath = edfName;
    %EdfFileName = edfPath;
    FilePath = edfName;
    FileName = edfPath;
    XmlFilePath = xmlName;
    XmlFileName = xmlPath;
    
    EDF_View({})
end