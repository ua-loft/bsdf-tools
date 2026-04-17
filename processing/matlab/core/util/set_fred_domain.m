
function [Pi, Ai, Ps, As] = set_fred_domain(Pi, Ai, Ps, As)

    % Force Pi >= 0:
    mPi = Pi < 0;
    while any(mPi)
        Pi(mPi) = -Pi(mPi); % flip sign to make Pi > 0
        Ai(mPi) = Ai(mPi) + 180; % adjust azimuth to preserve angle
        mPi = Pi < 0;
    end

    % Force Pi <= 180:
    mPi = Pi > 180;
    while any(mPi)
        Pi(mPi) = 360 - Pi(mPi); % adjust domain, e.g., 184 becomes 176
        Ai(mPi) = Ai(mPi) + 180; % adjust azimuth to preserve angle
        mPi = Pi > 180;
    end

    % Force Ps >= 0:
    mPs = Ps < 0;
    Ps(mPs) = -Ps(mPs); % flip sign to make Ps > 0
    As(mPs) = As(mPs) + 180; % adjust azimuth to preserve angle

    % Force Ps <= 180:
    mPs = Ps > 180;
    while any(mPs)
        Ps(mPs) = 360 - Ps(mPs); % adjust domain, e.g., 184 becomes 176
        As(mPs) = As(mPs) + 180; % adjust azimuth to preserve angle
        mPs = Ps > 180;
    end

    % Force Ai \in [0, 360):
    mAi_lo = Ai < 0;
    while any(mAi_lo)
        Ai(mAi_lo) = Ai(mAi_lo) + 360; % add
        mAi_lo = Ai < 0;
    end
    mAi_hi = Ai >= 360;
    while any(mAi_hi)
        Ai(mAi_hi) = Ai(mAi_hi) - 360; % subtract
        mAi_hi = Ai >= 360;
    end

    % Force As \in [0, 360):
    mAs_lo = As < 0;
    while any(mAs_lo)
        As(mAs_lo) = As(mAs_lo) + 360; % add
        mAs_lo = As < 0;
    end
    mAs_hi = As >= 360;
    while any(mAs_hi)
        As(mAs_hi) = As(mAs_hi) - 360; % subtract
        mAs_hi = As >= 360;
    end

end

