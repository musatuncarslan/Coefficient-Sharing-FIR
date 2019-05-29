function tappedDelayBlock = tappedDelayLine(sys, numCoeff)

    blocks = find_system(sys, 'SearchDepth', '1');
    inBlock = blocks(2);
    input_pos = get_param(inBlock{1}, 'Position');
    % setup tapped delay line.
    add_block('hdlsllib/Discrete/Tapped Delay', [sys '/Tapped Delay Line'], 'Position', input_pos + [80, -10, 90, 10]);
    tappedDelayBlock{1} =  'Tapped Delay Line';
    set_param([sys '/' tappedDelayBlock{1}], 'NumDelays', num2str(numCoeff), 'DelayOrder', 'Newest');
   
end