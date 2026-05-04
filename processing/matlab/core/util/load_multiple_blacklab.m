
function [lambda, src_z, src_a, view_z, view_a, BRDF] = load_multiple_blacklab(filepaths)
    % 'filepaths' is cell of strings.
    % lambda, src_z, src_a, view_z, view_a, BRDF are cells of vectors.

    if ~iscell(filepaths) % if not cell
        if isstr(filepaths) % if string, then handle exception
            filepaths = {filepaths};
            warning("Converted 'filepaths' to cell to handle exception of single filepath string.")
        else % not cell and not string --> throw error
            error("'filepaths' should be a cell of strings.")
        end
    end
    
    n = length(filepaths);
    lambda = cell(n, 1);
    src_z = cell(n, 1);
    src_a = cell(n, 1);
    view_z = cell(n, 1);
    view_a = cell(n, 1);
    BRDF = cell(n, 1);
    for j = 1:n
        [lambda{j}, src_z{j}, src_a{j}, view_z{j}, view_a{j}, BRDF{j}] = load_single_blacklab(filepaths{j});
    end

end

