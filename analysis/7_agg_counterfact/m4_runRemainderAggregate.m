%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  M4_RUNREMAINDERAGGREGATE.M, automatically calling
%  M5_PREPARE_DATA_Q.M
%  M6_VAR.M
%  M7_COUNTERFACTUAL.M
% 
%  These scripts take aggregate time series data, mostly from public
%  databases and partially computed from Statistics Denmark micro data
%  (PPI) and estimate a VAR to confirm that prices during the
%  Great Recession did not as fall as historical relationships would have
%  implied.
%
%  DEPENDENCIES:
%  
%  Inputs:
%   
%   - in/data_q_in.xlsx
%     Year Quarter USGDP USPPI USLOANS GDP PPImicro LOANS
%     see third worksheet for sources of time series
%
%   - var_tbx/
%     codes for VAR estimation extracted from macrometrics toolbox
%     www.gabrielzuellig.com > macrometrics
%
%  Outputs:
%   
%   - temp/data_q_ready.mat
%     USGDP USPPI USLOANS GDP PPImicro LOANS dPPImicro
%
%   - out/out_var.mat
%
%   - out/out_cf.mat
%
%   - Fig D.1a-b
%
%   - Tab D.1
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



clear all; clc;

addpath('./var_tbx') 


%% Preliminary data stuff
m5_prepare_data_q;


%% Settings for VAR
folder = 'out/';
p = 3;
h = 20;
c_case = 1;
vars = {'GDP','PPImicro'};
exvars = {};
n = length(vars);
ident = 'chol';
gdppos = 1;
shockpos = 1; % position of the shock in the Cholesky ordering
shocksize = 1; % 0 = one standard deviation, all else: absolute values
state.nonlinear = 'no';
nboot = 1000;
alpha = 10; %confidence level

samplemin = 1995;
samplemax = 2007.75;

%% Estimate 
m6_var;
% output: IRF => 1% increase in GDP typically leads to 
% 1% higher prices in the medium run

%% Counterfactual exercise
m7_counterfactual


%% FIGURES

% Figure D.1a
load('temp/data_q_ready.mat')
vars = {'GDP','PPImicro'};
data = NaN*ones(size(data_lib,1), length(vars));
for vv = 1:length(vars)
    col = find(strcmp(labels_lib, vars(vv)));
    data(:,vv) = data_lib(:, col);
end

data = data(time >= 1995.25 & time < 2016.5, :);
time = time(time >= 1995.25 & time < 2016.5);
refperiod = find(time == 2007.75);
data = (data - data(refperiod, :))/100;

figure() 
plot(time, data(:,1), 'LineWidth', 2, 'Color', rgb('navy'))
hold on
plot(time, data(:,2), ':', 'LineWidth', 2, 'Color', rgb('maroon'))
ylabel('log [2007q4 = 0]')
axis('tight')
ylim([-.4 .15])
legend('Real GDP','Chain-linked PPI','Location','SouthEast')
legend boxoff
box off
set(gca, 'YGrid', 'on', 'XGrid', 'off')
set(gca,'fontname','times')
set(gcf,'paperpositionmode','auto')
set(gcf, 'position', [0 0 350 200]);
print(gcf,'-dpng','-loose',strcat(folder,'FigD1a'));

% Figure D.1b
load(strcat(folder,'/out_cf.mat'))
res = res(time >= 2007 & time <= 2012, :);
time = time(time >= 2007 & time <= 2012);

figure()
plot(time, res(:,2), 'LineWidth', 2, 'Color', rgb('navy'))
hold on
plot(time, res(:,6), ':', 'LineWidth', 2, 'Color', rgb('maroon'))
plot(time, zeros(size(time)), 'Color', 'black')
ylabel('log PPI [2007q4 = 0]')
axis('tight')
ylim([-.06 .1])
yticks([-.06 -.04 -.02 0 .02 .04 .06 .08 .1])
xticks([2007:1:2011])
legend('Observed prices','Conditional forecast','Location','SouthWest')
legend boxoff
box off
set(gca, 'YGrid', 'on', 'XGrid', 'off')
set(gca,'fontname','times')
set(gcf,'paperpositionmode','auto')
set(gcf, 'position', [0 0 350 200]);
print(gcf,'-dpng','-loose',strcat(folder,'FigD1b'));

% year, actual, conditional forecast, missing disinflation
disp([time-2000, res(:,2), res(:,6), res(:,6) - res(:,2)])


%% TABLE ON UNCONDITIONAL US-DK comparison

load('temp/data_q_ready.mat')

vars = {'LOANS','GDP','PPImicro','USLOANS','USGDP','USPPI'};
data = NaN*ones(size(data_lib,1), length(vars));
for vv = 1:length(vars)
    col = find(strcmp(labels_lib, vars(vv)));
    data(:,vv) = data_lib(:, col);
end
data = data(time >= 1986 & time < 2019, :);
time = time(time >= 1986 & time < 2019);
growth = 4*(data(2:end,:) - data(1:end-1,:));
timegrowth = time(2:end,:);

out = NaN*ones(14, 6);
% growth rates in 2005
out(2,:) = nanmean(growth(floor(timegrowth) == 2005,:), 1);
% growth rates in 2006
out(3,:) = nanmean(growth(floor(timegrowth) == 2006,:), 1);
% growth rates in 2007
out(4,:) = nanmean(growth(floor(timegrowth) == 2007,:), 1);
% grwth rates in 2008
out(5,:) = nanmean(growth(floor(timegrowth) == 2008,:), 1);
% growth rates in 2009
out(6,:) = nanmean(growth(floor(timegrowth) == 2009,:), 1);
% growth rates in 2010
out(7,:) = nanmean(growth(floor(timegrowth) == 2010,:), 1);
% growth rates in 2011
out(8,:) = nanmean(growth(floor(timegrowth) == 2011,:), 1);
% growth rates in 2012
out(9,:) = nanmean(growth(floor(timegrowth) == 2012,:), 1);
% for the following, only take sample period during which data for both
% countries is available
for ii=1:3
    tempgrowth = growth(logical(sum(isnan(growth(:,[ii ii+3])), 2) == 0), [ii ii+3]);
    % average growth
    out(1, [ii ii+3]) = mean(tempgrowth, 1);
    % standard deviation
    out(10, [ii ii+3]) = std(tempgrowth, 1);
    % persistence
    out(11, ii) = tempgrowth(1:end-1,1) \ tempgrowth(2:end,1);
    out(11, ii+3) = tempgrowth(1:end-1,2) \ tempgrowth(2:end,2);
end
out(12:14, 1:3) = corr(growth(:, 1:3), 'rows', 'pairwise');
out(12:14, 4:6) = corr(growth(:, 4:6));

T = array2table(out, 'VariableNames', vars);
T.Properties.RowNames = {'mean';'05';'06';'07';'08';'09';'10';'11';'12';'sd';'autocorr';'corr w GDP';'corr w PPI';'corr w loans'}
writetable(T, 'out/TabD1_timeseries_comparison.txt')

close all
