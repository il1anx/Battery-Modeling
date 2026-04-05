function err = Param_Opt(Coef,Param)
% Compute 1st oder battery model response and rms error 
% from measured voltage data V
% V = E0 - R0*I-VC
% Coef(1): C1
% Coef(2): R1
% Param(3): E0
% Param(4): R0

global V_new I_new Time_new
deltat = Time_new(3) - Time_new(2);
n = length(I_new);
Vc = zeros(size(I_new));

% compute capacitor voltage
for i = 2:n
    Vc(i) = Vc(i-1)*exp(-deltat/(Coef(1)*Coef(2)))+ ...
        Coef(2)*I_new(i-1)*(1-exp(-deltat/(Coef(1)*Coef(2))));
end

% Compute Estimated voltage
Vest = Param(1) - Param(2).*I_new - Vc;

% Compute RMS error 
err = sqrt(sum((V_new-Vest).^2)/(length(I_new)-1));
