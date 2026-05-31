
function [A, I, R, RT] = load_multiple_rt300s(filepaths)
    % 'filepaths' is cell of strings.
    % A,I,R,RT are cells of vectors.

    if ~iscell(filepaths) % if not cell
        if isstr(filepaths) % if string, then handle exception
            filepaths = {filepaths};
            warning("Converted 'filepaths' to cell to handle exception of single filepath string.")
        else % not cell and not string --> throw error
            error("'filepaths' should be a cell of strings.")
        end
    end
    
    n = length(filepaths);
    A = cell(n, 1);
    I = cell(n, 1);
    R = cell(n, 1);
    RT = cell(n, 1);
    for j = 1:n
        [A{j}, I{j}, R{j}, RT{j}] = load_single_rt300s(filepaths{j});
    end

end

