function temp_monitor(arduinoObj, tempPin, greenPin, yellowPin, redPin, V0, Tc, minTemp, maxTemp)
%TEMP_MONITOR Monitor cabin temperature and control LED indicators
%   TEMP_MONITOR(a, tempSensorPin, duration) continuously reads temperature
%   from specified analog pin and controls LEDs based on comfort range:
%   - Steady GREEN: 18-24°C (comfort range)
%   - Blinking YELLOW: <18°C (0.5s interval)
%   - Blinking RED: >24°C (0.25s interval)
% initialization variable
sampleInterval = 1; % Sampling interval
maxSamples = 600;   % Maximum sampling points 
timeStamps = zeros(maxSamples, 1);
temperatures = zeros(maxSamples, 1);

% Create a real-time graphical window
figure;
hPlot = plot(NaN, NaN, 'b-', 'LineWidth', 1.5);
xlabel('Time (second)');
ylabel('Temperature (°C)');
title('Real-time cabin temperature monitoring');
grid on;
hold on;

% Draw the reference line for the comfortable temperature range
yline(minTemp, 'g--', 'Lower limit of comfort', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
yline(maxTemp, 'r--', 'Upper limit of comfort', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
ylim([minTemp-5, maxTemp+5]); % Set the Y-axis range


% Main monitoring loop
sampleCount = 0;
while true
    % Update the sampling count
    sampleCount = sampleCount + 1;
    
    % Read and convert the temperature data
    voltage = readVoltage(arduinoObj, tempPin);
    currentTemp = (voltage - V0) / Tc;
    
    % recorded data
    if sampleCount <= maxSamples
        timeStamps(sampleCount) = (sampleCount-1) * sampleInterval;
        temperatures(sampleCount) = currentTemp;
    else
        % The buffer is full. Scroll the data
        timeStamps = [timeStamps(2:end); (sampleCount-1)*sampleInterval];
        temperatures = [temperatures(2:end); currentTemp];
    end
    
    % Update the real-time graphics
    set(hPlot, 'XData', timeStamps(1:sampleCount), 'YData', temperatures(1:sampleCount));
    xlim([0, max(timeStamps(1:sampleCount))]);
    drawnow;
    
    % Control the LED according to the temperature
    if currentTemp >= minTemp && currentTemp <= maxTemp
        % Comfort range - Green LED constantly on
        writeDigitalPin(arduinoObj, greenPin, 1);
        writeDigitalPin(arduinoObj, yellowPin, 0);
        writeDigitalPin(arduinoObj, redPin, 0);
        
    elseif currentTemp < minTemp
        % Below the comfort range - Yellow LED flashes (at 0.5-second intervals)
        writeDigitalPin(arduinoObj, greenPin, 0);
        writeDigitalPin(arduinoObj, redPin, 0);
        
        % Yellow LED flashing
        writeDigitalPin(arduinoObj, yellowPin, 1);
        pause(0.25);
        writeDigitalPin(arduinoObj, yellowPin, 0);
        pause(0.25);
        
    else
        % Above the comfort range - Red LED flashes (0.25 second interval)
        writeDigitalPin(arduinoObj, greenPin, 0);
        writeDigitalPin(arduinoObj, yellowPin, 0);
        
        % The red LED flashing.
        writeDigitalPin(arduinoObj, redPin, 1);
        pause(0.125);
        writeDigitalPin(arduinoObj, redPin, 0);
        pause(0.125);
    end
    
    % Control the sampling frequency
    pause(sampleInterval - 0.5); % Subtract the LED flashing time
end
end