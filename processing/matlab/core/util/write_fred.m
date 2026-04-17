
function status = write_fred(Pi, Ai, Ps, As, BRDF, filepath)
    % Writes BRDF data to '.txt' file for use in FRED.
    % Include '.txt' in 'filepath' argument.
    % Writes all provided values, in boolean order of [Pi,Ai,Ps,As].

    status = false;

    % Open text file:
    fid = fopen(filepath, 'w');

    % Write header:
    fprintf(fid, 'type bsdf_data\n');
    fprintf(fid, 'format angles=deg bsdf=value scale=1\n');

    % Write data:
    for Pi_val = unique(Pi)
        mPi = Pi == Pi_val;
        for Ai_val = unique(Ai(mPi))
            mPiAi = and(mPi, Ai == Ai_val);
            header = sprintf('%i\t%i\n', Pi_val, Ai_val);
            block = ""; % initialize
            for Ps_val = unique(Ps(mPiAi))
                mPiAiPs = and(mPiAi, Ps == Ps_val);
                for As_val = unique(As(mPiAiPs))
                    mPiAiPsAs = and(mPiAiPs, As == As_val);
                    n = sum(mPiAiPsAs);
                    if n == 1
                        block = block ...
                                + sprintf('%i\t%i\t%.6f\n', ...
                                         Ps_val, As_val, BRDF(mPiAiPsAs)); 
                    elseif n > 1
                        error("Multiple entries for same angle. Process data prior to writing to file.")
                    end
                end
            end
            if ~isempty(block) % if any (Ps,As) values, then write
                fprintf(fid, '%s%s', header, block);
            end
        end
    end

    % Close text file and return status=true success:
    fclose(fid);
    status = true;

end

