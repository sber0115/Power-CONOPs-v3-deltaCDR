

init_soc = 0.8; %start simulation with this state-of-charge           
start_charge_soc = 0.85; %when in roving mode, rover will 
                         %stop to charge once under this state-of-charge
end_charge_soc = .95;   %if in charging mode and state-of-charge 
                        %exceeds this parameter, go back to roving

occlusion_power_consumption = 21; %[W]
        %encompasses the assumption outlining that once power generation 
        %falls below the nominal roving power consumption, 
        %power consumption will be limited to 21W
                               
roving_power_generation = 68; %[W]
        %during roving conditions, solar panel temperatures 
        %will lead to this basline power generation

input_regolith_factor = .25; %specify a percentage effiency loss in 
                            %power generation due to lunar dust 
                            %coverage on the solar panel
regolith_factor_delta = .00; %specify the increase in the 
                             %percentage effiency loss due to lunar dust

trek_duration     =  50; % specify in [Hrs] how long the simulation will be

plan_duration     =  0;    %specify in [Hrs] the planning phase of mission
downlink_duration =  0;  %specify in [Hrs] downlink phase of mission

max_distance_from_lander = 500; % specify the distance at which the rover "heads back" to the lander

%% User can see how energy expenditure changes 
%  by disabling/enabling rocks/craters/shadows
enable_rocks = true;
enable_shadows = true;
enable_craters = true;

max_charge_period = 0; %[Hrs]
max_shadow_time   = 5*60; %[secs, 5 mins total]


