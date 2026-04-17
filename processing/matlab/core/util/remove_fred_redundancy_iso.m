
function [Pi, Ai, Ps, As, BRDF] = remove_fred_redundancy_iso(Pi, Ai, Ps, As, BRDF)
    % For isotropic samples, only need one Ai angle and only need |As - Ai| 
    % \in [0, 180]. This function averages corresponding data (i.e., 
    % constant |As - Ai| values), and returns by convention Ai = 0 and 
    % As \in [0, 180].

    As = abs(mod(As - Ai + 180, 360) - 180); % |As-Ai| is what matters for 
        % isotropic, and with convention of Ai=0 then As=|As-Ai|; however 
        % need to wrap |As-Ai| into [-180,180) about Ai to get |As-Ai| 
        % angular separation rather than linear difference.
    Ai = zeros(size(Ai)); % replace all Ai with 0 (Ai=0 by convention)
    mkeep = true(size(BRDF)); % logical of unique angles to keep
    for Pi_val = unique(Pi)
        mPi = Pi == Pi_val;
        for Ps_val = unique(Ps)
            mPiPs = and(mPi, Ps == Ps_val);
            for As_val = unique(As)
                mPiPsAs = and(mPiPs, As == As_val);
                mPiPsAs_j = find(mPiPsAs); % logical to indices
                if length(mPiPsAs_j) > 1
                    BRDF(mPiPsAs_j(1)) = mean(BRDF(mPiPsAs));
                        % set first to average
                    mkeep(mPiPsAs_j(2:end)) = false; % remove non-first
                end
            end
        end
    end
    Pi = Pi(mkeep); % keep only unique angles
    Ai = Ai(mkeep);
    Ps = Ps(mkeep);
    As = As(mkeep);
    BRDF = BRDF(mkeep);

end

