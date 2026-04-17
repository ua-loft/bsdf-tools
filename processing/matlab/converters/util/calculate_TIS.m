
function TIS = calculate_TIS(Pi, Ai, Ps, As, BRDF, ISOTROPIC)
% Calculate TIS for Zemax, with data in FRED frame.
% Assumes FRED domain already set; meaning, Ps \in [0, 90] and As \in [0,
% 180] if isotropic of [0, 360) if anisotropic.
% Format: TIS(S_index, I_index), which is TIS(Ai_index, Pi_index).

DEBUG = false;

% =======

RT = BRDF .* cosd(Ps); % TIS is integral of reflectance RT, not BRDF

% Expand data set to Ps = 90, for full integration bounds:

Pi_new = [];
Ai_new = [];
Ps_new = [];
As_new = [];
RT_new = [];

eps = 1e-6; % +/- threshold of numeric error

for Ai_j = unique(Ai)'
    mAi = abs(Ai - Ai_j) < eps;
    for Pi_j = unique(Pi(mAi))'
        mAiPi = and(mAi, abs(Pi - Pi_j) < eps);

        Ps_max = max(Ps(mAiPi));
        mAiPiPs = and(mAiPi, abs(Ps - Ps_max) < eps);

        Pi_new = [Pi_new; Pi(mAiPiPs)];
        Ai_new = [Ai_new; Ai(mAiPiPs)];
        Ps_new = [Ps_new; repelem(90, sum(mAiPiPs), 1)];
        As_new = [As_new; As(mAiPiPs)];
        RT_new = [RT_new; RT(mAiPiPs)];

    end
end

Pi = [Pi; Pi_new];
Ai = [Ai; Ai_new];
Ps = [Ps; Ps_new];
As = [As; As_new];
RT = [RT; RT_new];




% IF ANISOTROPIC, WANT TO WRAP PERIODIC DOMAIN NOW:

% ...






% Convert to unit vectors (x,y,z points on unit sphere):

TIS = zeros(length(unique(Ai)), length(unique(Pi)));

Ai_id = 0;
for Ai_j = unique(Ai)'
    Ai_id = Ai_id + 1;
    mAi = abs(Ai - Ai_j) < eps;
    Pi_id = 0;
    for Pi_j = unique(Pi(mAi))'
        Pi_id = Pi_id + 1;
        mAiPi = and(mAi, abs(Pi - Pi_j) < eps);

        x = sind(Ps(mAiPi)) .* cosd(As(mAiPi));
        y = sind(Ps(mAiPi)) .* sind(As(mAiPi));
        z = cosd(Ps(mAiPi));

        % Normalize unit vectors:

        norms = sqrt(x.^2 + y.^2 + z.^2);
        x = x ./ norms;
        y = y ./ norms;
        z = z ./ norms;

        % Make into full sphere:
        RT_mAiPi = RT(mAiPi);
        if ISOTROPIC
            x = [x; x];
            y = [y; -y];
            z = [z; z];
            RT_mAiPi = [RT_mAiPi; RT_mAiPi];
        end
        x = [x; x];
        y = [y; y];
        z = [z; -z];
        RT_mAiPi = [RT_mAiPi; RT_mAiPi];

% Generate triangular mesh / convex hull, of unit sphere points:

        k = convhull(x, y, z);

        % Ps_mAiPi = Ps(mAiPi);
        % As_mAiPi = As(mAiPi);

        n = size(k, 1); % number of mesh elements
        a = zeros(3, n); % [x;y;z] of mesh element's first vertex
        b = zeros(3, n); % [x;y;z] of mesh element's second vertex
        c = zeros(3, n); % [x;y;z] of mesh element's third vertex
        RT_avg = zeros(1, n);
        for m = 1:n % index of mesh element
            a(:, m) = [x(k(m, 1)); y(k(m, 1)); z(k(m, 1))];
            b(:, m) = [x(k(m, 2)); y(k(m, 2)); z(k(m, 2))];
            c(:, m) = [x(k(m, 3)); y(k(m, 3)); z(k(m, 3))];
            RT_avg(m) = (RT_mAiPi(k(m, 1)) + RT_mAiPi(k(m, 2)) + RT_mAiPi(k(m, 3))) / 3; % average across mesh element
        end
        
% Curve mesh elements to get exact solid angle:

        % Calculate solid area formed by triangle vertices:
            % - Van Oosterom-Strackee solid angle formula
        numer = abs(dot(a, cross(b, c, 1), 1));
        denom = 1 + dot(a, b, 1) + dot(b, c, 1) + dot(c, a, 1);
        SA = 2 * atan2(numer, denom); % solid angle of mesh elements
        
        % Check result:
        if abs(sum(SA) - 4*pi) > eps
            warning("Convex hull (after mapping mesh elements to solid angle) in TIS calculation did not yield expected 4*pi surface-area integral of sphere. Do not trust TIS value.")
        end

% Integrate:

        TIS_j = sum(RT_avg .* SA) / 2; % divide by 2 because mirrored  
            % mirror to full sphere, and TIS is hemisphere
        
% Normalize to Zemax definition of TIS:

        % TIS(Ai_id, Pi_id) = TIS_j / 2; % Zemax defines TIS as the ratio of 
        %     % a black sample's full hemisphere to a zero-absorption sample;
        %     % if Lambertian then RT = 1/pi --> TIS = 2, hence divide by 2.
        TIS(Ai_id, Pi_id) = TIS_j; % or, since BRDF already normalized

% Debug why I=30 has dip in TIS:

        if DEBUG

            figure
            % trisurf(k, x, y, z, RT_mAiPi) % SA)
            trisurf(k, x, y, z, RT_avg)
            shading flat
            colorbar
            axis equal
            xlabel('X Axis')
            ylabel('Y Axis')
            zlabel('Z Axis')
    
            % figure
            % histogram(SA)
    
            fprintf("Mean SA: %.6f\nMean RT: %.6f\nSum SA: %.6f\nTIS: %.6f\n\n", mean(SA), mean(RT_avg), sum(SA), TIS_j)
            % note mean(RT_avg) = mean(RT_mAiPi)

            % stop=1;

        end



    end
end



if DEBUG

    % TIS
    
    % stop = 1


end






end

