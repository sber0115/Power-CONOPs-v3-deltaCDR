
%% Graphing distance-from-lander vs time

figure
plot(time_vector/time_scale,distance_travelled)
title('Distance from Lander vs Time')
%xline(25.59, '--r', {'Occlusion end'});
%title('Distance from Lander vs Time')
xlabel('Time (hrs)')
xlim([25.59, backAtLander_time/60^2])
ylim([0, 550])
%xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylabel('Distance from Lander (m)')
totalTrekTime_text = [{'Speed-made-good: ' [num2str(round(100000/(backAtLander_time - occlusion_end_time), 2)) ' cm/s']} ];
text(backAtLander_time/60^2 - 3.5, 490, totalTrekTime_text);
totalTrekTime_text = [{'Total time for trek: ' [num2str(round((backAtLander_time/60^2 - occlusion_end_time/60^2), 1)) ' hours']} ];
text(backAtLander_time/60^2 - 3.5, 425, totalTrekTime_text);

%% Graphing state-of-charge vs time

figure
plot(time_vector/time_scale,battery_soc*100)
title('Battery State-of-Charge vs Time (During Occultation)')
line_30W.LabelVerticalAlignment = 'middle';
line_transitionToHibernation = xline(4, '--r', {'Transition to 20W power consumption'});
line_transitionToHibernation.LabelVerticalAlignment = 'middle';
%line_transitionToRoving = xline(22, '--r', {'Power generation back at 53W'});
line_transitionToRoving.LabelVerticalAlignment = 'middle';
%line_transitionToNominal = xline(24.5, '--r', {'Power generation back at 67W'});
line_transitionToNominal.LabelVerticalAlignment = 'middle';
line_pos_power.LabelVerticalAlignment = 'middle';
%line_occlusion_end = xline(25.59, '--r', {'Occlusion end'});
line_occlusion_end.LabelVerticalAlignment = 'middle';
hold on
%title('Battery State-of-Charge vs Time')
xlim([0, 25.6])
%xlim([0, backAtLander_time/60^2])
%xlim([25.6, backAtLander_time/60^2])
%xticks(linspace(0,trek_duration, 10))
xtickformat('%.1f')
ylim([0,100]);
xlabel('Time (hrs)')
ylabel('State of Charge (100% Max)')


