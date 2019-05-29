clear all
close all
clc

hdlsetuptoolpath('ToolName','Xilinx Vivado','ToolPath',...
'C:\Xilinx\Vivado\2018.3\bin\vivado.bat');

% addpath('Simulink Correlator Library');
sysName = 'untitled';
open_system(sysName);
h = load_system(sysName);

rng(40);
coeff = randi([0, 1], 3, 60)*2-1;

[A, I, seqDiff, flag] = filter_preprocessing(coeff);
numCoeff = length(A);

baseFilter = 1;

% coefficient sharing FIR
sys = [sysName '/Coeff Share'];
coefficientSharingFIR(sys, baseFilter, coeff, A, I, seqDiff)

% direct form FIR
sys = [sysName '/FIR'];
directFormFIR(sys, coeff)






% directFormFIRFilter(sysName, subsysName, baseFilter, set(1), coeff, A, I);



% set_param(demuxBlock{2}, 'Outputs', num2str(numCoeff));


% if isempty(subsystems) ~= 1
%     delete_block(subsystems);
% end






% coeff_orig = coeff;
% sharing_factor = 20;
% L = length(coeff);
% M = ceil(L/sharing_factor);
% delay = M + ceil(L/M) + 5;
% 
% 
% rate = 2;
% coeff_cell = cell(1, rate);
% cell_l = zeros(1, rate);
% for k=1:rate
%    coeff_cell{k} = coeff(k:rate:end);
%    cell_l(k) = length(coeff_cell{k});
% end
% 
% coeff = zeros(max(cell_l), rate);
% 
% for k=1:rate
%     coeff(1:cell_l(k), k) = coeff_cell{k};
% end
% 
% coeff_1 = coeff_cell{1};
% coeff_2 = coeff_cell{2};