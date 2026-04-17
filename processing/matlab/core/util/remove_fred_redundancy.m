
function [Pi, Ai, Ps, As, BRDF] = remove_fred_redundancy(Pi, Ai, Ps, As, BRDF)
    % If multiple Ps=0 entries exist per (Pi,Ai) block, keep only one 
    % (with As=0 by convention). Average-out and remove redundancy of any 
    % duplicated angles. All arguments are 1D vectors.
    
    % Remove redundant Ps=0 entries per each (Pi,Ai) block:
    mkeep = true(size(BRDF)); % initialize mask to keep
    for Pi_val = unique(Pi)
        mPi = Pi == Pi_val;
        for Ai_val = unique(Ai(mPi))
            mPiAi = and(mPi, Ai == Ai_val); % mask of (Pi,Ai) block
            m = and(mPiAi, Ps == 0); % mask of Ps=0 in block
            if sum(m) > 1 % if more than one Ps=0 datapoint in block
                mj = find(m); % switch logical to indices
                BRDF(mj(1)) = mean(BRDF(m)); % set first entry to average
                As(mj(1)) = 0; % by convention, set As=0 at Ps=0 entry
                mkeep(mj(2:end)) = false; % define elements to remove
            end
        end
    end
    if any(~mkeep) % if any elements are to be removed
        Pi = Pi(mkeep);
        Ai = Ai(mkeep);
        Ps = Ps(mkeep);
        As = As(mkeep);
        BRDF = BRDF(mkeep);
    end

    % Check for any duplicated entries, then average-out and remove if so:
    mkeep = true(size(BRDF)); % mask of elements to keep
    for Pi_val = unique(Pi)
        mPi = Pi == Pi_val;
        for Ai_val = unique(Ai)
            mPiAi = and(mPi, Ai == Ai_val);
            for Ps_val = unique(Ps)
                mPiAiPs = and(mPiAi, Ps == Ps_val);
                for As_val = unique(As)
                    mPiAiPsAs = and(mPiAiPs, As == As_val);
                    if sum(mPiAiPsAs) > 1
                        mPiAiPsAs_j = find(mPiAiPsAs);
                        BRDF(mPiAiPsAs_j(1)) = mean(BRDF(mPiAiPsAs)); 
                            % set first entry to average
                        mkeep(mPiAiPsAs_j(2:end)) = false; % remove others
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
    end

end

