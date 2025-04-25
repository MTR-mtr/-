function temp_prediction(a, tempSensorPin, duration)
%TEMP_PREDICTION Predicts future temperature trends and provides LED alerts
%   This function continuously monitors temperature and calculates its rate of
%   change to:
%   - Predict temperature 5 minutes ahead
%   - Alert when temperature changes too rapidly (>|4|°C/min)
%   - Visualize real-time temperature data
%
%   LED Indicators:
%   - STEADY GREEN: Temperature stable in comfort range (18-24°C)
%   - STEADY RED: Temperature rising too fast (>4°C/min)
%   - STEADY YELLOW: Temperature falling too fast (<-4°C/min)
    % initialization variable
    sampleInterval = 1; % Sampling interval (seconds)
    samples = duration/sampleInterval;
    tempHistory = zeros(1, samples); % Temperature historical record
    timeStamps = 0:sampleInterval:duration-sampleInterval;

    greenLED = 'D2';
    yellowLED = 'D3';
    redLED = 'D4';
    
    % Configure the LED pins to the output mode
    configurePin(a, greenLED, 'DigitalOutput');
    configurePin(a, yellowLED, 'DigitalOutput');
    configurePin(a, redLED, 'DigitalOutput');
    
    % Temperature sensor parameters(MCP9700A)
    V0 = 0.5; % Output voltage (V) at 0°C
    Tc = 0.01; % Temperature coefficient (V/°C)
    
    % Create a real-time temperature curve graph
    figure;
    hPlot = plot(NaN, NaN);
    xlabel('Time (second)');
    ylabel('temperature (°C)');
    title('Real-time temperature monitoring and prediction');
    grid on;
    hold on;
    
    % main loop
    for i = 1:samples
        % Read the temperature
        voltage = readVoltage(a, tempSensorPin);
        tempC = (voltage - V0)/Tc;
        tempHistory(i) = tempC;
        
        % Calculate the rate of temperature change (using data from the past 10 seconds)
        if i > 10
            timeWindow = timeStamps(max(1,i-10):i);
            tempWindow = tempHistory(max(1,i-10):i);
            p = polyfit(timeWindow, tempWindow, 1); % linear fitting
            rate = p(1); % °C/s
            ratePerMin = rate * 60; % Convert to °C/min
            
            % Predict the temperature in 5 minutes
            predictedTemp = tempC + rate * 300; % 300s=5min
            
            % Display the current status
            clc;
            fprintf('current temperature: %.2f°C\n', tempC);
            fprintf('Rate of temperature change: %.2f°C/min\n', ratePerMin);
            fprintf('Predict the temperature in 5 minutes: %.2f°C\n\n', predictedTemp);
            
            % Alarm logic
            if ratePerMin > 4 % The temperature rises too fast.
                writeDigitalPin(a, greenLED, 0);
                writeDigitalPin(a, yellowLED, 0);
                writeDigitalPin(a, redLED, 1);
                fprintf('Warning: The temperature is rising rapidly\n');
            elseif ratePerMin < -4 % The temperature drops too quickly.
                writeDigitalPin(a, greenLED, 0);
                writeDigitalPin(a, yellowLED, 1);
                writeDigitalPin(a, redLED, 0);
                fprintf('Warning: Temperature drops rapidly\n');
            else % temperature stabilization
                writeDigitalPin(a, greenLED, 1);
                writeDigitalPin(a, yellowLED, 0);
                writeDigitalPin(a, redLED, 0);
                fprintf('The temperature change is normal.\n');
            end
        end
        
        % Update the real-time curve
        set(hPlot, 'XData', timeStamps(1:i), 'YData', tempHistory(1:i));
        xlim([0 max(timeStamps)]);
        ylim([min(tempHistory(1:i))-2 max(tempHistory(1:i))+2]);
        drawnow;
        
        % sample interval
        pause(sampleInterval);
    end
    
    % Monitoring is completed. Turn off all leds
    writeDigitalPin(a, greenLED, 0);
    writeDigitalPin(a, yellowLED, 0);
    writeDigitalPin(a, redLED, 0);
end