clc; clear; close all;

fis = mamfis('Name', 'Special Problem');

fis = addInput(fis, [0 60], 'Name', 'Queue');
fis = addMF(fis, 'Queue', 'trimf', [0 0 15], 'Name', 'Short');
fis = addMF(fis, 'Queue', 'trimf', [10 30 50], 'Name', 'Medium');
fis = addMF(fis, 'Queue', 'trimf', [40 60 60], 'Name', 'Long');

fis = addInput(fis, [0 40], 'Name', 'Arrival');
fis = addMF(fis, 'Arrival', 'trimf', [0 0 10], 'Name', 'Low');
fis = addMF(fis, 'Arrival', 'trimf', [5 20 35], 'Name', 'Medium');
fis = addMF(fis, 'Arrival', 'trimf', [30 40 40], 'Name', 'High');

fis = addInput(fis, [0 90], 'Name', 'Waiting');
fis = addMF(fis, 'Waiting', 'trimf', [0 0 25], 'Name', 'Short');
fis = addMF(fis, 'Waiting', 'trimf', [15 45 75], 'Name', 'Moderate');
fis = addMF(fis, 'Waiting', 'trimf', [60 90 90], 'Name', 'Long');

fis = addOutput(fis, [0 120], 'Name', 'TotalGreen');
fis = addMF(fis, 'TotalGreen', 'trapmf', [10 10 30 40], 'Name', 'Short');
fis = addMF(fis, 'TotalGreen', 'trapmf', [30 40 70 80], 'Name', 'Medium');
fis = addMF(fis, 'TotalGreen', 'trapmf', [60 80 120 120], 'Name', 'Long');

fis.DefuzzificationMethod = 'centroid';

fuzzyrules = [
    1 1 1 1; 1 1 2 1; 1 1 3 2;
    1 2 1 1; 1 2 2 2; 1 2 3 2;
    1 3 1 2; 1 3 2 2; 1 3 3 3;
    2 1 1 2; 2 1 2 2; 2 1 3 3;
    2 2 1 2; 2 2 2 2; 2 2 3 3;
    2 3 1 2; 2 3 2 3; 2 3 3 3;
    3 1 1 2; 3 1 2 2; 3 1 3 3;
    3 2 1 2; 3 2 2 3; 3 2 3 3;
    3 3 1 3; 3 3 2 3; 3 3 3 3
];

for i = 1:size(fuzzyrules, 1)
    fis = addRule(fis, [fuzzyrules(i,:) 1 1]);  
end

iterations = 5;
scenarios = 27;
leftshare = 0.2;  
queue_ranges = [0 15; 16 45; 46 60];      
arrival_ranges = [0 10; 11 30; 31 40];    
waiting_ranges = [0 20; 21 60; 61 90];
queue_label = {'Short', 'Medium', 'Long'};
arrival_label = {'Low', 'Medium', 'High'};
waiting_label = {'Short', 'Moderate', 'Long'};

results = table('Size', [0 12],...
    'VariableTypes', {'categorical', 'categorical', 'categorical', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'categorical', 'categorical'},...
    'VariableNames', {'QueueLevel', 'ArrivalLevel', 'WaitingLevel', 'Intersection', 'Queue', 'Arrival', 'Waiting', 'TotalGreen', 'Through', 'LeftTurn', 'First', 'Second'});

for s = 1:scenarios
    [W, A, Q] = ind2sub([3, 3, 3], s);

    for iter = 1:iterations
        QL_NS1 = randi(queue_ranges(Q, :));
        QL_EW1 = randi(queue_ranges(Q, :));
        AR_NS1 = randi(arrival_ranges(A, :));
        AR_EW1 = randi(arrival_ranges(A, :));
        WT_NS1 = randi(waiting_ranges(W, :));
        WT_EW1 = randi(waiting_ranges(W, :));
    
        if QL_NS1 >= QL_EW1
            First = 'NS'; 
            Second = 'EW';
            QL_first = QL_NS1; 
            AR_first = AR_NS1; 
            WT_first = WT_NS1;
            QL_second = QL_EW1; 
            AR_second = AR_EW1; 
            WT_second = WT_EW1;
        else
            First = 'EW'; 
            Second = 'NS';
            QL_first = QL_EW1; 
            AR_first = AR_EW1; 
            WT_first = WT_EW1;
            QL_second = QL_NS1; 
            AR_second = AR_NS1; 
            WT_second = WT_NS1;
        end
    
        TG_first = round(evalfis(fis,[QL_first AR_first WT_first]));
        LT_first = round(TG_first * leftshare);
        LT_first = max(LT_first, 3);
        TH_first = TG_first;
    
        TG_second = round(evalfis(fis,[QL_second AR_second WT_second]));
        LT_second = round(TG_second * leftshare);
        LT_second = max(LT_second, 3);
        TH_second = TG_second;
     
        results = [results; 
            {queue_label{Q}, arrival_label{A}, waiting_label{W}, 1, QL_first, AR_first, WT_first, TG_first, TH_first, LT_first, First, Second};
            {queue_label{Q}, arrival_label{A}, waiting_label{W}, 1, QL_second, AR_second, WT_second, TG_second, TH_second, LT_second, Second, First}];
       end
end

disp(results);

figure('Name','Traffic Signal Simulation (Intersection 1)','NumberTitle','off');
hold on;

intersection1 = results.Intersection == 1;

plot(find(intersection1), results.TotalGreen(intersection1),'b-o','LineWidth',1.5,'DisplayName','Total Green Intersection 1');
plot(find(intersection1), results.LeftTurn(intersection1),'b--s','LineWidth',1.5,'DisplayName','Left-Turn Intersection 1');

xlabel('Iteration');
ylabel('Time (seconds)');
title('Total Green and Left-Turn Allocation over Iterations');
legend('Location','best');
grid on;
hold off;

summary = varfun(@mean, results, ...
    'InputVariables', {'TotalGreen', 'LeftTurn'}, ...
    'GroupingVariables', {'QueueLevel', 'ArrivalLevel', 'WaitingLevel'});

summary.Properties.VariableNames{'mean_TotalGreen'} = 'AvgTotalGreen';
summary.Properties.VariableNames{'mean_LeftTurn'} = 'AvgLeftTurn';
summary.AvgTotalGreen = round(summary.AvgTotalGreen); 
summary.AvgLeftTurn  = round(summary.AvgLeftTurn);
disp(summary);
