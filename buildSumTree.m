function buildSumTree(sys, S, coeff)
    M = size(coeff, 2);    
    S = S + 1;
    block_coeff = coeff(1, S);
    depth = nextpow2(length(S));
    

    lines = find_system(sys,'SearchDepth',1,'FollowLinks','on','LookUnderMasks','all','FindAll','on','type','line');
    delete_line(lines);

    add_block('hdlsllib/Signal Routing/Demux', [sys '/Demux'], 'Orientation', 'Up');
    
    inport = find_system(sys,'SearchDepth',1, 'FollowLinks','on','LookUnderMasks','all','BlockType','Inport');
    outport = find_system(sys,'SearchDepth',1, 'FollowLinks','on','LookUnderMasks','all','BlockType','Outport');
    demux = find_system(sys,'SearchDepth',1, 'FollowLinks','on','LookUnderMasks','all','BlockType','Demux');
    addDelay = find_system(sys,'SearchDepth', 1, 'FollowLinks','on','LookUnderMasks','all');
    delete_block(addDelay(4:end-1))
    
    set_param(inport{1}, 'Name', 'data_in');
    set_param(outport{1}, 'Name', 'data_out');
    inport = find_system(sys,'SearchDepth',1, 'FollowLinks','on','LookUnderMasks','all','BlockType','Inport');
    outport = find_system(sys,'SearchDepth',1, 'FollowLinks','on','LookUnderMasks','all','BlockType','Outport');

    % position demux block
    inportPos = get_param(inport{1}, 'Position');
    demuxPosition = get_param(demux{1}, 'Position');
    w = abs(demuxPosition(1) - demuxPosition(3));
    h = abs(demuxPosition(2) - demuxPosition(4));
    set_param(demux{1}, 'Position', [inportPos(3)+20, inportPos(2)-h-20, inportPos(3)+w+20, inportPos(2)-20]);
    demuxPosition = get_param(demux{1}, 'Position');


    set_param(demux{1}, 'Outputs', num2str(M)); 
    quotient = length(S);
    if 2^nextpow2(length(S)) == length(S)
        quotient_vec = zeros(1, nextpow2(length(S)));
        remainder_vec = zeros(1, nextpow2(length(S)));
    else
        quotient_vec = zeros(1, nextpow2(length(S))-1);
        remainder_vec = zeros(1, nextpow2(length(S))-1);
    end

    k = 1;
    if quotient ~= 0
        while (quotient ~= 1)
            remainder = mod(quotient, 2);
            quotient = floor((quotient++remainder)/2);
            remainder_vec(k) = remainder;
            quotient_vec(k) = quotient;
            k = k+1;
        end
    end
    % add blocks to the system
    addDelayBlock = cell(k-1, quotient_vec(1));
    x = 50; os = 0;
    for k=1:length(quotient_vec)
        if remainder_vec(k) ~= 0
            for l=1:(quotient_vec(k)-remainder_vec(k))
                add_block('filter_library/Add and Delay',[sys, '/add_delay' num2str(k) '_' num2str(l)], 'Orientation', 'Up', ...
                    'Position', [demuxPosition(1), demuxPosition(2)-70, demuxPosition(1)+20, demuxPosition(2)-30]+ ...
                                    [x*(l-1), -60*(k-1), x*(l-1), -60*(k-1)] + [os/2, 0, os/2, 0]);          
                addDelayBlock{k, l} = ['add_delay' num2str(k) '_' num2str(l)];
            end
            l = l+1;
            add_block('simulink/Commonly Used Blocks/Delay',[sys, '/add_delay' num2str(k) '_' num2str(l)], 'Orientation', 'Up', ...
                'Position', [demuxPosition(1), demuxPosition(2)-70, demuxPosition(1)+20, demuxPosition(2)-30]+ ...
                                [x*(l-1), -60*(k-1), x*(l-1), -60*(k-1)] + [os/2, 0, os/2, 0]);  
            addDelayBlock{k, l} = ['add_delay' num2str(k) '_' num2str(l)];
        else
            for l=1:quotient_vec(k)
                add_block('filter_library/Add and Delay',[sys, '/add_delay' num2str(k) '_' num2str(l)], 'Orientation', 'Up', ...
                    'Position', [demuxPosition(1), demuxPosition(2)-70, demuxPosition(1)+20, demuxPosition(2)-30]+ ...
                                    [x*(l-1), -60*(k-1), x*(l-1), -60*(k-1)] + [os/2, 0, os/2, 0]);
                addDelayBlock{k, l} = ['add_delay' num2str(k) '_' num2str(l)];
            end        
        end
        x = x/(2^(k-1));
        os = x*(2^k-1);
        x = x*2^k;
    end

    addDelayPos = get_param([sys, '/', addDelayBlock{1, end}], 'Position');
    set_param(demux{1}, 'Position', [inportPos(3)+20, inportPos(2)-h-20, addDelayPos(3)+20, inportPos(2)-20]);

    % position output port
    delayAddPos = get_param([sys, '/', addDelayBlock{end, 1}], 'Position');
    outportPos = get_param(outport{1}, 'Position');
    w = abs(outportPos(1) - outportPos(3));
    h = abs(outportPos(2) - outportPos(4));
    set_param(outport{1}, 'Position', [delayAddPos(3)+20, delayAddPos(2)-h-20, delayAddPos(3)+w+20, delayAddPos(2)-20]);

    % connect the tree
    for k=1:size(addDelayBlock, 1)-1
        if remainder_vec(k+1) == 1
            % handle rows with odd number of elements
            for l=1:(quotient_vec(k)-1)/2
                out1 = [addDelayBlock{k, 2*(l-1)+1} '/1'];
                out2 = [addDelayBlock{k, 2*(l-1)+2} '/1'];
                in1 = [addDelayBlock{k+1, l} '/1'];
                in2 = [addDelayBlock{k+1, l} '/2'];
                add_line(sys, out1,in1,'autorouting','on');
                add_line(sys, out2,in2,'autorouting','on');
            end
            % handling the odd block (delay block)
            out1 = [addDelayBlock{k, quotient_vec(k)} '/1'];
            in1 = [addDelayBlock{k+1, quotient_vec(k+1)} '/1'];
            add_line(sys, out1,in1,'autorouting','on');
        else
            % handle rows with even number of elements
            for l=1:(quotient_vec(k))/2
                out1 = [addDelayBlock{k, 2*(l-1)+1} '/1'];
                out2 = [addDelayBlock{k, 2*(l-1)+2} '/1'];
                in1 = [addDelayBlock{k+1, l} '/1'];
                in2 = [addDelayBlock{k+1, l} '/2'];
                add_line(sys, out1,in1,'autorouting','on');
                add_line(sys, out2,in2,'autorouting','on');
            end        
        end
    end

    % connect the demux
    if mod(length(S), 2) == 1
        % handle rows with odd number of elements
        for l=1:(length(S)-1)/2
            out1 = ['Demux/' num2str(S(2*(l-1)+1))];
            out2 = ['Demux/' num2str(S(2*(l-1)+2))];
            in1 = [addDelayBlock{1, l} '/1'];
            in2 = [addDelayBlock{1, l} '/2'];
            add_line(sys, out1,in1,'autorouting','on');
            add_line(sys, out2,in2,'autorouting','on');
        end
        % handling the odd block (delay block)
        out1 = ['Demux/' num2str(S(end))];
        in1 = [addDelayBlock{1, quotient_vec(1)} '/1'];
        add_line(sys, out1,in1,'autorouting','on');
    else
        % handle rows with even number of elements
        for l=1:length(S)/2
            out1 = ['Demux/' num2str(S(2*(l-1)+1))];
            out2 = ['Demux/' num2str(S(2*(l-1)+2))];
            in1 = [addDelayBlock{1, l} '/1'];
            in2 = [addDelayBlock{1, l} '/2'];
            add_line(sys, out1,in1,'autorouting','on');
            add_line(sys, out2,in2,'autorouting','on');
        end        
    end

    % connect output port
    out1 = [addDelayBlock{end, 1}, '/1'];
    in1 = 'data_out/1';
    add_line(sys, out1,in1,'autorouting','on');

    % connect input port
    out1 = 'data_in/1';
    in1 = 'Demux/1';
    add_line(sys, out1,in1,'autorouting','on');

    addterms(sys);
%     termS = 1:M;
%     termS = setdiff(termS, S);
%     demuxPortConnectivity = get_param([sys, '/Demux'], 'PortConnectivity');
%     add_block('hdlsllib/Sinks/Terminator', [sys, '/Term']);
%     term = find_system(sys,'SearchDepth',1, 'FollowLinks','on','LookUnderMasks','all','BlockType','Terminator');
%     termPos = get_param(term{1}, 'Position');
%     w = abs(termPos(1) - termPos(3));
%     h = abs(termPos(2) - termPos(4));
%     delete_block(term);
%     for k=1:length(termS)
%         termPos = demuxPortConnectivity(termS(k)+1).Position;
%         add_block('hdlsllib/Sinks/Terminator', [sys, '/Term_' num2str(termS(k))], 'Orientation', 'Up', ...
%             'Position', [termPos(1)-w/2, termPos(2)-h+5, termPos(1)+w/2, termPos(2)+5]);
%         out1 = ['Demux/' num2str(termS(k))];
%         in1 = ['Term_' num2str(termS(k)) '/1'];
%         add_line(sys, out1,in1,'autorouting','on');
%     end

    setSigns(sys, S, block_coeff, addDelayBlock, quotient_vec, remainder_vec);
end