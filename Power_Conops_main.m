%% Populating crater and rock vectors according to user parameters
%  Crater and rock characteristics determined by the Rock and
%  CraterDistribution files in this directory

if (enable_rocks)
    rock_findings = randi([occlusion_end_time, ...
        length(time_vector)], 1, length(rockAvoidances)*2);
    all_avoided_rocks = zeros(1, length(rockAvoidances));
else
    rock_findings = [];
    all_avoided_rocks = [];
end

if (enable_shadows)
    shadow_findings = randi([occlusion_end_time, ...
        length(time_vector)], 1, 50);
else
    shadow_findings = [];
end

if (enable_craters)
    crater_findings = randi([occlusion_end_time, ...
        length(time_vector)], 1, length(craterAvoidances)*2);
    all_avoided_craters = zeros(1, length(craterAvoidances));
else
    crater_findings = [];
    all_avoided_craters = [];
end

%% Variables to index into rock and crater vectors
%  Temporary variables to store information about a specific entry in those
%  vectors as well.

rock_find_index = 1;
rock_turn_energy = 0;
rock_straight_distance = 0;
rock_turn_time = 0;

crater_find_index = 1;
crater_turn_energy = 0;
crater_straight_distance = 0;
crater_turn_time = 0;

% flags/booleans used for control flow logic
is_charging = false;
is_avoiding_rock = false;
is_avoiding_crater = false;
in_shadow    = false;
changed_direction = false;

%indexes and flags to change the current input power
change_curr_power = false;
occ_index = 1;

% variables to keep track of avoidance and shadow times
time_avoiding_rock = 0; %[secs]
time_avoiding_crater = 0; %[secs]
time_in_shadow = 0; %[secs]
distance_covered = 0; %[m]
direction_change_time = 0;
backAtLander_time = 0; %[s]

%%

%{
Factor by which the distance travelled toward target decreases 
is determined by calculating two times

Time 1: Determining time required to execute avoidance
Time 2: Determining time it takes rover to travel (diameter of turn) meters, 
        assuming a straight path
Take the ratio of time2/time1
%}

%% Control flow for obstacle avoidance
soc_under_100 = true; %flag to make sure battery state of charge is under 100%
                      %if not used then battery state-of-charge will go
                      %above 100%
for i = length(trek_phase1)+1:length(time_vector)
    spec_time = time_vector(i);
    rock_found = ismember(spec_time, rock_findings);
    shadow_found = ismember(spec_time, shadow_findings);
    crater_found = ismember(spec_time, crater_findings);
    change_curr_power = ismember(spec_time, occ_times);
       
    % change the current power generation based on occ_powers vector in the
    % _constants files in this directory 
    % (changes every hour during the occultation)
    if (change_curr_power && occ_index < length(occ_times))
       occ_index = occ_index + 1; 
    end
    
    %this control logic is used to change the sign of 
    %the distance increments being done on the distance vector
    %i.e distances changes will be negative once max_distance_from_lander
    %is reached
    if (distance_travelled(i-1) >= max_distance_from_lander && ~is_avoiding_rock && ~is_avoiding_crater)
       changed_direction = true; 
       direction_change_time = spec_time;
    end
       
    %this is accessible by the rest of the cases in the code
    %regolith_factors(i) encompasses loss in efficiency due to lunar dust
    occlusion_power_generation = occlusion_powers(occ_index)*regolith_factors(i);
    
    can_avoid_rock = ~is_charging && ~is_avoiding_rock && ~is_avoiding_crater ...
                     && rock_find_index <= length(rockAvoidances);
    %similarly for craters
    can_avoid_crater = ~is_charging && ~is_avoiding_crater && ~is_avoiding_rock ...
                       && crater_find_index <= length(craterAvoidances);
                   
    %at the 4 hour mark, power generation falls below nominal power consumption during roving
    if (spec_time < 4*3600) 
        energy_change = (occlusion_power_generation - nominal_rove_mode*battery_efficiency_multipliers(i));
        distance_covered = 0;
    
    % so after the initial four hours, change mode to
    % occlusion_power_consumption, and consider battery efficiency
    elseif (spec_time < 92136)
        energy_change = (occlusion_power_generation - ...
                occlusion_power_consumption*battery_efficiency_multipliers(i));
        distance_covered = 0;
    
    % if the following conditionals are reached, rover is in roving mode
    elseif (battery_soc(i-1) < start_charge_soc && ~is_charging)
        is_charging = true;
        energy_change = (roving_power_generation*angle_offset(i)*regolith_factors(i) ...
                        - charge_min_mode);
        distance_covered = 0;
    
    elseif (is_charging)
        if (battery_soc(i-1) >= end_charge_soc) %exit charging_mode
            is_charging = false;
            energy_change = (roving_power_generation*angle_offset(i)*regolith_factors(i) - nominal_rove_mode);
            distance_covered = normal_distance;
        else  %continue charging mode until state-of-charge reaches user specified end_charge_soc parameter
            energy_change = (roving_power_generation*angle_offset(i)*regolith_factors(i) - charge_min_mode);
            distance_covered = 0;
        end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ROCK AVOIDANCE
    elseif (rock_found && can_avoid_rock)    
        all_avoided_rocks(rock_find_index) = rockAvoidances(4, rock_find_index);
        is_avoiding_rock = true;
        time_avoiding_rock = 0;
        
        %get associated information for this rock
        %includes diameter, energy needed to avoid it, and how long it'd
        %take to do so
        rock_turn_energy = rockAvoidances(1,rock_find_index);
        rock_straight_distance = rockAvoidances(2, rock_find_index);
        rock_avoidance_duration = rockAvoidances(3,rock_find_index);
        %calculate linear distance factor (factor by which speed is affected during skid-steer)
        straight_total_time = rock_straight_distance / velocity_m;
        linear_distance_factor = straight_total_time / rock_avoidance_duration;
        
        avionics_consumption = extreme_rove_mode;
        %note, rock turn energy given in Joules, but total energy must be
        %expended over the duration of the entire manuever, so we must
        %divide by the manuever duration (to get W, which will be interpreted as J)
        avoidance_consumption = rock_turn_energy / rock_avoidance_duration;
        power_generated = (roving_power_generation*regolith_factors(i)*angle_offset(i))*0.6;         
        energy_change = power_generated + -1 *(avoidance_consumption + avionics_consumption);    
     
        rock_find_index = rock_find_index + 1;
        
        distance_covered = normal_distance*linear_distance_factor;
   
    elseif (is_avoiding_rock)
        if (time_avoiding_rock == rock_avoidance_duration-1) %finished avoiding rock so back to nominal rove
            is_avoiding_rock = false;
            time_avoiding_rock = 0;
            energy_change = roving_power_generation*regolith_factors(i)*angle_offset(i) - nominal_rove_mode;
    
            distance_covered = normal_distance;
            
        else %still avoiding rock
            time_avoiding_rock = time_avoiding_rock + 1;
            
            if (time_in_shadow >= max_shadow_time)
                time_in_shadow = 0;
                in_shadow = false;
                power_generated = (roving_power_generation*regolith_factors(i)*angle_offset(i)); 
            elseif (in_shadow)
                time_in_shadow = time_in_shadow + 1;
                power_generated = 0;
            else
                power_generated = (roving_power_generation*regolith_factors(i)*angle_offset(i))*0.6;     
            end
             
            energy_change = power_generated + -1 *(avoidance_consumption + avionics_consumption); 
     
            distance_covered = (normal_distance*linear_distance_factor);
        end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CRATER AVOIDANCE
    elseif (crater_found && can_avoid_crater)  
        all_avoided_craters(crater_find_index) = craterAvoidances(4, crater_find_index);
        is_avoiding_crater = true;
        time_avoiding_crater = 0;
        
        %get associated information for this crater
        %includes diameter, energy needed to avoid it, and how long it'd
        %take to do so
        crater_turn_energy = craterAvoidances(1,crater_find_index);
        crater_straight_distance = craterAvoidances(2, crater_find_index);
        crater_avoidance_duration = craterAvoidances(3,crater_find_index);
        %calculate linear distance factor (factor by which speed is affected during skid-steer)
        straight_total_time = crater_straight_distance / velocity_m;
        linear_distance_factor = straight_total_time / crater_avoidance_duration;
        avionics_consumption = extreme_rove_mode;
        avoidance_consumption = crater_turn_energy / crater_avoidance_duration; 
        power_generated = (roving_power_generation*regolith_factors(i)*angle_offset(i))*0.6;    
        energy_change = power_generated + -1 *(avoidance_consumption + avionics_consumption); 
  
        distance_covered = (normal_distance*linear_distance_factor);
        crater_find_index = crater_find_index + 1;
        
    elseif (is_avoiding_crater)
        if (time_avoiding_crater == crater_avoidance_duration-1) %finished avoiding crater so back to nominal rove
            is_avoiding_crater = false;
            time_avoiding_crater = 0;
 
            energy_changed = roving_power_generation*regolith_factors(i)*angle_offset(i) - nominal_rove_mode;
            distance_covered = normal_distance;
            
        else %still avoiding crater
            time_avoiding_crater = time_avoiding_crater + 1;
 
            if (time_in_shadow >= max_shadow_time)
                time_in_shadow = 0;
                in_shadow = false;
                power_generated = (roving_power_generation*regolith_factors(i)*angle_offset(i));
            elseif (in_shadow)
                time_in_shadow = time_in_shadow + 1;
                power_generated = 0;
            else
                power_generated = (roving_power_generation*regolith_factors(i)*angle_offset(i))*0.6;     
            end
             
            energy_change = power_generated + -1 *(avoidance_consumption + avionics_consumption); 
     
            distance_covered = (normal_distance*linear_distance_factor);
        
        end
    else
        
        energy_change = (roving_power_generation*regolith_factors(i)*angle_offset(i) - nominal_rove_mode);
        if (shadow_found) %while in shadow power generation is NULL (= 0)
            in_shadow = true;
            energy_change = (-1 * nominal_rove_mode);
            time_in_shadow = 0;
        elseif (in_shadow && time_in_shadow < max_shadow_time) %continue in shadow until max_shadow_time specified by user
            energy_change = (-1 * nominal_rove_mode);  
            time_in_shadow = time_in_shadow + 1;
        elseif (time_in_shadow == max_shadow_time)
            in_shadow = false;
            time_in_shadow = 0;
        end
        
        distance_covered = normal_distance;
        
    end
    
    temp_cap = (battery_cap(i-1) + energy_change);
    %check to see if state-of-charge exceeds 100%
    %if too much energy is being generated, then it will max out on
    %the state-of-charge graph
    if (abs(temp_cap/battery_total - 1) > tolerance)
        battery_cap(i) = (battery_cap(i-1) + energy_change);
    else
        battery_cap(i) = battery_cap(i-1);
    end
    
    battery_soc(i) = battery_cap(i)/battery_total;
    
    %% logic used to keep track of when rover reached lander
    %  at that time, the rover "changes direction" and distance
    %  changes are negative, so distance from lander starts decreasing
    if (changed_direction)
        if (distance_travelled(i-1) <= 0)
           backAtLander_time = spec_time; 
           break;
        else
            distance_covered = -1*distance_covered;
        end
    else
        distance_covered = distance_covered;
    end
    
    distance_travelled(i) = distance_travelled(i-1) + distance_covered;
end