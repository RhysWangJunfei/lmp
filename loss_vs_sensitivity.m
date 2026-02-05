filename = 'case1181';
mpc = loadcase(filename);
default_demand_p = mpc.bus(:,3);
default_demand_q = mpc.bus(:,4);
flag=0;
pf_list=[];
loss_list=[];
nb = size(mpc.bus,1);   % number of buses
ng = size(mpc.gen,1);   % number of generators
while flag<5000
    try 
        mpc = loadcase(filename);
        %mpc.branch(:,6) = line_constraint(:,5);
        rdm_per_p = ones(nb,1)*-0.5+rand(nb,1)*1;
        rdm_per_q = ones(nb,1)*-0.5+rand(nb,1)*1;
        new_p = default_demand_p.*(1+rdm_per_p);
        new_q = default_demand_q.*(1+rdm_per_q);
        mpc.bus(:,3) = new_p;
        mpc.bus(:,4) = new_q;
        [result,success]=runopf(mpc,mpoption('pf.enforce_q_lims', 1));
        
    catch ME
        % Handle exceptions
        disp('An error occurred while solving the OPF:');
        disp(ME.message); % Display the error message
    end
    H   = makePTDF(mpc);                 % single-slack (bus 1 in your case)

    
    % build generator-to-bus mapping
    Cg = sparse(mpc.gen(:,1), 1:ng, 1, nb, ng);
    
    % compute total Pg per bus
    Pg_bus = Cg * result.gen(:,2);
    
    % compute net injection
    p = Pg_bus - mpc.bus(:,3);
    f_hat = H * p;                       % PTDF-based flows (MW)
    datapoint = [f_hat.'];
    condition = [p.'];
    pf_list = [pf_list;datapoint];
    loss_list = [loss_list;condition];
    flag = flag+1;
end


