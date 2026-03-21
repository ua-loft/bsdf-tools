
function status = write_zemax(S, I, Az, Rz, BRDF, filepath, ISOTROPIC, OVERWRITE, header_info)
    % 'filepath' is full filepath of output *.bsdf file.
    % Only monochromatic light source is currently supported.
    % Set 'header_info = ""' to leave blank.

    status = false; % initialize

    % Check if file is available, and open/create if so:
    if exist(filepath, 'file') % if file already exists
        if OVERWRITE % if user specified to overwrite the file
            warning("BSDF file already exists. Overwriting the file.");
        else
            error("BSDF file already exists. Change 'filepath' or set 'OVERWRITE=true'.");
        end
    end
    fid = fopen(filepath, 'wt'); % if no error above, open file

    % Write header information for measurement:
    fprintf(fid, header_info);

    % Write header information for assumptions (symmetry, source, etc.):
    fprintf(fid, "Source\tMeasured\n");
    if ISOTROPIC
        fprintf(fid, "Symmetry\tPlaneSymmetrical\n");
    else
        fprintf(fid, "Symmetry\tAsymmetrical4D\n");
    end
    fprintf(fid, "SpectralContent\tMonochrome\n");
        % assuming monochromatic source
    fprintf(fid, "ScatterType\tBRDF\n");

    % Write header information for angles of BRDF data:

    Su = unique(S);
    nS = length(Su);
    Iu = unique(I);
    nI = length(Iu);
    Azu = unique(Az);
    nAz = length(Azu);
    Rzu = unique(Rz);
    nRz = length(Rzu);

    fprintf(fid, "SampleRotation\t%i\n", nS);
    fprintf(fid, "%i", Su(1)); % first value
    if nS > 1
        for S_j = Su(2:end)' % non-first value(s)
            fprintf(fid, "\t"); % tab, such that last value doesn't have tab
            fprintf(fid, "%i", S_j); % value
        end
    end
    fprintf(fid, "\n");

    fprintf(fid, "AngleOfIncidence\t%i\n", nI);
    fprintf(fid, "%i", Iu(1)); % first value
    if nI > 1
        for I_j = Iu(2:end)' % non-first value(s)
            fprintf(fid, "\t"); % tab, such that last value doesn't have tab
            fprintf(fid, "%i", I_j); % value
        end
    end
    fprintf(fid, "\n");

    fprintf(fid, "ScatterAzimuth\t%i\n", nAz);
    fprintf(fid, "%i", Azu(1)); % first value
    if nAz > 1
        for Az_j = Azu(2:end)' % non-first value(s)
            fprintf(fid, "\t"); % tab, such that last value doesn't have tab
            fprintf(fid, "%i", Az_j); % value
        end
    end
    fprintf(fid, "\n");

    fprintf(fid, "ScatterRadial\t%i\n", nRz);
    fprintf(fid, "%i", Rzu(1)); % first value
    if nRz > 1
        for Rz_j = Rzu(2:end)' % non-first value(s)
            fprintf(fid, "\t"); % tab, such that last value doesn't have tab
            fprintf(fid, "%i", Rz_j); % value
        end
    end
    fprintf(fid, "\n");

    fprintf(fid, "Monochrome\n"); % assuming monochromatic source
    fprintf(fid, "DataBegin\n");

    % Write BRDF data:

    TIS = calculate_TIS(S, I, Az, Rz, BRDF);

    S_index = 0;
    for S_j = Su'
        S_index = S_index + 1;
        mS = S == S_j;
        I_index = 0;
        for I_j = Iu'
            I_index = I_index + 1;
            mSI = and(mS, I == I_j);

            fprintf(fid, "TIS\t%.6f\n", TIS(S_index, I_index));

            for Az_j = Azu'
                mSIAz = and(mSI, Az == Az_j);
                
                % First entry (since do not want tab after last entry):
                mSIAzRz = and(mSIAz, Rz == Rzu(1));
                if sum(mSIAzRz) > 1
                    throw_error_msg1();
                end
                fprintf(fid, "%.4e", BRDF(mSIAzRz));
                
                % Non-first entries:
                if nRz > 1
                    for Rz_j = Rzu(2:end)'
                        mSIAzRz = and(mSIAz, Rz == Rz_j);
                        if sum(mSIAzRz) > 1
                            throw_error_msg1();
                        end
                        fprintf(fid, "\t"); % tab
                        fprintf(fid, "%.4e", BRDF(mSIAzRz)); % value
                    end
                end
                fprintf(fid, "\n");

            end
        end
    end

    % Close file:
    fprintf(fid, "DataEnd\n");
    fclose(fid);

    status = true; % success

end


function TIS = calculate_TIS(S, I, Az, Rz, BRDF)
    TIS = zeros(length(unique(S)), length(unique(I)));
end


function throw_error_msg1()
    error("Unexpected multiple BRDF entries for same angle. Debug formatting of input arguments prior to function call.");
end

