
%                Simulation of Quadrotor Recovery Control 
%                by Gareth Dicker and Fiona Chui
%                Major work performed in January 2016
%
%   Description: Simulation of quadrotor collision recovery control for
%   prediction and validation of experimental collisions of the Spiri 
%   quadrotor platform.

% Siginificant files:

% /Dynamics/dynamicsystem.m contains the quadrotor dynamics equations
% /Initialize/initparams.m contains thrust/drag coefficient, intertias...
% /Controller/checkrecoverystage.m contains switch conditions between stages
% /Controller/computedesiredacceleration.m formulates controller input
% /Controller/controllerrecovery.m performs control based on Faessler's work

clear all;
close all;
clc;

%% Definition of Constants and Variables

% Initialize global parameters.
initparams;

% Define starting pose and twist parameters.

% NOTE TO PLEIADES: Play around with initial conditions and gains in
% controller recovery to get a sense for the aggressiveness of the control

IC.posn     = [0; 0; 5]; % world frame position (meters) 
IC.linVel   = [0; 0; 0]; % world frame velocity (m / s)
IC.angVel   = [0; 0; 0]; % body rates (radians / s)
IC.attEuler = [-3; 0; 0]; % [roll; pitch; yaw] (radians)

% Initialize state and its derivative.
[state, stateDeriv] = initstate(IC);

endTime = 2;  % seconds
dt = 1 / 200; % time step (Hz)

% Define control types using pose and twist struct types.
Control = initcontrol;

% Initialize propeller state (superfluous)
PropState = initpropstate([-1000; 1000; -1000; 1000]);

% Update pose and twist structs from state and its derivative.
[Pose, Twist] = updatekinematics(state, stateDeriv);

% Initialize history for plotting and visualizing simulation.
Hist = inithist(state, stateDeriv, Pose, Twist, Control, PropState);

% Three recovery stages
% 1: before attitude stabilized
% 2: attitude stabilized, vertical velocity unstable
% 3: both attitude and vertical velocity stable
recoveryStage = 1;

for i = 0 : dt : endTime - dt

    % recovery stage can only increase from 1 --> 2 --> 3
    recoveryStage = checkrecoverystage(Pose, Twist, recoveryStage)

    [Control] = computedesiredacceleration(Control, Pose, Twist, recoveryStage);
    [Control] = controllerrecovery(dt, Pose, Twist, Control, Hist, recoveryStage, i);
    
    % Propagate dynamics.
    options = odeset('RelTol',1e-3);
    [tODE,stateODE] = ode45(@(tODE, stateODE) ...
    dynamicsystem(tODE, stateODE, dt, Control.rpm, PropState.rpm),[i i+dt], Hist.states(:,end), options);
    [stateDeriv, PropState] = dynamicsystem(tODE(end), stateODE(end,:)', dt, Control.rpm, PropState.rpm);
    state = stateODE(end,:)';
    t = tODE(end,:)- dt;

    % Update kinematic variables from dynamics output.
    [Pose, Twist] = updatekinematics(state, stateDeriv);

    % Update history.
    Hist = updatehist(Hist, t, state, stateDeriv, Pose, Twist, Control, PropState);
    
end
%% Note: only some of these graphs plot what their legends say

%  plotcontrolforcetorque(Hist.times, Hist.controls);

% plotbodyrates(Hist.times, Hist.controls, Hist.twists);

% plotposition(Hist.times, Hist.poses);

plotangles(Hist.times, Hist.poses);

% plotvelocity(Hist.times, Hist.twists);

% plotcontrolrpm(Hist.times, Hist.controls);

% plotderivrpm(Hist.times, Hist.propstate);

% ploterrorquaternion(Hist.times, Hist.controls);

%% Visualize simulation.
simvisualization(Hist.times, Hist.states, 'YZ');
