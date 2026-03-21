
function status = write_zemax(S, I, Az, Rz, BRDF, filepath)

    

% PRINT HEADER STUFF

fprintf(fid, "Source\tMeasured\n")
fprintf(fid, "Symmetry\tAsymmetrical4D\n")
fprintf(fid, "SpectralContent\tMonochrome\n")
fprintf(fid, "ScatterType\tBRDF\n")

fprintf(fid, "SampleRotation\t%i\n", length(unique(S)));
for S_j = unique(S)
    fprintf("%i\t", S_j)
end
fprintf("\n")
% NEED TO DELETE LAST TAB

fprintf(fid, "AngleOfIncidence\t%i\n", length(unique(I)));
for I_j = unique(I)
    fprintf("%i\t", I_j)
end
fprintf("\n")
% NEED TO DELETE LAST TAB\

fprintf(fid, "ScatterAzimuth\t%i\n", length(unique(Az)));
for Az_j = unique(Az)
    fprintf("%i\t", Az_j)
end
fprintf("\n")
% NEED TO DELETE LAST TAB

fprintf(fid, "ScatterRadial\t%i\n", length(unique(Rz)));
for Rz_j = unique(Rz)
    fprintf("%i\t", Rz_j)
end
fprintf("\n")
% NEED TO DELETE LAST TAB

fprintf("\n")

fprintf("Monochrome\n")
fprintf("DataBegin\n")

TIS = calculate_TIS();

k = 0;
for S_j = unique(S)'
    mS = S == S_j;
    for I_j = unique(I(mS))'
        mSI = and(mS, I == I_j);
        k = k + 1; % index of S,I block for TIS
        fprintf("TIS %.6f\n", TIS(k))
        for Az_j = unique(Az(mSI))'
            mSIAz = and(mSI, Az == Az_j);
            for Rz_j = unique(Rz(mSIAz))'
                mSIAzRz = and(mSIAz, Rz == Rz_j);
                fprintf("%.4e\t", BRDF(mSIAzRz));
            end
            % DELETE LAST TAB
        end
    end
end

fprintf("DateEnd")











end

