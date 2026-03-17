



clearvars, clc, close all


% USER INPUTS:
filename_in = 'DEBUG_ANISO_aniso.txt';
filename_out = 'DEBUG_ANISO_aniso_SYMM.txt';




% =============================
% =============================


% If sample has xz plane symmetry (at \phi_i = 0 orientation), then:
    % BRDF(\phi_i, \phi_s) = BRDF(-\phi_i, -\phi_s).

% If sample has yz plane symmetry (at \phi_i = 0 orientation), then:
    % BRDF(\phi_i, \phi_s) = BRDF(180 - \phi_i, -\phi_s).

[theta_i, phi_i, theta_s, phi_s, BRDF] = load_FRED(filename_in);

% Assuming \psi_i \in [0,-90] with operators YZ and XY, such that:
%   YZ([0,-90]) = [0,-90] U [180,270] = [180,360]
%   XY([180,360]) = [180,360] U [-180,-360] = [0,360]

% Apply yz plane symmetry:
theta_i = [theta_i; theta_i];
phi_i   = [phi_i;   180 - phi_i];
theta_s = [theta_s; theta_s];
phi_s   = [phi_s;   -phi_s];
BRDF    = [BRDF;    BRDF];

% Apply xy plane symmetry:
theta_i = [theta_i; theta_i];
phi_i   = [phi_i;   -phi_i];
theta_s = [theta_s; theta_s];
phi_s   = [phi_s;   -phi_s];
BRDF    = [BRDF;    BRDF];

% Adjust azimuth angles to proper [0,360) domain:
mi = phi_i < 0; % incident
while any(mi)
    phi_i(mi) = phi_i(mi) + 360;
    mi = phi_i < 0;
end
mi = phi_i >= 360;
while any(mi)
    phi_i(mi) = phi_i(mi) - 360;
    mi = phi_i >= 360;
end
ms = phi_s < 0; % scatter
while any(ms)
    phi_s(ms) = phi_s(ms) + 360;
    ms = phi_s < 0;
end
ms = phi_s >= 360;
while any(ms)
    phi_s(ms) = phi_s(ms) - 360;
    ms = phi_s >= 360;
end

% Check for and average any overlapping angles:
theta_i_unique = unique(theta_i);
phi_i_unique = unique(phi_i);
theta_s_unique = unique(theta_s);
phi_s_unique = unique(phi_s);
for theta_i_current = theta_i_unique'
    m1 = theta_i == theta_i_current;
    for phi_i_current = phi_i_unique'
        m2 = and(m1, phi_i == phi_i_current);
        for theta_s_current = theta_s_unique'
            m3 = and(m2, theta_s == theta_s_current);
            for phi_s_current = phi_s_unique'
                m = and(m3, phi_s == phi_s_current); % mask
                if sum(m) > 1
                    BRDF(m) = mean(BRDF(m)); % average duplicate angles
                end
            end
        end
    end
end

% ===========
% Write new FRED file:

% Open text file:
fid = fopen(filename_out, 'w');

% Write header:
fprintf(fid, 'type bsdf_data\n');
fprintf(fid, 'format angles=deg bsdf=value scale=1\n');

theta_i_unique_sorted = sort(theta_i_unique);
phi_i_unique_sorted = sort(phi_i_unique);
theta_s_unique_sorted = sort(theta_s_unique);
phi_s_unique_sorted = sort(phi_s_unique);
for theta_i_current = theta_i_unique_sorted'
    m1 = theta_i == theta_i_current;
    for phi_i_current = phi_i_unique_sorted'
        
        fprintf(fid, '%i	%i\n', theta_i_current, phi_i_current); 
            % space is tab
        
        m2 = and(m1, phi_i == phi_i_current);
        for theta_s_current = theta_s_unique_sorted'
            m3 = and(m2, theta_s == theta_s_current);
            
            if theta_s_current == 0
                BRDF(m3) = mean(BRDF(m3)); % average all \theta_s=0 values
                m = find(m3); % switch to indices (not logical)
                m = m(1); % use first (because all same value)
                
                if ~isnan(BRDF(m)) % only write if not nan
                    fprintf(fid, '0	0	%.6f\n', BRDF(m)); % space is tab
                        % (only use \phi_s = 0 for \theta_s = 0)
                end

            else
                
                for phi_s_current = phi_s_unique_sorted'
                    m = and(m3, phi_s == phi_s_current); % mask
                    if sum(m) > 1
                        m = find(m); % switch to indices (not logical)
                        m = m(1); % use first true index (because all same)
                    end
                    
                    if ~isnan(BRDF(m)) % only write if not nan
                        fprintf(fid, '%i	%i	%.6f\n', ...
                            theta_s_current, phi_s_current, BRDF(m)); % space is tab
                    end

                end
            end
        end
    end
end

% Close text file:
fclose(fid);







% =====================================
% [BEGIN] FUNCTIONS:





function [theta_i, phi_i, theta_s, phi_s, BRDF] = load_FRED(filename)
    % Output vectors corresponding to BRDF values.
    data = readmatrix(filename);
    mNaN = isnan(data(:, 3));
    mBRDF = ~mNaN;
    theta_i_blockheaders = data(mNaN, 1);
    phi_i_blockheaders = data(mNaN, 2);
    theta_s = data(mBRDF, 1);
    phi_s = data(mBRDF, 2);
    BRDF = data(mBRDF, 3);
    blockstarts = find(mNaN) + 1; % +1 for where (\theta_s,\phi_s) begin
    blockends = [blockstarts(2:end) - 2; size(data, 1)];
    blocklengths = blockends - blockstarts + 1;
    nblocks = length(blockstarts);
    L = sum(blocklengths);
    theta_i = nan(L, 1);
    phi_i = nan(L, 1);
    j0 = 1;
    for j = 1:nblocks
        j1 = j0 + blocklengths(j) - 1;
        theta_i(j0:j1) = repmat(theta_i_blockheaders(j), blocklengths(j), 1);
        phi_i(j0:j1) = repmat(phi_i_blockheaders(j), blocklengths(j), 1);
        j0 = j1 + 1;
    end
end




