
function [lambda, src_z, src_a, view_z, view_a, BRDF] = load_single_blacklab(filepath)
    % Load text file data output by Remote Sensing Group's Blacklab
    % measurement.
    % lambda, src_z, src_a, view_z, view_a, BRDF are vectors.
    
    % sheets = sheetnames(filepath);
    % i0 = 1;
    % for k = 1:length(sheets)
    %     raw = readmatrix(filepath, 'Sheet', sheets{k});
    %     if ~isempty(raw) % handle last sheet being empty
    %         iL = size(raw, 2) - 1; % minus 1 b/c first column empty
    %         i1 = i0 + iL - 1;
    %         A(i0:i1) = raw(7, 2:end);
    %         I(i0:i1) = raw(8, 2:end);
    %         R(i0:i1) = raw(9, 2:end);
    %         RT(i0:i1) = raw(22, 2:end);
    %         i0 = i1 + 1;
    %     end
    % end

    lines = readlines(filepath);
    
    % Find the column-header line:
    headerLineIdx = find(startsWith(strtrim(lines), "src_z"), 1, "first");
    if isempty(headerLineIdx)
        error("Could not find data header line starting with src_z.");
    end
    
    % Store metadata/header info above the column titles as one string:
    headerInfo = strjoin(lines(1 : headerLineIdx-1), newline);
    
    % Get column titles from the detected header line:
    colNames = split(strtrim(lines(headerLineIdx)));
    colNames = colNames(:)';
    
    % Wavelength column headers start after angle columns:
    angleCols = ["src_z", "src_a", "view_z", "view_a"];
    nAngles = numel(angleCols);
    lambdaLabels = colNames(nAngles+1 : end); % e.g. "1243.53nm"
    lambda = str2double(erase(lambdaLabels, "nm")); % numeric vector
    
    % Import numeric data starting after the detected header line:
    opts = delimitedTextImportOptions("Delimiter", {' ', '\t'}, ...
        "NumVariables", numel(colNames), ...
        "DataLines", [headerLineIdx+1, Inf], ...
        "ConsecutiveDelimitersRule", "join", ...
        "LeadingDelimitersRule", "ignore");
    opts.VariableNames = matlab.lang.makeValidName(colNames);
    opts.VariableTypes(:) = {'double'}; % convert 'char' to 'double' so table loads as numeric data
    T = readtable(filepath, opts);
    
    % 1D vectors (row titles of 2D data):
    src_z  = T.src_z;
    src_a  = T.src_a;
    view_z = T.view_z;
    view_a = T.view_a;
    
    % 2D array of BRDF values ('lambda' is column titles):
    BRF = T{:, nAngles+1 : end};

    % Format data into point cloud:
    n = size(BRF, 2); % number of wavelengths
    m = size(BRF, 1); % number of angles per wavelength
    lambda = repelem(lambda, 1, m);
    src_z = repmat(src_z', 1, n);
    src_a = repmat(src_a', 1, n);
    view_z = repmat(view_z', 1, n);
    view_a = repmat(view_a', 1, n);
    BRDF = BRF(:)' / pi; % 2D array to vector, and BRF to BRDF

end

