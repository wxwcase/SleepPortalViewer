function StartMe_cmdPars(varargin) %varargin
%varargin: (edfPath, edfName, xmlPath, xmlName)
    
    global needOpenDialog;
    global FilePath;
    global FileName;
    global XmlFilePath;
    global XmlFileName;
    
    if isempty(varargin)
        needOpenDialog = true;
    elseif length(varargin) == 2
        needOpenDialog = false;
        FilePath = varargin{1};
        FileName = varargin{2};
    elseif length(varargin) > 2
            XmlFilePath = varargin{3};
            XmlFileName = varargin{4};
    end
    
    EDF_View({})
end