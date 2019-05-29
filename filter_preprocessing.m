function [A, I, seqDiff, flag] = filter_preprocessing(coeff)
    
    flag = 0;
    coeff(coeff == -1) = 0;

    numCoeff = size(coeff, 2);
    numFilters = size(coeff, 1);
    
    frameSeq = nan(numCoeff, 1);
    for k=1:numCoeff
        frameSeq(k, 1) = bi2de(transpose(coeff(:, k)), 'left-msb');
    end

    possibleSeq = zeros(numFilters, 2^numFilters); 
    for k=0:2^numFilters-1
        possibleSeq(:, k+1) = de2bi(k, numFilters, 'left-msb');
    end

    seqDiff = zeros(numFilters, 2^numFilters);
    for k=1:numFilters
        seqDiff(k, :) = possibleSeq(1, :) - possibleSeq(k, :);
    end
    seqDiff(seqDiff~=0) = -1;
    seqDiff(seqDiff==0) = 1;

    [A, I] = sort(frameSeq);
    for k=1:2^numFilters
        fprintf('Number of %i s: %i', k-1, length(find(A == k-1)));
        if (length(find(A == k-1)) == 1) || (length(find(A == k-1)) == 0)
            fprintf(' -- having too many empty or impulsive groups is inefficient, regroup filters by hand using smaller K, M/2^K_g <= 1\n');
            flag = 1;
            return;
        else
            fprintf('\n')
        end
    end
    fprintf('Done\n------------------------------------\n')

end