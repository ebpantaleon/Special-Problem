clc; clear; close all;

startTime = datetime(2025,12,11,0,0,0);
endTime   = datetime(2025,12,12,0,0,0);
timeSteps = startTime:minutes(30):endTime;
iterations = numel(timeSteps);

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

leftshare = 0.2;
queue_range = [0 60];     
waiting_range = [0 90];   
results = table('Size',[0 10],...
    'VariableTypes',{'datetime','double','double','double','double','double','double','double','categorical','categorical'},...
    'VariableNames',{'Time','Intersection','Queue','Arrival','Waiting','TotalGreen','Through','LeftTurn','First','Second'});

for t = 1:iterations
    currentTime = timeSteps(t);
    tdec = hour(currentTime) + minute(currentTime)/60;

    if (hour(currentTime) >= 0 && hour(currentTime) < 5) || (hour(currentTime) >= 22 && hour(currentTime) <= 23)
        lambda = 3;                      
        QL_NS1 = poissrnd(1);            
        QL_EW1 = poissrnd(1);
        WT_NS1 = round(rand*2);                 
        WT_EW1 = round(rand*2);

    elseif (tdec >= 7 && tdec < 9) || (tdec >= 17 && tdec < 21)
        lambda = 50;                     
        QL_NS1 = max(0, round(normrnd(60,20))); 
        QL_EW1 = max(0, round(normrnd(60,20)));
        WT_NS1 = randi([25 90]);         
        WT_EW1 = randi([25 90]);
    else
        lambda = 15;                    
        QL_NS1 = randi(queue_range);
        QL_EW1 = randi(queue_range);
        WT_NS1 = randi(waiting_range);
        WT_EW1 = randi(waiting_range);
    end

   AR_NS1 = poissrnd(lambda);
   AR_EW1 = poissrnd(lambda);

   AR_NS1 = max(min(AR_NS1,40),0);
   AR_EW1 = max(min(AR_EW1,40),0);
   QL_NS1 = max(min(QL_NS1,60),0);
   QL_EW1 = max(min(QL_EW1,60),0);
   WT_NS1 = max(min(WT_NS1,90),0);
   WT_EW1 = max(min(WT_EW1,90),0);

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

    TG_first = round(evalfis(fis, [QL_first, AR_first, WT_first]));
    TG_second = round(evalfis(fis, [QL_second, AR_second, WT_second]));
    LT_first = max(round(TG_first * leftshare), 3);
    LT_second = max(round(TG_second * leftshare), 3);
    TH_first = TG_first;
    TH_second = TG_second;

    results = [results;
        {currentTime, 1, QL_first, AR_first, WT_first, TG_first, TH_first, LT_first, First, Second};
        {currentTime, 1, QL_second, AR_second, WT_second, TG_second, TH_second, LT_second, Second, First}];

    served_factor = 0.5; 
    QL_NS2 = max(0, QL_NS1 - round(served_factor * TG_first*(strcmp(First,'NS') + 0*strcmp(Second,'NS'))) ...
                    - round(served_factor * TG_second*(strcmp(Second,'NS') + 0*strcmp(First,'NS'))) + randi([-2 2]));
    QL_EW2 = max(0, QL_EW1 - round(served_factor * TG_first*(strcmp(First,'EW') + 0*strcmp(Second,'EW'))) ...
                    - round(served_factor * TG_second*(strcmp(Second,'EW') + 0*strcmp(First,'EW'))) + randi([-2 2]));

    AR_NS2 = AR_NS1;
    AR_EW2 = AR_EW1;
    WT_NS2 = max(0, WT_NS1 - round(0.2*TG_first) + randi([-3 3]));
    WT_EW2 = max(0, WT_EW1 - round(0.2*TG_second) + randi([-3 3]));

    QL_NS2 = max(min(QL_NS2,160),0);
    QL_EW2 = max(min(QL_EW2,160),0);
    WT_NS2 = max(min(WT_NS2,90),0);
    WT_EW2 = max(min(WT_EW2,90),0);

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

    TG_first2 = round(evalfis(fis, [QL_first2, AR_first2, WT_first2]));
    TG_second2 = round(evalfis(fis, [QL_second2, AR_second2, WT_second2]));
    LT_first2 = max(round(TG_first2 * leftshare), 3);
    LT_second2 = max(round(TG_second2 * leftshare), 3);
    TH_first2 = TG_first2;
    TH_second2 = TG_second2;

    results = [results;
        {currentTime, 2, QL_first2, AR_first2, WT_first2, TG_first2, TH_first2, LT_first2, First2, Second2};
        {currentTime, 2, QL_second2, AR_second2, WT_second2, TG_second2, TH_second2, LT_second2, Second2, First2}];

end

disp(results);

times = unique(results.Time);
int1 = results.Intersection == 1;
int2 = results.Intersection == 2;

figure('Name','Intersection 1 - Total Green & Left Turn','NumberTitle','off');
subplot(2,1,1);
plot(results.Time(int1), results.TotalGreen(int1), '-o', 'LineWidth',1.2);
xlabel('Time'); 
ylabel('Total Green (sec)'); 
title('Intersection 1: Total Green Time');
grid on;

subplot(2,1,2);
plot(results.Time(int1), results.LeftTurn(int1), '--s', 'LineWidth',1.2);
xlabel('Time'); 
ylabel('Left Turn (sec)'); 
title('Intersection 1: Left-Turn Green Time');
grid on;

figure('Name','Intersection 2 - Total Green & Left Turn','NumberTitle','off');
subplot(2,1,1);
plot(results.Time(int2), results.TotalGreen(int2), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Total Green (sec)'); title('Intersection 2: Total Green Time');
grid on;

subplot(2,1,2);
plot(results.Time(int2), results.LeftTurn(int2), '--s', 'LineWidth',1.2);
xlabel('Time'); ylabel('Left Turn (sec)'); title('Intersection 2: Left-Turn Green Time');
grid on;

figure('Name','Queue Length over Time','NumberTitle','off');
subplot(2,1,1);
plot(results.Time(int1), results.Queue(int1), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Queue Length (veh)'); title('Intersection 1: Queue Length');
grid on;

subplot(2,1,2);
plot(results.Time(int2), results.Queue(int2), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Queue Length (veh)'); title('Intersection 2: Queue Length');
grid on;

figure('Name','Arrival Rate over Time','NumberTitle','off');
subplot(2,1,1);
plot(results.Time(int1), results.Arrival(int1), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Arrival Rate (veh/min)'); title('Intersection 1: Arrival Rate');
grid on;

subplot(2,1,2);
plot(results.Time(int2), results.Arrival(int2), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Arrival Rate (veh/min)'); title('Intersection 2: Arrival Rate');
grid on;

figure('Name','Waiting Time over Time','NumberTitle','off');
subplot(2,1,1);
plot(results.Time(int1), results.Waiting(int1), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Waiting Time (sec)'); title('Intersection 1: Waiting Time');
grid on;

subplot(2,1,2);
plot(results.Time(int2), results.Waiting(int2), '-o', 'LineWidth',1.2);
xlabel('Time'); ylabel('Waiting Time (sec)'); title('Intersection 2: Waiting Time');
grid on;