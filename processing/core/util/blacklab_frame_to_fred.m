
function [Pi, Ai, Ps, As] = blacklab_frame_to_fred(src_z, src_a, view_z, view_a)
    % Inputs and outputs are corresponding 1D vectors.
    % Converts Blacklab coordinates to FRED coordinates.
    % Pi == polar incident (\theta_i)
    % Ai == polar azimuth (\phi_i)
    % Ps == scatter incident (\theta_s)
    % As == scatter azimuth (\phi_s)

    Pi = src_z;
    Ai = src_a + 180;
    Ps = view_z;
    As = view_a;
    [Pi, Ai, Ps, As] = set_fred_domain(Pi, Ai, Ps, As);
    
end

