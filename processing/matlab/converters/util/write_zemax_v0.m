



function status = write_zemax(S, I, Az, Rz, BRDF, filepath)
    % Write to Zemax BSDF file.

    name_sample = 'test';
    name_source = 'test';
    name_angles = 'test';
    filenames = ['blanktest', 'test1', 'test2'];
    
    M = length(filenames);
        % DOESNT WORK FOR STR


    name_dates = ['test1', 'test2'];
    filepath_bsdf_file = 'test';
    name_contact = 'test';
    sample_rotations = S;
    Azq = Az;
    Rzq = Rz;
    TIS = 0;







    % =======

    status = false;
    
    line_break = ...
        "# ======================================================\n";
    line_sample = ...
        "# Sample: " + name_sample + "\n";
        % e.g.: "# Sample: NiTE on Invar\n"
    line_source = ...
        "# Light source: " + name_source + "\n";
        % e.g.: "# Light source: red laser\n"
    line_angles = ...
        "# Angles measured: (I,A,R) = " + name_angles + "\n";
        % e.g.: 
        % "# Angles measured: (I,A,R) = (10:20:70, -90:10:90, -80:10:80)\n"
    line_blankdataset = ...
        "# Blank dataset: '" + filenames(1) + "'\n";
        % e.g.: "# Blank dataset: 'blank_measurement.xls'\n"
    
    line_datasets = "# Dataset(s): "; % initialize
    for m = 1:M
        if m > 1 % if not first dataset
            line_datasets = line_datasets + ", "; % add comma between datasets
        end
        line_datasets = line_datasets + "'" + filenames(m + 1) + "'";
        % note first element in 'filenames' is blank, so add 1 to m
    end
    line_datasets = line_datasets + "\n"; % finalize
        % e.g.: "# Dataset(s): 'sample_measurement_1.xls', ...
        % 'sample_measurement_2.xls', 'sample_measurement_3.xls'\n"
    
    line_dates = "# Date(s) measured: "; % initialize
    for date_id = 1 : length(name_dates)
        if date_id > 1 % if not first date
            line_dates = line_dates + ", "; % add comma between dates
        end
        line_dates = line_dates + name_dates(date_id);
    end
    line_dates = line_dates + "\n"; % finalize
        % e.g.: "# Date(s) measured: 2025/09/15, 2025/09/16\n"
    
    line_SampleRot = "%i"; % initialize
    if M > 1
    
        % for m = 2:M
        %     line_SampleRot = line_SampleRot + "	%i"; % note space between %i needs to be 
        %         % tab else Zemax fails to read BSDF file, and cannot have tab 
        %         % after last element
        % end
    
        % Need to define [0,360], but assuming only [0,90] is measured.
        % Therefore, M is number of datasets for [0,90]. To mirror, skip 90
        % and copy in reverse to map measured (90,0] to inferred (90,180].
        % However, also need to flip Az direction for sample rotations
        % (90,180] --> 360-Az. Then, copy (0,180] to (180,360] without any 
        % Az change. In total, this will be 4*(M-1)+1 sample rotations.
    
        for dummy_rotation = 2 : (4 * (M - 1) + 1)
            line_SampleRot = line_SampleRot + "	%i"; % note space between %i needs to be 
                % tab else Zemax fails to read BSDF file, and cannot have tab 
                % after last element
        end
    
    end
    line_SampleRot = line_SampleRot + "\n"; % finalize
    
    line_Iu = "%i"; % initialize
    if nI > 1
        for i = 2:nI
            line_Iu = line_Iu + "	%i"; % note space between %i needs to be 
                % tab else Zemax fails to read BSDF file, and cannot have tab 
                % after last element
        end
    end
    line_Iu = line_Iu + "\n"; % finalize
    
    line_Az = "%i"; % initialize
    if nAzq > 1
        for j = 2:nAzq
            line_Az = line_Az + "	%i"; % note space between %i needs to be 
                % tab else Zemax fails to read BSDF file, and cannot have tab 
                % after last element
        end
    end
    line_Az = line_Az + "\n"; % finalize
    
    line_Rz = "%i"; % initialize
    if nRzq > 1
        for k = 2:nRzq
            line_Rz = line_Rz + "	%i"; % note space between %i needs to be 
                % tab else Zemax fails to read BSDF file, and cannot have tab 
                % after last element
        end
    end
    line_Rz = line_Rz + "\n"; % finalize
    
    line_BRDF = "%1.3e"; % initialize
    if nRzq > 1
        for k = 2:nRzq % Rz here because BRDF row is constant (I,Az) across Rz
            line_BRDF = line_BRDF + "	%1.3e"; % note space between %1.3e 
                % needs to be tab else Zemax fails to read BSDF file, and
                % cannot have tab after last element
        end
    end
    line_BRDF = line_BRDF + "\n"; % finalize
    
    % =========================================================================
    % Write to file:
    
    % Open file:
    if FILENAME_IS_AVAILABLE
        fid = fopen(filepath_bsdf_file, 'wt');
    end
    
    % Write:
    
    fprintf(fid, line_break);
    fprintf(fid, line_break);
    fprintf(fid, "# [BEGIN] DEVELOPMENT INFORMATION:\n");
    fprintf(fid, "# \n");
    fprintf(fid, line_sample);
    fprintf(fid, "# Scatterometer: Wyant College's J&C RT-300S\n");
    fprintf(fid, line_source);
    fprintf(fid, line_angles);
    fprintf(fid, "# Number of measurements averaged: n/a\n");
        % for anisotropic, each dataset is unique sample rotation and therefore
        % no measurements are averaged
    fprintf(fid, line_blankdataset);
    fprintf(fid, line_datasets);
    fprintf(fid, "# Processing script: '" + mfilename() + ".m'\n");
        % e.g.: "# Processing script: 'rt300s_to_bsdf_aniso.m'\n"
    fprintf(fid, "# Processing source: https://github.com/ua-loft/bsdf-tools/tree/" + repo_version + "\n");
    fprintf(fid, line_dates);
    fprintf(fid, "# Note(s): - sample is anisotropic;\n" + ...
        "#          - TIS calculated over entire hemisphere, i.e., " + ...
        "Az=[0,360), but only from BRDF values reported here so " + ...
        "assuming BRDF=0 beyond Rz>=90;\n");
    fprintf(fid, "# Point of contact: " + name_contact + "\n");
        % e.g.: 
        % "# Point of contact: Jacob P. Krell (jacobpkrell@arizona.edu)\n"
    fprintf(fid, "# \n");
    fprintf(fid, "# [END] DEVELOPMENT INFORMATION.\n");
    fprintf(fid, "# ======================================================\n");
    fprintf(fid, "# ======================================================\n");
    fprintf(fid, "# \n");
    
    fprintf(fid, "Source	Measured\n"); % space is tab
    fprintf(fid, "Symmetry	Asymmetrical4D\n"); % space is tab
        % assuming anisotropic sample
    fprintf(fid, "SpectralContent	Monochrome\n"); % space is tab
        % assuming monochromatic light source
    fprintf(fid, "ScatterType	BRDF\n"); % space is tab
    
    sample_rotations_all = [sample_rotations, ...
        sample_rotations(2:end) + 90, sample_rotations(2:end) + 180, ...
        sample_rotations(2:end) + 270]; % make [0,90] into [0,360]
    fprintf(fid, sprintf("SampleRotation	%i\n", length(sample_rotations_all))); % space is tab
    fprintf(fid, line_SampleRot, sample_rotations_all);
    
    fprintf(fid, "AngleOfIncidence	%i\n", nI); % space is tab
    fprintf(fid, line_Iu, Iu);
    fprintf(fid, "ScatterAzimuth	%i\n", nAzq); % space is tab
    fprintf(fid, line_Az, Azq);
    fprintf(fid, "ScatterRadial	%i\n", nRzq); % space is tab
    fprintf(fid, line_Rz, Rzq);
    fprintf(fid, "\n");
    
    fprintf(fid, "Monochrome\n");
        % assuming monochromatic light source
    fprintf(fid, "DataBegin\n");
    
    % Zemax requires [0,360] sample rotations be defined; so, copy/mirror
    % BRDF values (with Az flipped accordingly) from [0,90] sample rotation
    % measurements. To do this,
    
    % First, write measured BRDF values for [0,90] sample rotations:
    for m = 1:M % for sample rotation
        for i = 1:nI % for incident angle
            fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
            for j = 1:nAzq
                fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
            end
        end
    end
    % Second, copy measured [0,90] to inferred (90,180] sample rotation values:
        % - need 360-Az, and to go in reverse order (from 90 back to 0)
    for m = (M - 1) : -1 : 1 % for sample rotation, flipped from [0,90] to (90,0]
        for i = 1:nI % for incident angle
            fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
            for j = nAzq : -1 : 1 % flipped because need 360-Az (to flip about incident plane),
                    % and Azq=[0,360] with equal steps can simply be flipped in
                    % element order to achieve 360-Az
                fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
            end
        end
    end
    % Third, copy to (180,270] sample rotation values:
        % - exact same as 'First' except starting at m=2 b/c m=1 in 'Second'
    for m = 2:M % for sample rotation
        for i = 1:nI % for incident angle
            fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
            for j = 1:nAzq
                fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
            end
        end
    end
    % Fourth, copy to (270,360] sample rotation values:
        % - exact same as 'Second'
    for m = (M - 1) : -1 : 1 % for sample rotation, flipped from [0,90] to (90,0]
        for i = 1:nI % for incident angle
            fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
            for j = nAzq : -1 : 1 % flipped because need 360-Az (to flip about incident plane),
                    % and Azq=[0,360] with equal steps can simply be flipped in
                    % element order to achieve 360-Az
                fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
            end
        end
    end
    
    fprintf(fid, "DataEnd\n");
    
    % Values have been written, so may close file:
    fclose(fid);







    
    
    
    
    
    
    status = true;

end




