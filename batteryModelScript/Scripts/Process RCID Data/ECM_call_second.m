function [err] = ECM_call_second(X,r0_opt,ini_SOC_opt, V_new, I_new, Time_new, OCV, SOC )

 
    c1_opt = X(1);
    r1_opt = X(2);
    c2_opt = X(3);
    r2_opt = X(4);
    
options = simset('SrcWorkspace','current'); % CRITICAL: set workspace for model I/O
Tend = max(Time_new); % Set simulation end time
sim('ECM_opt_second',[Tend],options);


% Compute RMS error 
%err = sum((V_opt_data-V_sim_data).^2);
err = sqrt(sum((V_opt_data - V_sim_data).^2)/(length(I_new)-1));


end