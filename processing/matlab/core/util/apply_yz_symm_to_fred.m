
function [Pi, Ai, Ps, As, BRDF] = apply_yz_symm_to_fred(Pi, Ai, Ps, As, BRDF)
    % Assumes sample has YZ symmetry.
    % This is true for all isotropic samples, and for anisotropic samples
    % such as a lenslet array that is symmetric.
    % The symmetry yields: BRDF(Ai, As) = BRDF(180 - Ai, -As).

    Pi = [Pi, Pi];
    Ai = [Ai, 180 - Ai];
    Ps = [Ps, Ps];
    As = [As, -As];
    BRDF = [BRDF, BRDF];
    [Pi, Ai, Ps, As] = set_fred_domain(Pi, Ai, Ps, As); % ensure domain

end

