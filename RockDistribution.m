

Diameters = (0.0:0.05:1);
N = 0.0279.*exp(-867/500.*Diameters)./Diameters-0.04785.*expint(1867./500.*Diameters);

maxAllowedRockHeight = 0.080; %[m]
wheelWidth = 0.080; %[m]

maxDiameter = round(((maxAllowedRockHeight - 0.0039)/0.2347),2); %max diameter of a rock with the max height

D = (maxDiameter:0.01:1.0);
%cumulative frequency of rocks with diameter >= maxD per square meter
rocksCumulative = 0.0279.*exp(-867/500.*D)./D-0.04785.*expint(1867./500.*D);
 
rocksOnPath = [D ; zeros(1,length(rocksCumulative))];
for index = 1:length(rocksOnPath)-1
    rocksOnPath(2,index) = rocksCumulative(index)-rocksCumulative(index+1);
end


roverWidth = 0.650; %[m]
distance = 1000; %distance to target [m]


rocks = [D ; zeros(1,length(rocksOnPath))]; %diameter of rocks; # of rocks with that diameter
for index = 1:length(rocks)
%     disp(distance + "-" + D(index) + "=" + (distance-D(index)));
    travelArea = (roverWidth+D(index))*distance;
    rocks(2,index) = (rocksOnPath(2,index)*travelArea);
    distance = distance - D(index);
end

rockClearance = 0.300; %[m]
turnRadii = roverWidth/2 + rocks(1,:)/2 + rockClearance; %turn radius = roverWidth/2 + rockDiameter/2 + clearance [m]

pointTurnTime = 28; %time to point turn 90deg [s]
pointTurnPower = 10; %[W]
skidTurnPower = 12; %[W]
straightVelocity = velocity_m; %[m/s]
skidTurnVelocity = straightVelocity/2; %[m/s]
skidTurnTimes = pi*turnRadii/skidTurnVelocity; %time to do each skid turn [s]

pointTurnEnergy = pointTurnTime*pointTurnPower; %W*s
skidTurnEnergies = skidTurnTimes*skidTurnPower; %W*s

totalTurnTimes = round(skidTurnTimes+2*pointTurnTime); %[s]
totalTurnEnergies = skidTurnEnergies+2*pointTurnEnergy; %W*s
straightPathDistances = 2*turnRadii; %[m]

rockAvoidances = [totalTurnEnergies ; straightPathDistances; totalTurnTimes; D];
rock_cols = size(rockAvoidances,2);
rock_perm = randperm(rock_cols);
rockAvoidances = rockAvoidances(:, rock_perm);

x = sum(rocks(2,1:end));