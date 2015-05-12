function sroEvents = readSROevents() 
%Read in SRO stage concepts, and return as an array
% by Wei, 2012-12-10
	try
		fid = fopen('sro-events-old.csv');
%         fid = fopen('sro-events.csv');
	    format = '%s';
	    out = textscan(fid, format,'delimiter', ', ');
	    sroEvents = out{1};
	    fclose(fid);
	catch
		errordlg('Cannot read SRO events file', 'Configuration error');
	end
end