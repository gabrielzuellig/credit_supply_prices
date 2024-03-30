
%% prep
load(strcat(folder, 'out_var.mat'))
res = VAR.savedata.data;
time = VAR.savedata.time;
res = res(logical(time >= 2000 & time < 2016),:);
res = [res, res, res];
time = time(logical(time >= 2000 & time < 2016),:);
res(find(time > samplemax,1,'first'):end,n+1:end) = NaN;
resboot = repmat(res(:,[n+1:2*n]), 1, 1, nboot);

%% iterate system forward without shocks or adjustments, just for reference
if c_case == 0
    xlag = [VAR.Y(end,:), VAR.X(end,1:end-n)];
elseif c_case == 1
    xlag = [ones(1,1), VAR.Y(end,:), VAR.X(end,2:end-n)];
elseif c_case == 2
    xlag = [ones(1,1),  VAR.X(end,2)+1, VAR.Y(end,:), VAR.X(end,3:end-n)];
end
for tt = find(isnan(res(:,n+1)),1,'first'):1:size(res,1)
    Ypred = xlag*VAR.A;
    res(tt, n+1:2*n) = Ypred;
    if c_case == 0
        xlag = [Ypred, xlag(1:end-n)];
    elseif c_case == 1
        xlag = [ones(1,1), Ypred, xlag(2:end-n)];
    elseif c_case == 2
        xlag = [ones(1,1), xlag(2)+1, Ypred, xlag(3:end-n)];
    end
end


%% add two elements
% 1. let GDP and inflation load on past shocks
% 2. for each period, adjust GDP to where it actually was
% (the latter requires the update of the residual for inflation, too)
firstcf = find(isnan(res(:,n+3)),1,'first');
u = NaN*ones(size(res,1),n);
u(1:firstcf-1,:) = VAR.u((end-firstcf+2):end,:);
if c_case == 0
    xlag = [VAR.Y(end,:), VAR.X(end,1:end-n)];
elseif c_case == 1
    xlag = [ones(1,1), VAR.Y(end,:), VAR.X(end,2:end-n)];
elseif c_case == 2
    xlag = [ones(1,1),  VAR.X(end,2)+1, VAR.Y(end,:), VAR.X(end,3:end-n)];
end
for tt = firstcf:1:size(res,1)
    Ypred = xlag*VAR.A;
    Yactual = res(tt,1:n);
    diff = Yactual - Ypred;
    addshock = diff(gdppos)*VAR.S(:,gdppos)'/VAR.S(gdppos,gdppos);
    res(tt, n+3:3*n) = Ypred + addshock;
    u(tt,:) = Yactual - Ypred;
    if c_case == 0
        xlag = [Ypred + addshock, xlag(1:end-n)];
    elseif c_case == 1
        xlag = [ones(1,1), Ypred + addshock, xlag(2:end-n)];
    elseif c_case == 2
        xlag = [ones(1,1), xlag(2)+1, Ypred + addshock, xlag(3:end-n)];
    end
end
% bootstrap repeats
for bb = 1:1:nboot
    u = NaN*ones(size(res,1),n);
    VAR.u = VAR.Y - VAR.X*VARboot.A(:,:,bb);
    u(1:firstcf-1,:) = VAR.u((end-firstcf+2):end,:);
    xlag = [ones(1,1), VAR.Y(end,:), VAR.X(end,2:end-n)];
    for tt = firstcf:1:size(res,1)
        Ypred = xlag*VARboot.A(:,:,bb);
        Yactual = res(tt,1:n);
        diff = Yactual - Ypred;
        addshock = diff(gdppos)*VAR.S(:,gdppos)'/VAR.S(gdppos,gdppos);
        resboot(tt, :, bb) = Ypred + addshock;
        u(tt,:) = Yactual - Ypred;
        if c_case == 0
            xlag = [Ypred + addshock, xlag(1:end-n)];
        elseif c_case == 1
            xlag = [ones(1,1), Ypred + addshock, xlag(2:end-n)];
        elseif c_case == 2
            xlag = [ones(1,1), xlag(2)+1, Ypred + addshock, xlag(3:end-n)];
        end
    end
end

res = res/100;
resboot = resboot/100;
res = res - res(firstcf-1,:);
resboot = resboot - resboot(firstcf-1,:,:);
condforec_bands=prctile(resboot, [alpha/2 100-alpha/2], 3);


%% figures
res = res(time >= 2002 & time <= 2013,:);
condforec_bands = condforec_bands(time >= 2002 & time <= 2013,:,:);
time = time(time >= 2002 & time <= 2013);

figure() % GDP level
plot(time, res(:,1), 'LineWidth', 2, 'Color', rgb('navy'))
hold on
plot(time, zeros(size(time)), 'Color', 'black')
plot(time, res(:,5), 'LineWidth', 2, 'Color', rgb('maroon'))
ylabel('log GDP [2007q4 = 0]')
axis('tight')
box off
set(gca, 'YGrid', 'on', 'XGrid', 'off')
set(gca,'fontname','times')
set(gcf,'paperpositionmode','auto')
set(gcf, 'position', [0 0 300 200]);

figure() % Price level
plot(time, res(:,2), 'LineWidth', 2, 'Color', rgb('navy'))
hold on
plot(time, zeros(size(time)), 'Color', 'black')
plot(time, res(:,6), 'LineWidth', 2, 'Color', rgb('maroon'))
ylabel('log PPI [2007q4 = 0]')
axis('tight')
box off
set(gca, 'YGrid', 'on', 'XGrid', 'off')
set(gca,'fontname','times')
set(gcf,'paperpositionmode','auto')
set(gcf, 'position', [0 0 300 200]);

save(strcat(folder, 'out_cf.mat'), 'res', 'condforec_bands', 'time')

