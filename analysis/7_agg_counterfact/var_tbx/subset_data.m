
% select T x N matrix of endogenous variables
data = NaN*ones(size(data_lib,1), n);
printvars = {};
for vv = 1:length(vars)
    col = find(strcmp(labels_lib, vars(vv)));
    data(:,vv) = data_lib(:, col);
    printvars = [printvars, printlabels_lib(col)];
end

% select T x N matrix of exogenous variables
exdata = NaN*ones(size(data_lib,1), length(exvars));
if ~isempty(exvars)
    for vv = 1:length(exvars)
        col = find(strcmp(labels_lib, exvars(vv)));
        exdata(:,vv) = data_lib(:, col);
    end
end

% select instrument (if necessary)
z = [];
if strcmp(ident, 'proxy')
    for vv = 1:length(proxyvar)
        col = find(strcmp(labels_lib, proxyvar(vv)));
        z = [z, data_lib(:, col)];
    end
end

% select state (if necessary)
s = [];
if strcmp(state.nonlinear, 'yes') && strcmp(state.logistic, 'yes')
    col = find(strcmp(labels_lib, state.statevar));
    s = data_lib(:, col);
end


% select interaction (if necessary)
if strcmp(state.nonlinear, 'yes') && strcmp(state.interacted, 'yes')
    exdata = NaN*ones(size(data_lib,1), 1);
    col1 = find(strcmp(labels_lib, state.shockvar));
    col2 = find(strcmp(labels_lib, state.statevar));
    exdata = data_lib(:, col1) .* data_lib(:, col2);
    state.shockpos = find(strcmp(state.shockvar, vars));
    state.statepos = find(strcmp(state.statevar, vars));
end


% ignore non-NA columns
nona = logical(sum(isnan([data, exdata]),2) == 0);
data = data(nona, :);
exdata = exdata(nona, :);
time = time(nona, :);
if strcmp(ident, 'proxy')
    z = z(nona, :);
end
if strcmp(state.nonlinear, 'yes') && strcmp(state.logistic, 'yes')
    s = s(nona, :);
end

% save unrestricted data sample
savedata.data = data;
savedata.exdata = exdata;
savedata.time = time;
if strcmp(ident, 'proxy')
    savedata.z = z;
end
if strcmp(state.nonlinear, 'yes') && strcmp(state.logistic, 'yes')
    savedata.s = s;
end

% ignore data before 1983
data = data(time >= samplemin, :);
exdata = exdata(time >= samplemin, :);
time = time(time >= samplemin, :);
if strcmp(ident, 'proxy')
    z = z(time >= samplemin, :);
end
if strcmp(state.nonlinear, 'yes') && strcmp(state.logistic, 'yes')
    s = s(time >= samplemin, :);
end

% ignore data after 2008
data = data(time <= samplemax, :);
exdata = exdata(time <= samplemax, :);
time = time(time <= samplemax);
if strcmp(ident, 'proxy')
    z = z(time <= samplemax, :);
end
if strcmp(state.nonlinear, 'yes') && strcmp(state.logistic, 'yes')
    s = s(time <= samplemax, :);
end

% Logistic transformation of s-variable
if strcmp(state.nonlinear, 'yes') && strcmp(state.logistic, 'yes')
    state.s = (s - prctile(s, state.cq)) / std(s(~isnan(s)));
    state.Fs = exp(-state.gamma*state.s)./(1+exp(-state.gamma*state.s));
end

% dummy of state
if strcmp(state.nonlinear, 'yes') && strcmp(state.interacted, 'yes')
    state.absval = prctile(data(:,state.statepos), state.cq);
    state.s = logical(data(:,state.statepos) <= state.absval);
end


% generate plot of actual data that goes into model
xt00 = find(time==2000);
xt = [flip(xt00:-20:1) (xt00+20):20:size(data,1)];
nrow = ceil(size(data,2)/3);

figure()
for vv = 1:size(data,2)
    subplot(nrow, 3, vv)
    plot(1:size(data,1), data(:,vv),'k','LineWidth',2)
    axis('tight')
    grid on
    hold on
    plot(1:size(data,1), zeros(size(data,1),1), 'k')
    set(gca, 'XTick',xt, 'XTickLabel',(xt-xt00)/4 + 2000)
    set(gca,'FontSize',10)
    title(printvars(vv),'FontSize',14)
end
set(gcf,'paperpositionmode','auto')
set(gcf, 'position', [0 0 800 nrow*200]);

if strcmp(state.nonlinear, 'yes')
    figure()
    if strcmp(state.logistic, 'yes')
        subplot(2, 1, 1)
        plot(1:size(data,1), state.s, 'k', 'LineWidth', 2)
        if min(state.s(~isnan(state.s))) < 0 && max(state.s(~isnan(state.s))) > 0
            hold on
            plot(1:size(data,1), zeros(size(data,1),1), 'k', 'LineWidth', .5)
        end
        axis('tight')
        grid on
        set(gca, 'XTick',xt, 'XTickLabel',(xt-xt00)/4 + 2000)
        set(gca,'FontSize',10)
        title('State variable','FontSize',14)
        subplot(2, 1, 2)
        plot(1:size(data,1), state.Fs, 'k', 'LineWidth', 2)
        axis('tight')
        grid on
        ylim([0 1 ])
        set(gca, 'XTick',xt, 'XTickLabel',(xt-xt00)/4 + 2000)
        set(gca,'FontSize',10)
        title('Regime indicator / logistic transformation','FontSize',14)
    elseif strcmp(state.interacted, 'yes')
        subplot(2, 1, 1)
        plot(1:size(data,1), data(:,state.shockpos), 'k', 'LineWidth', 2)
        if min(data(~isnan(data(:,state.shockpos)),state.shockpos)) < 0 && max(data(~isnan(data(:,state.shockpos)),state.shockpos)) > 0
            hold on
            plot(1:size(data,1), zeros(size(data,1),1), 'k', 'LineWidth', .5)
        end
        axis('tight')
        grid on
        set(gca, 'XTick',xt, 'XTickLabel',(xt-xt00)/4 + 2000)
        set(gca,'FontSize',10)
        title('Interacted variable 1: Shock','FontSize',14)
        subplot(2, 1, 2)
        area([state.s*min(data(:,state.statepos)), ...
            state.s*(max(data(:,state.statepos))-min(data(:,state.statepos)))], ...
            'FaceColor', [0.9 0.9 0.9], 'EdgeColor', [0.9 0.9 0.9])
        hold on
        plot(1:size(data,1), data(:,state.statepos), 'k', 'LineWidth', 2)
        if min(data(~isnan(data(:,state.shockpos)),state.shockpos)) < 0 && max(data(~isnan(data(:,state.shockpos)),state.shockpos)) > 0
            plot(1:size(data,1), zeros(size(data,1),1), 'k', 'LineWidth', .5)
        end
        axis('tight')
        legend('Regime 2', 'Location', 'NorthWest')
        legend boxoff
        grid on
        set(gca, 'XTick',xt, 'XTickLabel',(xt-xt00)/4 + 2000)
        set(gca,'FontSize',10)
        title('Interacted variable 2: State','FontSize',14)
    end
    set(gcf,'paperpositionmode','auto')    
    set(gcf, 'position', [0 0 800 400]);
end

clear vv col nona xt00 xt nrow s col1 col2
