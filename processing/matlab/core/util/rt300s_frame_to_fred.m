
function [Pi, Ai, Ps, As] = rt300s_frame_to_fred(A, I, R, S)
    % Inputs and outputs are corresponding 1D vectors.
    % Converts RT-300S coordinates to FRED coordinates.
    % Pi == polar incident (\theta_i)
    % Ai == polar azimuth (\phi_i)
    % Ps == scatter incident (\theta_s)
    % As == scatter azimuth (\phi_s)

    Pi = I;
    Ai = -S;
    Ps = R;
    As = 90 + A - S;
    [Pi, Ai, Ps, As] = set_fred_domain(Pi, Ai, Ps, As);
    
end

