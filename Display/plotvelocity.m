function [] = plotvelocity(t, velocity)

    a = struct2cell(velocity);
    b = [a{2,:}];
    plot(t,real(b)); 
    
    legend('xdot','ydot','zdot');
    xlabel('Time (s)');
    ylabel('Velocity (m/s)');
    title('World Frame Velocity');
    grid on;
end