
function [Pi, Ai, Ps, As, BRDF, lambda] = apply_xz_symm_to_fred(Pi, Ai, Ps, As, BRDF, lambda)
    % Assumes sample has XZ symmetry.
    % This is true for all isotropic samples, and for anisotropic samples
    % such as a lenslet array that is symmetric.
    % The symmetry yields: BRDF(Ai, As) = BRDF(-Ai, -As).

    Pi = [Pi, Pi];
    Ai = [Ai, -Ai];
    Ps = [Ps, Ps];
    As = [As, -As];
    BRDF = [BRDF, BRDF];
    if ~isempty(lambda)
        lambda = [lambda, lambda];
    end
    [Pi, Ai, Ps, As] = set_fred_domain(Pi, Ai, Ps, As); % ensure domain

end

