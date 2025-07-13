function age = calcAge()
% function to calculate age based on DOB and date of session
%
% INPUT       none
%
% OUTPUT      age in years
%
% Developed by Elaine Kearney, Jul 2021 (elaine-kearney.com)
% Matlab 2020b

% dialog setup
prompt = {'Month (first 3 letters)','Day', 'Year'};
dims = [1, 45];
curDate = date;
dateParts = strsplit(curDate, '-');
definput = {dateParts{2},dateParts{1}, dateParts{3}};

% user prompt - DOB
dlgtitle = 'Enter participant DOB';
DOB = inputdlg(prompt,dlgtitle,dims,definput);
checkInputs(DOB, dateParts);

% user prompt - session date
dlgtitle = 'Enter date of session';
sessDate = inputdlg(prompt,dlgtitle,dims,definput);
checkInputs(sessDate, dateParts);

% format responses
from = [DOB{1} '-' DOB{2} '-' DOB{3}];
from = datetime(from, 'InputFormat','MMM-dd-yyyy');
to = [sessDate{1} '-' sessDate{2} '-' sessDate{3}];
to = datetime(to, 'InputFormat', 'MMM-dd-yyyy');

% calc age
age = calyears(between(from, to));

end

function checkInputs(answer, dateParts)
if length(answer{1}) ~= 3
    error('Month must be specified using first 3 letters, e.g., Apr')
elseif str2double(answer{2}) < 1 || str2double(answer{2}) > 31
    error('Day must be a number between 1 and 31')
elseif str2double(answer{3}) < 1900 || str2double(answer{2}) > str2double(dateParts{3})
    error('Year must be a number between 1900 and the current year')
end
end