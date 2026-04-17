
function [Pi, Ai, Ps, As, BRDF] = load_fred(filepath)

    data = readmatrix(filepath);

    mheader = isnan(data(:, 3)); % mask of header (Pi,Ai,NaN) lines
    mblock = ~mheader; % mask of block (Ps,As,BRDF) lines

    Ps = data(mblock, 1);
    As = data(mblock, 2);
    BRDF = data(mblock, 3);

    Pi = zeros(size(BRDF));
    Ai = zeros(size(BRDF));

    mheader_j = find(mheader); % logical to indices
    j0 = mheader_j + 1; % first index of block(s)
    if length(mheader_j) > 1 % if more than one block
        j1 = [mheader_j(2:end) - 1; size(data, 1)]; % last index of blocks
    else
        j1 = length(BRDF); % last index of block
    end
    dj = j1 - j0; % difference of first/last indices of block(s)

    Pi_j = data(mheader, 1);
    Ai_j = data(mheader, 2);
    k1 = 0; % initialize, such that k0 = 1 on first iteration
    for j = 1:length(Pi_j)
        k0 = k1 + 1;
        k1 = k0 + dj(j);
        Pi(k0:k1) = Pi_j(j);
        Ai(k0:k1) = Ai_j(j);
    end

end

