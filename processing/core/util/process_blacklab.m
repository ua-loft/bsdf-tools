
% References:
% [1] 

% Initialized 2026/05/02 from 'process_rt300s.m'.

% ========================

function [lambda, src_z, src_a, view_z, view_a, BRDF] = process_blacklab(filepaths)
% Loads and averages data (if applicable). Does not apply plane symmetry 
% or anything else like that.

% Load data:
[lambda, src_z, src_a, view_z, view_a, BRDF] = load_multiple_blacklab(filepaths);
n = length(filepaths); % number of measurements

% Get masks of angles+wavelengths per file:
mkeep = cell(n, 1);
for j = 1:n
    mkeep{j} = false(size(BRDF{j})); % logical for sample
    for lambda_j = unique(lambda{j})
        mL = lambda{j} == lambda_j;
        for src_z_j = unique(src_z{j}(mL))
            mLSz = and(mL, src_z{j} == src_z_j);
            for src_a_j = unique(src_a{j}(mLSz))
                mLSzSa = and(mLSz, src_a{j} == src_a_j);
                for view_z_j = unique(view_z{j}(mLSzSa))
                    mLSzSaVz = and(mLSzSa, view_z{j} == view_z_j);
                    for view_a_j = unique(view_a{j}(mLSzSaVz))
                        mLSzSaVzVa = and(mLSzSaVz, view_a{j} == view_a_j);
                        if any(mLSzSaVzVa)
                            mkeep{j}(mLSzSaVzVa) = true;
                        end
                    end
                end
            end
        end
    end
end

% Currently, only supporting multiple sample measurements if all have same
% angles. Catch exceptions:
if n > 1 % if multiple sample measurements
    for j = 2:n
        if any(mkeep{j} ~= mkeep{j - 1})
            error("Multiple files with different angles+wavelengths is not currently supported. Ensure all sample data files measured identical angles and wavelengths.")
        end
    end
end
    
% Update dataset to the angles shared across sample measurements:
for j = 1:n
    % lambda{j} = lambda{j}(mkeep{j});
    % src_z{j} = src_z{j}(mkeep{j});
    % src_a{j} = src_a{j}(mkeep{j});
    % view_z{j} = view_z{j}(mkeep{j});
    % view_a{j} = view_a{j}(mkeep{j});
    BRDF{j} = BRDF{j}(mkeep{j});
end

% Assuming same angles and wavelengths (and same order), no longer need
% cells, so put into 1D vectors (using first cell for all):
lambda = lambda{1}(mkeep{1});
src_z = src_z{1}(mkeep{1});
src_a = src_a{1}(mkeep{1});
view_z = view_z{1}(mkeep{1});
view_a = view_a{1}(mkeep{1});

% Average across measurements, assuming same angles and wavelengths (and 
% in same order):
BRDF_avg = zeros(size(BRDF{1}));
for j = 1:n
    BRDF_avg = BRDF_avg + BRDF{j};
end
BRDF = BRDF_avg / n;

end

