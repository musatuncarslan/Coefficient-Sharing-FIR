function setSigns(gcb, S, block_coeff, addDelayBlock, quotient_vec, remainder_vec)

    sign_vec = blanks(length(S));
    for k=1:length(S)
        if block_coeff(k) == 1
            sign_vec(k) = '+';
        else
            sign_vec(k) = '-';
        end
    end
    idx = find(remainder_vec == 0);
    if mod(length(S), 2) == 1
        for k = 1:floor(length(S)/2)
            set_param([gcb, '/', addDelayBlock{1, k}], 'Inputs', sign_vec(2*(k-1)+1:2*k));
        end
        set_param([gcb, '/', addDelayBlock{idx(1), quotient_vec(idx(1))}], 'Inputs', ['+' sign_vec(end)]);
    else
        for k = 1:floor(length(S)/2)
            set_param([gcb, '/', addDelayBlock{1, k}], 'Inputs', sign_vec(2*(k-1)+1:2*k));
        end
    end
end