
function [Pi, Ai, Ps, As, BRDF, lambda] = remove_fred_redundancy(Pi, Ai, Ps, As, BRDF, lambda)
    % If multiple Ps=0 entries exist per (Pi,Ai) block, keep only one 
    % (with As=0 by convention). Average-out and remove redundancy of any 
    % duplicated angles. All arguments are 1D vectors.

    LAMBDA_IS_DUMMY = false;
    if nargin < 6 % then 'lambda' was not input
        lambda = zeros(size(BRDF)); % dummy values
        LAMBDA_IS_DUMMY = true;
    end
    
    % Remove redundant Ps=0 entries per each (Pi,Ai) block (per lambda):
    mkeep = true(size(BRDF)); % initialize mask to keep
    for lambda_val = unique(lambda)
        mL = lambda == lambda_val;
        for Pi_val = unique(Pi)
            mLPi = and(mL, Pi == Pi_val);
            for Ai_val = unique(Ai(mLPi))
                mLPiAi = and(mLPi, Ai == Ai_val); % mask of (Pi,Ai) block
                m = and(mLPiAi, Ps == 0); % mask of Ps=0 in block
                if sum(m) > 1 % if more than one Ps=0 datapoint in block
                    mj = find(m); % switch logical to indices
                    BRDF(mj(1)) = mean(BRDF(m)); % set first entry to average
                    As(mj(1)) = 0; % by convention, set As=0 at Ps=0 entry
                    mkeep(mj(2:end)) = false; % define elements to remove
                end
            end
        end
    end
    if any(~mkeep) % if any elements are to be removed
        Pi = Pi(mkeep);
        Ai = Ai(mkeep);
        Ps = Ps(mkeep);
        As = As(mkeep);
        BRDF = BRDF(mkeep);
        lambda = lambda(mkeep);
    end

    % Check for any duplicated entries, then average-out and remove if so:
    mkeep = true(size(BRDF)); % mask of elements to keep
    for lambda_val = unique(lambda)
        mL = lambda == lambda_val;
        for Pi_val = unique(Pi)
            mLPi = and(mL, Pi == Pi_val);
            for Ai_val = unique(Ai)
                mLPiAi = and(mLPi, Ai == Ai_val);
                for Ps_val = unique(Ps)
                    mLPiAiPs = and(mLPiAi, Ps == Ps_val);
                    for As_val = unique(As)
                        mLPiAiPsAs = and(mLPiAiPs, As == As_val);
                        if sum(mLPiAiPsAs) > 1
                            mLPiAiPsAs_j = find(mLPiAiPsAs);
                            BRDF(mLPiAiPsAs_j(1)) = mean(BRDF(mLPiAiPsAs)); 
                                % set first entry to average
                            mkeep(mLPiAiPsAs_j(2:end)) = false; % remove others
                        end
                    end
                end
            end
        end
    end
    if any(~mkeep) % if any elements are to be removed
        Pi = Pi(mkeep);
        Ai = Ai(mkeep);
        Ps = Ps(mkeep);
        As = As(mkeep);
        BRDF = BRDF(mkeep);
        lambda = lambda(mkeep);
    end

    if LAMBDA_IS_DUMMY
        lambda = [];
    end

end

