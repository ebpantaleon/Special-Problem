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
leftshare = 0.2;  
queue_range = [0 60];      
arrival_lambda = 22;    
waiting_range = [0 90];    

results = table('Size', [0 10],...
    'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'categorical', 'categorical'},...
    'VariableNames', {'Iteration', 'Intersection', 'Queue', 'Arrival', 'Waiting', 'TotalGreen', 'Through', 'LeftTurn', 'First', 'Second'});

for iter = 1:iterations

    QL_NS1 = randi(queue_range); 
    QL_EW1 = randi(queue_range);
    AR_NS1 = poissrnd(arrival_lambda);
    AR_EW1 = poissrnd(arrival_lambda);
    WT_NS1 = randi(waiting_range);
    WT_EW1 = randi(waiting_range);
    
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
        {iter, 1, QL_first, AR_first, WT_first, TG_first, TH_first, LT_first, First, Second};
        {iter, 1, QL_second, AR_second, WT_second, TG_second, TH_second, LT_second, Second, First}];
    
    QL_NS2 = max(0, QL_NS1 - round(0.5*TG_first) + randi([-1 1]));
    QL_EW2 = max(0, QL_EW1 - round(0.5*TG_second) + randi([-1 1]));
    AR_NS2 = AR_NS1; 
    AR_EW2 = AR_EW1;
    WT_NS2 = max(0, WT_NS1 - round(0.3*TG_first) + randi([-2 2]));
    WT_EW2 = max(0, WT_EW1 - round(0.3*TG_second) + randi([-2 2]));

    if QL_NS2 >= QL_EW2
        First2 = 'NS'; 
        Second2 = 'EW';
        QL_first2 = QL_NS2; 
        AR_first2 = AR_NS2; 
        WT_first2 = WT_NS2;
        QL_second2 = QL_EW2; 
        AR_second2 = AR_EW2; 
        WT_second2 = WT_EW2;
    else
        First2 = 'EW'; 
        Second2 = 'NS';
        QL_first2 = QL_EW2; 
        AR_first2 = AR_EW2; 
        WT_first2 = WT_EW2;
        QL_second2 = QL_NS2; 
        AR_second2 = AR_NS2; 
        WT_second2 = WT_NS2;
    end

    TG_first2 = round(evalfis(fis,[QL_first2 AR_first2 WT_first2]));
    LT_first2 = round(TG_first2 * leftshare);
    LT_first2 = max(LT_first2, 3);
    TH_first2 = TG_first2;
  
    TG_second2 = round(evalfis(fis,[QL_second2 AR_second2 WT_second2]));
    LT_second2 = round(TG_second2 * leftshare);
    LT_second2 = max(LT_second2, 3);
    TH_second2 = TG_second2;

    results = [results;
        {iter, 2, QL_first2, AR_first2, WT_first2, TG_first2, TH_first2, LT_first2, First2, Second2};
        {iter, 2, QL_second2, AR_second2, WT_second2, TG_second2, TH_second2, LT_second2, Second2, First2}];
    
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

figure('Name','Traffic Signal Simulation (Intersection 2)','NumberTitle','off');
hold on;

intersection2 = results.Intersection == 2;

plot(find(intersection2), results.TotalGreen(intersection2),'r-o','LineWidth',1.5,'DisplayName','Total Green Intersection 2');
plot(find(intersection2), results.LeftTurn(intersection2),'r--s','LineWidth',1.5,'DisplayName','Left-Turn Intersection 2');

xlabel('Iteration');
ylabel('Time (seconds)');
title('Total Green and Left-Turn Allocation over Iterations');
legend('Location','best');
grid on;
hold off;