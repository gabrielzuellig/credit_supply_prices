
%% Import
xlsdata = readtable('in/data_q_in.xlsx', 'ReadRowNames', 0);
data = xlsdata{:,:};
labels = xlsdata.Properties.VariableNames;


%% Timing and labelling
time = data(:,1)+(1/4)*(data(:,2)-1);
data = data(:,3:end);
labels = labels(1,3:end);

labelmat = readtable('in/data_q_in.xlsx','Sheet','labels','ReadVariableNames',0);
labels_print = labels;
for vv = 1:length(labels_print)
    col = find(strcmp(labelmat{:,1}, labels(vv)));
    if ~isempty(col)
        labels_print(vv) = labelmat{col,2};
    end
end
clear xlsdata labelmat


%% Data treatment

% 100*log of variables in levels (replace series)
var = {'USGDP','USPPI','USLOANS',...
    'GDP','PPImicro','LOANS'};
for vv = 1:length(var)
    col = find(strcmp(labels, var{vv}));
    if ~isempty(col)
        data(:, col) = 100*log(data(:, col));
    end
end

% first (log) difference
var = {'PPImicro','PPIDSTmanudom'};
for vv = 1:length(var)
    col = find(strcmp(labels, var{vv}));
    if ~isempty(col)
        data(:, end+1) = NaN;
        data(2:end, end) = data(2:end, col) - data(1:end-1, col);
        labels{length(labels) + 1} = strcat('d',var{vv});
        labels_print{length(labels_print) + 1} = strcat(labels_print{find(strcmp(labels, var{vv}))},' growth');
    end
end


%% Plot descriptive time series
xt00 = find(time==2000);
xt = [flip(xt00:-20:1) (xt00+20):20:size(data,1)];

for vv = 1:size(data,2)
    figure()
    plot(1:size(data,1), data(:,vv),'k','LineWidth',2)
    axis('tight')
    grid on
    set(gca, 'XTick',xt, 'XTickLabel',(xt-xt00)/4 + 2000)
    title(labels_print{vv})
    set(gca,'FontSize',12)
    set(gcf,'paperpositionmode','auto')
end

close all

%% Export, housekeeping
data_lib = data;
labels_lib = labels;
printlabels_lib = labels_print;
clear col col2 vv var data labels labels_print labelmat xt xt00
save(strcat('temp/data_q_ready.mat'), 'data_lib', 'labels_lib', 'printlabels_lib','time')

