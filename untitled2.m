% [~, ~, stages] = loadPSGAnnotationClass.testLoadCSV('configuration/mapping-CHAT.csv');
% disp(length(stages));
% stages

 annObj = loadPSGAnnotationClass('/Users/wei/Documents/MATLAB/ATestFiles/123CompumedicsSRO.xml');
 annObj = annObj.loadFile;
% disp(length(annObj.SleepStages));
 disp(length(annObj.ScoredEvent));
% disp(length(annObj.sleepStageValues));

% x = [2 2 32 32 2];
% y = [0 5 5 0 0];
% fill(x,y,'r','EdgeColor', 'r','FaceAlpha',0.5)