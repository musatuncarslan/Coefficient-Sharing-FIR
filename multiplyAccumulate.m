function multiplyAccumulate(sys, baseFilter, setIdx, coeff, A, I)

    numCoeff = length(A);
    subFilterTap = I(A == setIdx);
    subFilterCoeff = coeff(baseFilter, subFilterTap);
    subFilterTap = subFilterTap;
    uniqueCoeff = unique(subFilterCoeff);

    numSubFilterCoeff = length(subFilterCoeff);

    lines = find_system(sys,'FindAll','on', 'SearchDepth', '1', 'type','line');
    blocks = find_system(sys, 'SearchDepth', '1');
    inBlock = blocks(2); set_param(inBlock{1}, 'Name', 'x'); % get input block and rename it
    inBlock{1} = strrep(inBlock{1},'In1','x');
    outBlock = blocks(end); set_param(outBlock{1}, 'Name', 'y'); % get output block and rename it
    outBlock{1} = strrep(outBlock{1},'Out1','y');

    blocks = blocks(3:end-1); % exclude the system itself, input (2nd entry) and output (last entry)
    delete_block(blocks) % delete all blocks
    delete_line(lines) % delete all lines

    set_param(inBlock{1}, 'Position', [0, -7, 30, 7]);
    tappedDelay_pos = get_param(inBlock{1}, 'Position');
    
    % subsystems = find_system([system '/' subsystem],'BlockType', 'SubSystem')
    pos = get_param(inBlock{1}, 'Position');

    % add multiply and add blocks
    multiplyAddBlock = cell(1, numSubFilterCoeff);
    fromBlock = cell(1, numSubFilterCoeff);
    for k=1:numSubFilterCoeff
        % add and position multiply-add blocks
        add_block('filter_library/Multiply-Add', [sys '/Multiply-Add ' num2str(k)], 'Position', [pos(3)+60 -23 pos(3)+120 23]+[0, 100, 0, 100]);
        multiplyAddBlock{k} = ['Multiply-Add ' num2str(k)];

        % add and position coefficient blocks
        pos = [pos(3)+60 -23 pos(3)+120 23];
        idx = find(uniqueCoeff == subFilterCoeff(k));
        add_block('hdlsllib/Signal Routing/From', [sys '/from_c' num2str(k)], 'Position', [pos(1)-35, -5, pos(1)-5, 5] + [0, 100, 0, 100], ...
            'GotoTag', ['c' num2str(idx)], 'ShowName' , 'off'); 
        fromBlock{k} = ['from_c' num2str(k)];

        pos = get_param([sys, '/', multiplyAddBlock{k}], 'Position');

        % connect coefficients with multiply-add blocks
        add_line(sys,[fromBlock{k} '/1'], [multiplyAddBlock{k}, '/2'],'autorouting','on'); 
    end

    for k=1:numSubFilterCoeff
       if k < numSubFilterCoeff
            % connect multiply-add blocks to eachother
            add_line(sys,[multiplyAddBlock{k} '/1'], [multiplyAddBlock{k+1}, '/3'],'autorouting','on');
        else
            % connect last multiply-add block to output
            add_line(sys,[multiplyAddBlock{k} '/1'], 'y/1','autorouting','on');
        end

    end


    % setup tapped delay line demux
    pos_1 = get_param([sys, '/', multiplyAddBlock{1}], 'Position');
    pos_2 = get_param([sys, '/', multiplyAddBlock{end}], 'Position');
    add_block('hdlsllib/Signal Routing/Demux', [sys '/Input Demux'], 'Orientation', 'Down', 'Position', [pos_1(1), 30, pos_2(3), 35]);
    demuxBlock{1} = 'Input Demux';
    set_param([sys, '/', demuxBlock{1}], 'Outputs', num2str(numCoeff));

    % connect input and tapped delay line
    add_line(sys,'x/1', [demuxBlock{1} '/1'],'autorouting','on');

    for k=1:numSubFilterCoeff
        % connect demux with multiply-add blocks
        add_line(sys, [demuxBlock{1} '/' num2str(subFilterTap(k))], [multiplyAddBlock{k}, '/1'],'autorouting','on'); 
    end

    % add coefficient block
    coeffBlock = cell(1, length(uniqueCoeff));
    gotoBlock = cell(1, length(uniqueCoeff));
    pos = [tappedDelay_pos(1), pos_1(4)+30, tappedDelay_pos(1)+30, pos_1(4)+60];
    for k=1:length(uniqueCoeff)
        add_block('hdlsllib/Commonly Used Blocks/Constant', [sys '/c' num2str(k)], 'Position', pos, 'Value', num2str(uniqueCoeff(k)));
        add_block('hdlsllib/Signal Routing/Goto', [sys '/goto_c' num2str(k)], 'Position', pos + [50, 0, 50, 0], 'GotoTag', ['c' num2str(k)]);
        coeffBlock{k} = ['c' num2str(k)];
        gotoBlock{k} = ['goto_c' num2str(k)];
        pos = pos + [0, 60, 0, 60];

        set_param([sys, '/', coeffBlock{k}], 'OutDataTypeStr', 'fixdt(1, 12, 7)', 'SampleTime', '1');

        % connect coefficients with goto blocks
        add_line(sys, [coeffBlock{k} '/1'], [gotoBlock{k}, '/1'],'autorouting','on');
    end

    % add zero coefficient for the first multiply-add block and connect it
    initCoeff{1} = 'c0';
    pos = get_param([sys, '/', coeffBlock{1}], 'Position');
    add_block('hdlsllib/Commonly Used Blocks/Constant', [sys '/c0'], 'Position', pos + [0, -55, 0, -55], 'Value', num2str(0));
    set_param([sys, '/', initCoeff{1}], 'OutDataTypeStr', 'fixdt(1, 12, 7)', 'SampleTime', '1');
    add_line(sys, [initCoeff{1} '/1'], [multiplyAddBlock{1}, '/3'],'autorouting','on');


    pos = get_param([sys, '/', multiplyAddBlock{end}], 'Position');
    set_param(outBlock{1}, 'Position', [pos(3)+60, -5, pos(3)+90, 5] + [0, 100, 0, 100]);
    addterms(sys);
end
