%{
This program reads a txt file of desired source/view zenith/azimuth
angles and calculates the necessary black lab stage angles to obtain them.
It saves the stage angles as a second txt file. The user interacts with GUI
windows to choose an input file, edit header lines, and save the output
stage angles.

    Inputs:
        n/a (click to select file of input angles)
    Output:
        text file of stage angles

This program needs to be in the same folder as the function files:
    josies_compute_BL_angles.m
    rodrigues.m

Josie Maxwell, 28 May 2020, RSG

% =========================================================================

JPK == Jacob P. Krell, 2026/06/08-2026/xx/xx, LOFT;

%}

clear all; clc;

shading_cutoff = 10; % [JPK] minimum acceptable radiometer angle [deg] at 
    % which shading does not occur

%%% SELECT INPUT FILE %%%
[file,path] = uigetfile('.txt','Select Input File');

%%% GET RADIOMETRY ANGLES AND HEADER FROM FILE %%%
filecontents = importdata(fullfile(path,file));
data = filecontents.data;
angles = data(:,2:5); % radiometry angles
header = filecontents.textdata(1:end-1,1);

%%% CALCULATE STAGE ANGLES %%%
stage = zeros(size(angles));
for n = 1:size(angles,1)
    stage(n,:) = compute_BL_angles(angles(n,:));
end

%%% [JPK] FILTER OUT SELF-SHADING STAGE ANGLES %%%
radiometer_angle = stage(:, 1);
angles_to_remove = abs(radiometer_angle) < shading_cutoff;
if any(angles_to_remove)
    warning("Filtering out self-shading angles.")
    stage = stage(~angles_to_remove, :); % keep only non-shaded angles
end

%%% CREATE HEADER FOR OUTPUT FILE %%%
guiprompts = {};
dims = [];
for n = 1:size(header,1)
    guiprompts{1,n} = strjoin({'Header line ',num2str(n)});
    dims(n,1:2) = [1 100];
end
header = inputdlg(guiprompts,'Edit Output File Header',...
    dims,header);

%%% CREATE OUTPUT FILE %%%
% created suggested name of output file
if file(end-3) == '.'
    filesuggest = file(1:end-4);
else
    filesuggest = file;
end
filesuggest = [filesuggest '_out'];
[file2,path2] = uiputfile('.txt','Select or Type Name of Output File',filesuggest);
fid2 = fopen(fullfile(path2,file2),'wt');
% build header %
for n = 1:size(header,1)
    headerline = header{n,1};
    if headerline(1) ~= '%' % make sure each header line starts with '%'
        headerline = strjoin({'%',headerline});
    end
    fprintf(fid2,'%s\n',headerline);
end
% write code used in computations
fprintf(fid2,'%%\tAngles computed with %s%s\n',path,'black_lab_angles.m');
% write column headings %
fprintf(fid2,'%sRadiometer\tYoke    \tTilt    \tRotation\n','%');
% write stage angles %
fprintf(fid2,'%.7f\t%.7f\t%.7f\t%.7f\n',transpose(stage));
fclose(fid2);

disp('done')