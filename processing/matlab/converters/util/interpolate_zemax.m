
function [S, I, Az, Rz, BRDF] = interpolate_zemax(S, I, Az, Rz, BRDF, dAz, dRz, ISOTROPIC)
    % Assumes Az \in [0, 360).

    if ISOTROPIC

        S = zeros(size(S)); % set all stage rotations to 0 (by convention)

        % Assuming Az \in [0, 360), force to [0, 180] domain:
        m = Az > 180;
        Az(m) = 360 - Az(m); % isotropic condition, e.g., 184 to 176

        % Average-out and remove redundant Az entries:
        mkeep = true(size(BRDF));
        for I_j = unique(I)'
            mI = I == I_j;
            for Rz_j = unique(Rz)'
                mIRz = and(mI, Rz == Rz_j);
                for Az_j = unique(Az)'
                    mIRzAz = and(mIRz, Az == Az_j);
                    if sum(mIRzAz) > 1 % then multiple entries
                        mIRzAz_j = find(mIRzAz); % logical to indices
                        BRDF(mIRzAz_j(1)) = mean(BRDF(mIRzAz));
                            % set first to average
                        mkeep(mIRzAz_j(2:end)) = false; 
                            % remove redundant entries
                    end
                end
            end
        end
        S = S(mkeep);
        I = I(mkeep);
        Az = Az(mkeep);
        Rz = Rz(mkeep);
        BRDF = BRDF(mkeep);

    end

    % Extend dataset with outer limits of Az (per S,I,Rz), to interpolate:
    
    S_new = []; % initialize
    I_new = [];
    Az_new = [];
    Rz_new = [];
    BRDF_new = [];

    % n = 3; % number of Az elements to expand with
    
    for S_j = unique(S)'
        mS = S == S_j;
        for I_j = unique(I(mS))'
            mSI = and(mS, I == I_j);
            
            % % =============================================================
            % % [BEGIN] DEV ATTEMPT 1:
            % 
            % for Rz_j = unique(Rz(mSI))'
            %     mSIRz = and(mSI, Rz == Rz_j);
            %     mSIRz_j = find(mSIRz); % logical to indices
            % 
            %     Az_jvec = Az(mSIRz);
            %     [~, order] = sort(Az_jvec);
            %     mSIRz_j_sorted = mSIRz_j(order); % global indices sorted
            % 
            %     mj_lo = mSIRz_j_sorted(1:n);
            %     mj_hi = mSIRz_j_sorted(end-n+1 : end);
            % 
            %     if ISOTROPIC
            %         Az_lo = -Az(mj_lo);
            %         Az_hi = 360 - Az(mj_hi);
            %     else
            %         Az_lo = Az(mj_lo) + 360;
            %         Az_hi = Az(mj_hi) - 360;
            %     end
            % 
            %     S_new = [S_new; S(mj_lo); S(mj_hi)];
            %     I_new = [I_new; I(mj_lo); I(mj_hi)];
            %     Az_new = [Az_new; Az_lo; Az_hi];
            %     Rz_new = [Rz_new; Rz(mj_lo); Rz(mj_hi)];
            %     BRDF_new = [BRDF_new; BRDF(mj_lo); BRDF(mj_hi)];
            % 
            % end
            % 
            % % [END] DEV ATTEMPT 1.
            % % =============================================================
            % =============================================================
            % [BEGIN] DEV ATTEMPT 2:

            % Instead of sort order, use angle cutoff to expand Az:
            delta = 20;
            m_lo = and(mSI, Az < delta);
            if ISOTROPIC
                m_hi = and(mSI, Az > 180 - delta);
                Az_lo = -Az(m_lo); % isotropic symmetry
                Az_hi = 360 - Az(m_hi); % isotropic symmetry
            else % anisotropic
                m_hi = and(mSI, Az > 360 - delta);
                Az_lo = Az(m_lo) + 360;
                Az_hi = Az(m_hi) - 360;
            end

            S_new = [S_new; S(m_lo); S(m_hi)];
            I_new = [I_new; I(m_lo); I(m_hi)];
            Az_new = [Az_new; Az_lo; Az_hi];
            Rz_new = [Rz_new; Rz(m_lo); Rz(m_hi)];
            BRDF_new = [BRDF_new; BRDF(m_lo); BRDF(m_hi)];

            % [END] DEV ATTEMPT 2.
            % =============================================================
            
        end
    end

    S = [S; S_new]; % extend dataset, to expand Az domain for interpolation
    I = [I; I_new];
    Az = [Az; Az_new];
    Rz = [Rz; Rz_new];
    BRDF = [BRDF; BRDF_new];

    % Define query points for interpolation:
    if ISOTROPIC
        Az_q = 0 : dAz : 180; % [0, 180]
    else
        Az_q = 0 : dAz : 360;
        Az_q = Az_q(1 : end-1); % remove 360... want [0, 360)
    end
    Rz_q = 0 : dRz : 180; % [0, 180]
    [Az_q_grid, Rz_q_grid] = meshgrid(Az_q, Rz_q);

    % Interpolate:
    S_all = [];
    I_all = [];
    Az_all = [];
    Rz_all = [];
    BRDF_all = [];
    for S_j = unique(S)'
        mS = S == S_j;
        for I_j = unique(I(mS))'
            mSI = and(mS, I == I_j);
            F = scatteredInterpolant(Az(mSI), Rz(mSI), BRDF(mSI), ...
                'natural', 'none');
            BRDF_new = F(Az_q_grid, Rz_q_grid);
            BRDF_new = BRDF_new(:); % grid to vector
            L = length(BRDF_new);
            S_new = repelem(S_j, L, 1);
            I_new = repelem(I_j, L, 1);
            S_all = [S_all; S_new]; % append values
            I_all = [I_all; I_new];
            Az_all = [Az_all; Az_q_grid(:)];
            Rz_all = [Rz_all; Rz_q_grid(:)];
            BRDF_all = [BRDF_all; BRDF_new];
        end
    end

    % Output final interpolated values:
    S = S_all;
    I = I_all;
    Az = Az_all;
    Rz = Rz_all;
    BRDF = BRDF_all;

end

