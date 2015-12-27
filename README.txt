% This Readme file describes version and operation instructions for
% Two Photon and Behavioral analysis tools.
% 
% User Manual : 
%       .\Doc\TwoPhotonAnalysis UserGuide.docx
%
% To start: 
%       run TPA_MainGUI   - gui mode
%
% Acknowledgements:
%       Special thanks for debugging - Jackie Schiller, Maria Lavzin, Lira Garion, Adam Hantman
%       Code contributions from:
%       1. Piotr Dollar toolbox for automatic classification of events.  
%       2. Image registration - Janelia code originally written by Sun Wenzhi, 8/28/2012 for Image Box SW. 
%          This code uses algorithms developed by Ann M. Kowalczyk and James R. Fienup in paper
%          J.R. Fienup and A.M. Kowalczyk, "Phase retrieval for a complex-valued object by using a low-resolution image," J. Opt. Soc. Am. A 7, 450-458, (1990).
% 	3. For the rest you can blame me Uri Dubin. 
%
% Compile Piotr Dollar toolbox:
% 	If you need to use automatic event detection tool you may need to compile Piotr Dollar toolbox
% 	for your specific platform. The actions to be taken:
% 		1. Make sure that you have a compiler (install for Win 7 :http://www.microsoft.com/en-us/download/details.aspx?id=8442)     
% 		2. In Matlab using mex -setup select the compiler 
% 		(On certain 64 bit windows 7 machines there are no compilers installed. You need to install Windows SDK and .Net 4. However, if Windows SDK fails to install
% 		You need to extract SDK 7 and go to ..\GRMSDKX_EN_DVD\Setup\WinSDKNetFxTools_amd64 directory and run the msi. Then select Repair option and select all other utilities.
%       	You also may need to disable command %useOmp([6 9])=1; in toolboxCompile.m file )
% 		3. Switch to the folder piotr_toolbox_V3.25 and run command addpath(genpath('.'))
% 		4. Run command : toolboxCompile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ver 	Date  		Who 	What
%==================================================
% 21.21 15.12.15    UD  	Integrating with Previous version of the Prarie Stimulus load. Fixes in spike display. 
% 21.20 10.12.15    UD  	fixing bugs liora. 
% 21.19 08.12.15    UD  	PSTH analysis bug fixing. Adding dF/F with bias. 
% 21.18 01.12.15    UD  	Testing with Liora
% 21.17 20.11.15    UD  	Bugs solving - Jackie
% 21.16 26.11.15    UD  	z-stack fixes. recheck ROIs
% 21.15 24.11.15    UD  	Fixing ROI assign bug
% 21.14 24.11.15    UD  	Event Order additions. MTExplorer Config Spike detect.
% 21.13 24.11.15    UD  	Tool for ROI movement - rot and scale.
% 21.12 18.11.15    UD  	Fixing prarie load.
% 21.11 17.11.15    UD  	Comments on ROI naming.
% 21.10 10.11.15    UD  	Fixing empty prarie directories.
% 21.09 03.11.15    UD  	Working with Liora on Bugs.
% 21.08 20.10.15    UD  	Fixing bugs for prarie system.
% 21.07 13.10.15    UD  	Event detection - fixes.
% 21.06 10.10.15    UD  	Event detection - manula configuration for Itsik.
% 21.05 08.09.15    UD  	Which score to import for Maria - predicted or manual.
% 21.04 25.08.15    UD  	ROi artifact removal for Itsik.
% 21.03 25.08.15    UD  	Shifting ROIs according to Z stack.
% 21.02 18.08.15    UD  	Mergin event class to behavior editor from 2101. Moving files around.
% 20.13 18.08.15    UD  	Categorization of the ROIs.
% 20.12 28.07.15    UD  	Session : save / load experiment data. Cross probing in MultiTrial.
% 20.11 28.07.15    UD  	Testing and doing video analysis. File CSV debug.
% 20.10 24.07.15    UD  	Merging
% 20.09 21.07.15	UD 	Skipping previous versions. MAC xls save resolve.
% 20.08 15.07.15	UD 	Overlay TP on Video data.
% 20.07 28.05.15	UD 	Fixing delay for continuous traces.
% 20.06 22.05.15	UD 	Trajectory is differential. Fixing Prarie interface.
% 20.05 19.05.15	UD 	Checking if it is possible do not use EventList object.
% 20.04 17.05.15	UD 	Merging with 2003 - continuous events.
% 19.32 10.05.15	UD 	Optical flow visualization.
% 19.31 07.05.15	UD 	Testing and working on complex events.
% 19.30 05.05.15	UD 	Debugging traces. Func Reconstruction.
% 19.29 01.05.15	UD 	Working on complicated search events and addind cell functional reconstruction tool.
% 19.28 24.04.15	UD 	Creating complicated search events. Fixing Time when Number of Slices is used
% 19.27 21.04.15	UD 	Working with Maria and fixing bugs
% 19.26 18.04.15	UD 	ToDo list: ROI from different z stacks
% 19.25 10.03.15	UD 	Bug fixing - integration with Prarie.
% 19.24 23.02.15	UD 	Working on trajectory integration. Adding Event management in XY view.
% 19.23 17.02.15	UD 	Testing delay view. Integrating trajectories.
% 19.22 12.02.15	UD 	Creating cell activity delay view.
% 19.21 20.01.15	UD 	Problems with XLS dir structure to CSV - MAC compatability issues. MultiTrial - adding 2 cursors.
% 19.20 13.01.15	UD 	Trying to do motion analysis.
% 19.19 11.01.15	UD 	Merging 19.18 in the lab. Fixing bugs with multi stack registration.
% 19.17 30.12.14	UD 	Trajectory for behavioral. Adding ROI position adjustment tool.
% 19.16 23.12.14	UD 	Fixing dF/F and Event insertion when no events found. Group does not work. Multiplain registration.
% 19.15 18.12.14	UD 	Adding dF/F for XY and Cursors
% 19.14 18.11.14	UD 	Working on training and MultiGroupExplorer
% 19.13 04.11.14	UD 	Multitrial explorer - adding color selection and save screeen as images as jpg/....
% 19.12 21.10.14	UD 	Merging with 1909. Fixes and bugs.
% 19.11 16.10.14	UD 	Skipping version in the Lab. Adding group definition using Kulback-Leibler conditioned on event. 
% 19.08 07.10.14	UD 	Updates for Ronen - Event counting. Adding Tone/Table event insertion. Directory rename.
% 19.07 03.10.14	UD 	Testing different bugs. Trying to load analysis data only.
% 19.06 21.09.14	UD 	Adding import to movie_comb.avi file from new JAABA_multi SW
% 19.05 11.09.14	UD 	Fixing bug with event load. Inconsistent file end fix.
% 19.04 12.08.14	UD 	Continue to work on Adams interface. ROI selection is working.
% 19.03 07.08.14	UD 	Adding check ShiftNum and Image Num
% 19.02 05.08.14	UD 	Testing multiple stack ROIs - working. Trying to integrate with JAABA explorer.
% 19.01 11.07.14	UD 	New data base management using excel. Skipping version 1900 that contains ElectroPhysiology IF Integration.
% 18.13 10.07.14	UD 	Simon code for line correlation. Smart query for Explorer.
% 18.12 09.07.14	UD 	Check Pointing. Adding Excel import tool with columns.
% 18.11 08.07.14	UD 	Adding Multi Experiment Tool. procROI data disappears when you touch ROI.
% 18.10 08.07.14	UD 	Check pointing.
% 18.09 06.07.14	UD 	Back to Janelia. Analysis only support.
% 18.08 24.06.14	UD 	Event auto detect continue. Try to compile the toolbox. B. Event bug fixes. 
% 18.07 20.05.14	UD 	trying to open old Two Phton data from the Lab 
% 18.06 14.05.14	UD 	ROI set movement in dx,dy 
% 18.05 30.04.14	UD 	Event auto detect.
% 18.04 26.04.14	UD 	Behavior Event auto detect. read Jaaba Excel. Fix bug in Jaaba Load.
% 18.03 25.04.14	UD 	Rename to Analysis.
% 18.02 22.04.14	UD 	Testing and bringing debug info from m17.11.
% 18.01 13.04.14	UD 	Integrating in one GUI.
% 18.00 08.04.14	UD 	Adding ElectroPhysiology data analysis support .
% 17.09 07.04.14	UD 	dF/F - 10% min and 10% min continuous.
% 17.08 05.04.14	UD 	Reshecking ROI problems. Synthetic data gen. Bug found in ROI index exoprt.
% 17.07 02.04.14	UD 	Adding debug info for jackie's auto detect error
% 17.06 27.03.14	UD 	Auto Detect
% 17.05 22.03.14	UD 	Cell Auto Detect and Multi Explorer Fixes
% 17.04 21.03.14	UD 	Working on registration
% 17.03 12.03.14	UD 	Checking registration
% 17.02 10.03.14	UD 	Working on cell detection. MEanwhile all cells are projected on all times in all trials.
% 17.01 06.03.14	UD 	Improve search in Trial Explorer.
% 17.00 04.03.14	UD 	Changing ROI display.Send to Jackie.
% 16.26 02.03.14	UD 	Working on file rename utility. Adding x pos indicators.
% 16.25 27.02.14	UD 	Adding Ytzhak/Slice file load.
% 16.24 27.02.14	UD 	Integrating pulse detection with dF/F. Fixing bugs
% 16.23 26.02.14	UD 	Trying to resolve.
% 16.22 26.02.14	UD 	Improvements in MultiTrial. Event problems are still not resolved.
% 16.21 26.02.14	UD 	Session management is according to experiment. Counters are atatched to the session.
% 16.20 26.02.14	UD 	Working on Explorer. Clear all at the start.
% 16.19 25.02.14	UD 	Backup Jackie
% 16.18 25.02.14	UD 	Still working on Multi dF/F and TrialExplorer. Fixing Z stack management and ROI over Z
% 16.17 25.02.14	UD 	Adding Trial Explorer.Working on 2 Z stacks. Adding counter of rois and events.
% 16.16 24.02.14	UD 	Improving user experience and fixing info delete.
% 16.15 24.02.14	UD 	Starting Multi Trial
% 16.14 23.02.14	UD 	ROI Analysis done
% 16.13 23.02.14	UD 	Continue to TwoPhoton full analysis. Solving some Save and Load problems - TESTED OK
% 16.12 22.02.14	UD 	Bringing in ROI class - small changes 
% 16.11 22.02.14	UD 	Testing. Working on Bugs
% 16.10 21.02.14	UD 	Single ROI first - talking with Jackie.
% 16.09 21.02.14	UD 	Check point. Tiff warning is fixed. 4 Windows are working for position.
% 16.08 20.02.14	UD 	Window sync - not working good.
% 16.07 20.02.14	UD 	rename views got confused of the naming. Adding resolution support. Registration is working.
% 16.06 19.02.14	UD 	ROI management revisited.
% 16.05 18.02.14	UD 	Fixing Jackies bugs. Working on sync.
% 16.04 17.02.14	UD 	Check point. 1603 - Version for Jackie & Oded. Working on Sync issues. Adding Decimation and Registration.
% 16.03 16.02.14	UD 	Check point. Adding data alignment GUI
% 16.02 15.02.14	UD 	Restructuring.Time Explorer GUI created.
% 16.01 14.02.14	UD 	Continue to develop. Changing period to repeat.
% 16.00 13.02.14	UD 	Interface to Janelia Data.
% 15.01 06.02.14	UD 	Working on Email comments. Editor from Liora TSeries.
% 15.00 16.01.14	UD 	Integrating New ROI Editor.
% 14.01 28.12.13	UD 	Improving browsing and ROI editing.
% 14.00 22.12.13	UD 	Rename for Janelia only. Working on email notes.
% 13.03 19.12.13	UD 	Testing.
% 13.02 26.11.13	UD 	ROI and Janelia integration..
% 13.01 10.11.13	UD 	Rename again to TSeries and working on ROI. Adding janelia support.
% 13.00 03.11.13	UD 	Rename AnalysisROI and adding new ROI management
% 12.01 14.09.13	UD 	Continue on Z stack
% 12.00 03.09.13	UD 	Working on Z Stack
% 11.11 01.09.13	UD 	Align versions
% 11.10 31.08.13	UD 	ROI Bugs
% 11.09 20.08.13	UD 	More "Improvements"
% 11.08 13.08.13	UD 	Improvements
% 11.07 06.08.13	UD 	Red Channel
% 11.06 06.08.13	UD 	bug Fix in ROI
% 11.05 30.07.13	UD 	multiple sync options
% 11.04 23.07.13	UD 	new day same sheet
% 11.03 15.07.13	UD 	fixing bugs
% 11.02 15.07.13	UD 	adding more features
% 11.01 09.07.13	UD 	improving
% 11.00 08.07.13	UD 	restructuring and major update
% 10.11 07.07.13	UD 	Implementing Doc from Maria and Jackie
% 10.10 02.07.13	UD 	Updating ROI processing
% 10.09 30.06.13	UD 	ROI handling cont
% 10.08 29.06.13	UD 	Big ROI data filtering
% 10.07 25.06.13	UD 	interfaces updates
% 10.06 25.04.13	UD 	Image load stack - T is the last dimension
% 10.05 23.04.13	UD 	Improving 3D representation
% 10.04 08.04.13	UD 	Multiple ROI and Z stack handling
% 10.03 12.03.13	UD 	Farther development
% 10.02 12.03.13	UD 	Adding GUI to explore the dataset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
