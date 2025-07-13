function checkAudapterParams(p)
% checkAudapterParams(p)
%
% Function to assess validity of variable names and data type in p
% structure used to initiate Audapter. Should be called immediately prior to: 
%   AudapterIO('init', p);
%
% INPUT     p       structure p used to initiate Audapter
% 
% Developed by Elaine Kearney, June 2021 (elaine-kearney.com)
% Matlab 2020b

%% input params
varNamesInputP = fieldnames(p);

% default params
defaultP = getAudapterDefaultParams('female');
defaultP.timeDomainPitchShiftAlgorithm = 'pp_none';    % param not in default params but is specified in AudapterIO
varNamesDefaultP = fieldnames(defaultP);

% compare input p field names to default p
if ~isequal(varNamesDefaultP, varNamesInputP)
    flagVar = ~ismember(varNamesInputP, varNamesDefaultP);
    error('User-specified variable name(s) ''%s'' in p is/are not correct. \nCross-check name(s) in function getAudapterDefaultParams.', strjoin(varNamesInputP(flagVar), ', '))
end

% compare input p field types to default p
numFields = length(varNamesDefaultP);
for i = 1:numFields
    varTypeDefaultP = class(defaultP.(varNamesDefaultP{i}));
    varTypeInputP = class(p.(varNamesDefaultP{i}));
    if ~isequal(varTypeDefaultP, varTypeInputP)
        error('User-specifed variable ''%s'' in p is type %s, expected type %s.', varNamesDefaultP{i}, varTypeInputP, varTypeDefaultP)
    end
end

end