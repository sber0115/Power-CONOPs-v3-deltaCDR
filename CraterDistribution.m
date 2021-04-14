
maxAllowedDepth = 0.080; %[m]
maxDiameterSmallCraters = 10*maxAllowedDepth; %small craters D < 4m have depth=0.1*D , [m]
maxDiameterLargeCraters = 5*maxAllowedDepth; %craters 4m < D < 10m have depth=0.2*D , [m]

Diameters = (8e-5:0.0001:0.005); %[km]
B = 10.^(-1.1-2.*log10(Diameters)); %[craters per km^2]

totalFrequency = 10.^(-1.1-2.*log10(8e-5));


cratersCumulative = [Diameters ; B];
craters = [Diameters ; zeros(1,length(B))];

for index = 1:length(craters)-1
    craters(2,index) = cratersCumulative(2,index)-cratersCumulative(2,index+1);
end

craters = [craters(1,1:end)*1000 ; craters(2,1:end)/(1000^2)]; %initialize maxPossibleCratersOnPath, diameter: [m], frequency: [craters per m^2]
D = craters(1,1:end); %diameter of rocks in [m]

%{
Testing to see if the crater sizes play a big role in speed made good
%}
%D = D(D <= 30);

roverWidth = 0.650; %[m]
travelArea = 1000*(D/2+roverWidth); % 1000m path * (D/2 + rover width) = travel area [m^2]

maxPossibleCratersOnPath = [D ; zeros(length(craters(2,1:end)))];
maxPossibleCratersOnPath(2,1:end) = (craters(2,1:end).*travelArea); %calculate craters seen along path, all integer amounts

craterProbability = [D ; maxPossibleCratersOnPath(2,1:end)./sum(maxPossibleCratersOnPath(2,1:end))];

craterOffsets = round((rand(1,length(D)).*D/2),2); %randomizes crater offsets from path, from 0 to D/2

craterClearances = zeros(1,length(D)); %clearance between rover and crater when driving [m]
for index = 1:length(craterClearances)  
    if D(index) > 5.00 %if D > 5m, clearance set to 1m 
        craterClearances(index) = 1;
    else %if D < 5m, clearance set to 0.25m
        craterClearances(index) = 0.25;
    end 
end

turnRadii = D/2+craterClearances; %[m]
distance = 1000; %[m]

cratersOnPath = randsrc(1,length(D),craterProbability);
ratio = (craterOffsets./(turnRadii)); %ratio of crater offset and the radii of each crater

thetas = acos(ratio); %angle of offset path length

skidTurnDistances = 2*pi*(D/2+1).*(thetas/pi); %length of offset path

pointTurnTime = 28; %time to point turn 90deg [s]
pointTurnPower = 10; %[W]
skidTurnPower = 12; %[W]
straightVelocity = velocity_m; %[m/s]
skidTurnVelocity = straightVelocity/2; %[m/s]
skidTurnTimes = skidTurnDistances/skidTurnVelocity; %time to do each skid turn [s]

poinTurnEnergy = pointTurnTime*pointTurnPower; %W*s
skidTurnEnergies = skidTurnTimes*skidTurnPower; %W*s

totalTurnTimes = round(skidTurnTimes+2*pointTurnTime); %[s]
totalTurnEnergies = skidTurnEnergies+2*poinTurnEnergy; %W*s
straightPathDistances = 2*sin(thetas).*turnRadii;

craterAvoidances = [totalTurnEnergies ; straightPathDistances; totalTurnTimes; D];
crater_cols = size(craterAvoidances,2);
crater_perm = randperm(crater_cols);
craterAvoidances = craterAvoidances(:, crater_perm);
