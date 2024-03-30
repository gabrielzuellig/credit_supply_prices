function [IRFbands, VARboot] = bootstrapVAR(VAR, nboot, alpha, method)

% inputs: 1. VAR structure incl. data and estimated A, 2. confidence level

% unpacking
t = size(VAR.u,1);
ub= VAR.u;
n = VAR.n;
u = VAR.u;
A = VAR.A;
X = VAR.X;
p = VAR.p;
IRFb = NaN*ones(size(VAR.IRF,1), size(VAR.IRF,2), nboot);
h = size(VAR.IRF,1);
VARboot.A = NaN*ones([size(VAR.A), nboot]);
VARboot.C = NaN*ones([size(VAR.C), nboot]);

% define upper and lower thresholds
if isempty(alpha)
    alpha = 90;
end
lo = (100-alpha)/2;
up = 100 - lo;

disp('Progress \n')
for bb = 1:1:nboot  % 'nboot' bootstraps

    % generate pseudo-disturbance 'ub'
    if strcmp(method, 'residual')
        % residual bootstrapping assumes E(y|Xb) = X*b and u are iid (i.e.
        % homoskedasticity => Draw from the empirical distribution of u
        
        segment = (1:t)/t;
        ub = zeros(ceil(1.25*t)+p,n);
        for i=1:size(ub,1)
            draw = rand(1,1);  % uniform distribution
            ub(i,:) = u(min(find(segment>=draw)),:);
        end
        
    elseif strcmp(method, 'wild')
        % allows for heteroskedasticity

        fu = 1-2*(rand(t,1)>0.5);
        ub = zeros(size(VAR.u));
        for i=1:n
            ub(:,i) = u(:,i).*fu;  % flip sign of randomly selected 50%
        end

    end

    % generate pseudo-sample based on drawn u's
    Yb = zeros(size(ub,1),n);
    r = X(1,:);
    for i=1:size(ub,1)
        Yb(i,:) = r*A + ub(i,:);
        if VAR.c_case == 0
            r = [Yb(i,:), r(1:end-n)];
        elseif VAR.c_case == 1
            r = [1, Yb(i,:), r(2:end-n)];
        elseif VAR.c_case == 2
            r = [1, i, Yb(i,:), r(3:end-n)];
        end
    end

    if strcmp(VAR.ident, 'chol') || strcmp(VAR.ident, 'no')
        data = Yb(end-size(VAR.data,1)+1:end,:); % trim data to original length
    elseif strcmp(VAR.ident, 'proxy')
        data = Yb; % can only have original length minus p lags because of u.
        if strcmp(method, 'wild')
            zb = VAR.z.*fu;
            zb = zb(p+1:end,:);
        else
            error('Proxy-VAR calls for the Wild bootstrapping method.')
        end
    end
        
    % estimate VAR and IRF
    VARb = estimateVAR(data, VAR.p, VAR.c_case, VAR.Xex);
    VARb.C = dyn_multipliers(VARb, h);

    % identify shock
    if strcmp(VAR.ident, 'no')
        for hh=1:h
            IRFb(hh,:,bb) = (VARb.C(:,:,hh)*VAR.shock)';
        end
    elseif strcmp(VAR.ident, 'chol')
        for hh=1:h
            IRFb(hh,:,bb) = (VARb.C(:,:,hh)*VARb.S*VAR.shock)';
        end
    elseif strcmp(VAR.ident, 'proxy')
        b = logical(1:n == VAR.shockpos);
        u_p = VARb.u(:,b);  % reduced-form residuals to be instrumented
        u_q = VARb.u(:,~b); % all other residuals
        nona = logical(isnan(zb) == 0);
        u_p = u_p(nona,1);
        u_q = u_q(nona,:);
        zb = zb(nona,1);
        % 1st-stage of IV: u_p on z
        zb = [ones(size(zb,1),1), zb];
        beta1 = zb\u_p;
        u_p_hat = zb*beta1;
        % 2nd-stage
        sb(~b) = u_p_hat\u_q;
        sb(b) = 1; % normalize s at shockpos to 1
        % impulse responses
        for hh=1:h
            IRFb(hh,:,bb) = (VARb.C(:,:,hh)*sb')';
        end    
    end
    
    % save A and C in 3-dim structure
    VARboot.A(:,:,bb) = VARb.A;
    VARboot.C(:,:,:,bb) = VARb.C;

    % progress bar
    fprintf(1,'\b\b\b\b%3.0f%%',100*(bb/nboot)); 

end
fprintf('\n');

% retrieve intervals
IRFbands=prctile(IRFb, [lo up], 3);
