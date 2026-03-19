
% References:
% [1] Max Duque's whitepaper on RT-300S
% [2] Max Duque's masters thesis

function [A, I, R, S, BRDF] = process_rt300s(blankpath, filepaths, S)
% Zeroes data (single or mutliple), averages if applicable, and formats
% into unique A,I,R,S entries. Does not apply plane symmetry or anything
% else like that.

% Load data:
[A0, I0, R0, RT0] = load_single_rt300s(blankpath);
[A, I, R, RT] = load_multiple_rt300s(filepaths);
n = length(A); % number of measurements

% First correction (zeroing system by subtracting blank measurement):
    % - from [1] and [2]
for j = 1:n
    if (any(A0 ~= A{j}) || any(I0 ~= I{j}) || any(R0 ~= R{j}))
        error("Measurement angles of 'blankpath' and 'filepaths' must be identical.")
    end
    RT{j} = RT{j} - RT0;
end

% Average (if stage rotation is equal):

if isscalar(S) % then no need to extend A,I,R,S vectors

    A = A0;
    I = I0;
    R = R0;
    S = repelem(S, length(A));

    RT_avg = zeros(size(RT0));
    for j = 1:n
        RT_avg = RT_avg + RT{j};
    end
    RT = RT_avg / n;

else

    if length(S) ~= n
        error("Stage rotation angles 'S' must be a vector corresponding to 'filenames'.")
    end

    % If any 'S' elements are equal, average their 'RT' values. Otherwise,
    % simply extend the A,I,R,S vectors:
    
    Su = unique(S);
    if length(Su) ~= length(S)
        warning("There are repeated stage rotation 'S' values. Attempting to average them.")
        
        error("THIS CODE NEEDS DEV.")
        % rtw: cycle through same S values somehow

    else % then each measurement is unique stage rotation
        A = repmat(A0, 1, n);
        I = repmat(I0, 1, n);
        R = repmat(R0, 1, n);
        S = repelem(S, length(RT0));
        RT_vec = RT{1};
        if n > 1
            for j = 2:n % concatenate cell into single vector
                RT_vec = [RT_vec, RT{j}];
            end
        end
        RT = RT_vec;
    end

end

% Average-out and remove any redundant/duplicated angles:
    % - forces domain of A \in [-90, +90)
mA_lo = A < -90;
A(mA_lo) = A(mA_lo) + 180; % force to A >= -90 domain
mA_hi = A >= 90;
A(mA_hi) = A(mA_hi) - 180; % force to A < +90 domain
mA = or(mA_lo, mA_hi);
R(mA) = -R(mA); % R sign flips for both A +/- 180
mkeep = true(size(RT)); % mask of elements to keep
for Aj = unique(A)
    mA = A == Aj; % reset mask (now cycling through all A values)
    for Ij = unique(I(mA))
        mAI = and(mA, I == Ij);
        for Rj = unique(R(mAI))
            mAIR = and(mAI, R == Rj);
            for Sj = unique(S(mAIR))
                mAIRS = and(mAIR, S == Sj);
                if sum(mAIRS) > 1
                    warning("Redundant measurements exist at (A,I,R,S) = (%i,%i,%i,%i). Averaging-out and removing redundancy.", Aj, Ij, Rj, Sj)
                    mAIRS_indices = find(mAIRS); % switch logical to indices
                    RT(mAIRS_indices(1)) = mean(RT(mAIRS)); % set first entry to average
                    mkeep(mAIRS_indices(2:end)) = false; % remove other entries
                end
            end
        end
    end
end
A = A(mkeep); % keep only unique angles
I = I(mkeep);
R = R(mkeep);
S = S(mkeep);
RT = RT(mkeep);

% Second correction (setting floor to zero):
    % - if following [1] and [2], then:
% RT = RT - min(RT); % shift all values so min=0
    % - or, if opting instead to not touch positive RT values:
RT(RT < 0) = 0; % set only negative values to 0

% Third correction (remove obscured measurements):
    % - from [1] and [2], but expanded beyond incident plane too
dA = 30; % [deg], +/- required clearance about A = +/-90
dR = 10; % [deg], +/- required clearance about R = -I
    % - allowed values are > |clearance|, not >= |clearance|
mA = ~and(-90 + dA < A, A < 90 - dA); % 1 if potentially obscured
mR = ~or(-sign(A).*R < -I - dR, -I + dR < -sign(A).*R); % 1 if potentially obscured
m = ~and(mA, mR); % 1 if unobscured
A = A(m); % keep only unobscured datapoints
I = I(m);
R = R(m);
S = S(m);
RT = RT(m);

% Convert RT to BRDF:
BRDF = RT ./ (pi * cosd(R)); % equation 4.6 of [2]

end

