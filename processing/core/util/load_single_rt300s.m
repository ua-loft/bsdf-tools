
function [A, I, R, RT] = load_single_rt300s(filepath)
    % Load Excel file data output by RT-300S measurement.
    % A,I,R,RT are vectors.
    
    sheets = sheetnames(filepath);
    i0 = 1;
    for k = 1:length(sheets)
        raw = readmatrix(filepath, 'Sheet', sheets{k});
        if ~isempty(raw) % handle last sheet being empty
            iL = size(raw, 2) - 1; % minus 1 b/c first column empty
            i1 = i0 + iL - 1;
            A(i0:i1) = raw(7, 2:end);
            I(i0:i1) = raw(8, 2:end);
            R(i0:i1) = raw(9, 2:end);
            RT(i0:i1) = raw(22, 2:end);
            i0 = i1 + 1;
        end
    end

end

