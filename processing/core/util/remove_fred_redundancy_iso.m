
function [Pi, Ai, Ps, As, BRDF, lambda] = remove_fred_redundancy_iso(Pi, Ai, Ps, As, BRDF, lambda)
    % For isotropic samples, only need one Ai angle and only need |As - Ai| 
    % \in [0, 180]. This function averages corresponding data (i.e., 
    % constant |As - Ai| values), and returns by convention Ai = 0 and 
    % As \in [0, 180].

    LAMBDA_IS_DUMMY = false;
    if nargin < 6 % then 'lambda' was not input
        lambda = zeros(size(BRDF)); % dummy values
        LAMBDA_IS_DUMMY = true;
    end

    As = abs(mod(As - Ai + 180, 360) - 180); % |As-Ai| is what matters for 
        % isotropic, and with convention of Ai=0 then As=|As-Ai|; however 
        % need to wrap |As-Ai| into [-180,180) about Ai to get |As-Ai| 
        % angular separation rather than linear difference.
    Ai = zeros(size(Ai)); % replace all Ai with 0 (Ai=0 by convention)
    mkeep = true(size(BRDF)); % logical of unique angles to keep
    for lambda_val = unique(lambda)
        mL = lambda == lambda_val;
        for Pi_val = unique(Pi)
            mLPi = and(mL, Pi == Pi_val);
            for Ps_val = unique(Ps)
                mLPiPs = and(mLPi, Ps == Ps_val);
                for As_val = unique(As)
                    mLPiPsAs = and(mLPiPs, As == As_val);
                    mLPiPsAs_j = find(mLPiPsAs); % logical to indices
                    if length(mLPiPsAs_j) > 1
                        BRDF(mLPiPsAs_j(1)) = mean(BRDF(mLPiPsAs));
                            % set first to average
                        mkeep(mLPiPsAs_j(2:end)) = false; % remove non-first
                    end
                end
            end
        end
    end
    Pi = Pi(mkeep); % keep only unique angles
    Ai = Ai(mkeep);
    Ps = Ps(mkeep);
    As = As(mkeep);
    BRDF = BRDF(mkeep);
    lambda = lambda(mkeep);

    if LAMBDA_IS_DUMMY
        lambda = [];
    end

end

