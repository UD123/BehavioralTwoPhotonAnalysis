% TPA_TestDataManager
% Performs test of data managing objects
% Inputs:
%       none
% Outputs:
%        side effect directories updated

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 16.03 16.02.14 UD     created
%-----------------------------
clear all

testType = 2;

%%%
% Testing Behavior
%%%
dm = TPA_DataManagerBehavior('DecimationFactor',[2 2 1 1]);
switch testType
    case 1,
        dm.TestSelect();
    case 2,
        dm.TestLoad();
    case 3,
        dm.TestAnalysis();
    otherwise
        disp('Skipping Behavior Tests')
end


%%%
% Testing TwoPhoton
%%%
sm = TPA_DataManagerTwoPhoton();

switch testType
    case 11,
        sm.TestSelect();
    case 12,
        sm.TestLoad();
    case 13,
        sm.TestAnalysis();
    otherwise
        disp('Skipping TwoPhoton Tests')
end