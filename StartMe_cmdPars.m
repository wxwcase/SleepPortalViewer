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
        FileName = varargin{1};
        FilePath = varargin{2};
    elseif length(varargin) == 4
        needOpenDialog = false;
        FileName = varargin{1};
        FilePath = varargin{2};
        XmlFileName = varargin{3};
        XmlFilePath = varargin{4};
    end
    
    EDF_View({})
end
