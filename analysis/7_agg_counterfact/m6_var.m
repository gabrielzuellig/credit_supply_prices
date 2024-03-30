

%% Load data, generate lags, subset relevant subsample, etc.
load('temp/data_q_ready.mat')
subset_data;

%% Akaike information criterion
BIC = zeros(6,1);
for pp = 1:6
   VAR = estimateVAR(data, pp, c_case, exdata);
   BIC(pp) = log(det(VAR.Omega)) + (2*pp*VAR.n^2)/VAR.t;
end
disp(['BIC suggests ', num2str(find(BIC == min(BIC))), ' lags.'])
disp(['Current setting: ', num2str(p)])
clear BIC pp VAR

%% Estimate matrices A, Omega, S, dynamic multipliers
VAR = estimateVAR(data, p, c_case, exdata);
VAR.C = dyn_multipliers(VAR, h); % not identified
VAR.savedata = savedata;
clear savedata

%% Identification: Cholesky
% organization
VAR.ident = ident;
VAR.shock = zeros(n,1);
VAR.shock(shockpos) = 1;
if shocksize ~= 0  % absolute values, e.g. 25bp = 0.25
    VAR.shock = VAR.shock ./ VAR.S(shockpos, shockpos) .* shocksize;
end
% Cholesky decomposition (already done in estimation function)
disp(VAR.S)
VAR.eps = VAR.u*inv(VAR.S);
% impulse responses
VAR.IRF = zeros(h,n);
for hh=1:h
    VAR.IRF(hh,:) = (VAR.C(:,:,hh)*VAR.S*VAR.shock)';
end

%% Bootstrap
[VAR.IRFbands, VARboot] = bootstrapVAR(VAR, nboot, 100-alpha, 'residual');

%% Plot impulse responses and save VAR structure
plotirf1(VAR.IRF, VAR.IRFbands, printvars, strcat(folder,'irf_pre07'))
save(strcat(folder, 'out_var.mat'), 'VAR', 'VARboot')

