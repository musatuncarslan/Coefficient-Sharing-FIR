function coefficientSharingFIR(sys, baseFilter, coeff, A, I, seqDiff)

    set = unique(A);
    noFilters = nextpow2(numel(set));
    numCoeff = length(coeff(1, :));
    
    lines = find_system(sys,'FindAll','on', 'SearchDepth', '1', 'type','line');
    blocks = find_system(sys, 'SearchDepth', '1');
    blockType = get_param(blocks, 'BlockType');
    
    outBlock = cell(0,0);
    k = 1;
    for i = 1:length(blocks)
        if ( strcmp(blockType{i}, 'Outport'))
            outBlock{k} = blocks{i};
            k = k + 1;
        end
    end

    inBlock = blocks(2); set_param(inBlock{1}, 'Name', 'x'); % get input block and rename it
    if numel(outBlock) < noFilters
        for k=numel(outBlock):noFilters-1
            add_block('hdlsllib/Commonly Used Blocks/Out1', [sys, '/y' num2str(k)]);
            outBlock{k+1} = [sys, '/y' num2str(k)];
        end
        for k=0:numel(outBlock)-1
            set_param(outBlock{k+1}, 'Name', ['y' num2str(k)]);
        end
    elseif numel(outBlock) > noFilters
        delete_block(outBlock(noFilters+1:end));
    elseif numel(outBlock) == 1
        set_param(outBlock{1}, 'Name', 'y0');
    end

    blocks = find_system(sys, 'SearchDepth', '1');
    blocks = blocks(3:end-noFilters); % exclude the system itself, input (2nd entry) and output (last entry)
    delete_block(blocks) % delete all blocks
    delete_line(lines) % delete all lines

    inBlock{1} = 'x';
    set_param([sys '/' inBlock{1}], 'Position', [0, -7, 30, 7]);

    % setup tapped delay line
    tappedDelayBlock = tappedDelayLine(sys, numCoeff); 
    add_line(sys, [inBlock{1} '/1'], [tappedDelayBlock{1}, '/1'],'autorouting','on');

    tappedDelayPos = get_param([sys '/' tappedDelayBlock{1}], 'Position');
    mulAccBlocks = cell(1, length(set));
    for k=1:length(set)
        tic
        add_block('hdlsllib/Ports & Subsystems/Subsystem', [sys '/Multiply-Accumulate ' num2str(set(k))], ...
            'Position', [tappedDelayPos(3)+60 -23 tappedDelayPos(3)+120 23]+[30, 0, 30, 0]+[0, 60, 0, 60]*(k-1));
        mulAccBlocks{k} = ['Multiply-Accumulate ' num2str(set(k))];
        multiplyAccumulate([sys '/' mulAccBlocks{k}], baseFilter, set(k), coeff, A, I);
        add_line(sys, [tappedDelayBlock{1} '/1'], [mulAccBlocks{k}, '/1'],'autorouting','on');
        toc
    end

    mulAccBlocksPos_1 = get_param([sys, '/', mulAccBlocks{1}], 'Position');
    mulAccBlocksPos_2 = get_param([sys, '/', mulAccBlocks{end}], 'Position');
    add_block('hdlsllib/Signal Routing/Mux', [sys '/Mux'], ...
        'Position', [mulAccBlocksPos_1(3)+30, mulAccBlocksPos_1(2)-6, mulAccBlocksPos_1(3)+35, mulAccBlocksPos_2(end)+6], ...
        'Inputs', num2str(length(set)));
    muxBlock{1} = 'Mux';
    for k=1:length(set)
        add_line(sys, [mulAccBlocks{k}, '/1'], [muxBlock{1}, '/' num2str(k)],'autorouting','on');
    end
    
    
    filterBlocks = cell(1, noFilters);
    for k=1:noFilters
        tic
        add_block('hdlsllib/Ports & Subsystems/Subsystem', [sys '/Filter ' num2str(set(k))], ...
            'Position', [mulAccBlocksPos_1(3)+60 -23 mulAccBlocksPos_1(3)+150 23]+[30, 0, 30, 0]+[0, 60, 0, 60]*(k-1));
        filterBlocks{k} = ['Filter ' num2str(set(k))];
        buildSumTree([sys '/' filterBlocks{k}], 0:numel(set)-1, seqDiff(k, :));

        
        set_param(outBlock{k}, 'Position', [mulAccBlocksPos_1(3)+150 -7 mulAccBlocksPos_1(3)+180 7]+[40, 0, 40, 0]+[0, 60, 0, 60]*(k-1))
        
        add_line(sys, [muxBlock{1} '/1'], [filterBlocks{k}, '/1'],'autorouting','on');
        add_line(sys, [filterBlocks{k} '/1'], ['y' num2str(k-1), '/1'],'autorouting','on');
        toc
    end    
    

    
end
