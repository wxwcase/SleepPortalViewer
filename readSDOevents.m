function sroEvents = readSDOevents()
%Read in SDO stage concepts, and return as an array
% by Wei, 2012-12-10
	try
		fid = fopen('sdo-events.csv');
	    format = '%s ';
	    out = textscan(fid, format,'delimiter', ', ');
	    sroEvents = out{1};
	    fclose(fid);
	catch
		errordlg('Cannot read SDO events file', 'Configuration error');
	end
end