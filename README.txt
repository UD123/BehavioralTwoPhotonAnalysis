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
%       Special thanks for debugging - Jackie Schiller, Maria Lavzin, Liora Garion, Adam Hantman
%       Code contributions from:
%       1. Piotr Dollar toolbox for automatic classification of events.  
%       2. Image registration - Janelia code originally written by Sun Wenzhi, 8/28/2012 for Image Box SW. 
%          This code uses algorithms developed by Ann M. Kowalczyk and James R. Fienup in paper
%          J.R. Fienup and A.M. Kowalczyk, "Phase retrieval for a complex-valued object by using a low-resolution image," J. Opt. Soc. Am. A 7, 450-458, (1990).
% 		3. For the rest you can blame me Uri Dubin. 
%
% To Do List:
% 	1. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ver 	Date  		Who 	What
%==================================================
% 29.04 19.03.19    UD  	Gal event import fix
% 29.03 19.03.19    UD  	Multiple channels multiple slices support. Fixing bug in Event alignment.
% 29.02 10.10.18    UD  	Fix computer name change in Video Labeler.
% 29.01 26.09.18    UD  	Can load new system files.
% 28.28 14.08.18    UD  	Video Labeler - fixes.
% 28.27 25.07.18    UD  	Video Labeler - filtering of ROIs.
% 28.26 08.07.18    UD  	Video Labeler updates. Fixes for Shahar
% 28.25 04.07.18    UD  	Hadas Averaging is merged back from 2710.
% 28.24 27.06.18    UD  	VideoLabeler updates - training.
% 28.23 26.06.18    UD  	VideoLabeler updates.
% 28.22 13.06.18    UD  	Export to excel for Fadi.
% 28.21 06.06.18    UD  	Testing behavioral labeler again. Adding snippets.
% 28.20 28.05.18    UD  	Gal is coding.
% 28.19 24.05.18    UD  	Overlay of snippets. Merging with Gal.
% 28.18 09.05.18    UD  	Import from Labeler. Adding Scripts for Jackie
% 28.17 29.04.18    UD  	Export data from Labeler and fixes for Faddy
% 28.16 11.04.18    UD  	Trajectory tool improvement
% 28.15 01.04.18    UD  	Ethogram export
% 28.14 29.03.18    UD  	ElectroPhys for certain simple file and Averaging for Shahar.
% 28.13 19.03.18    UD  	ElectroPhys for Fadi.
% 28.12 08.03.18    UD  	Improving Behavioral analysis tool. Fadi behavioral offset by 20 frames.
% 28.11 04.03.18    UD  	Updates in technion
% 28.10 27.02.18    UD  	Running on bigger dataset
% 28.09 19.02.18    UD  	Integrating Matlab GUI for ROI labeling
% 28.08 09.02.18    UD  	DNN Heatmaps. Fixing selection for Fadi. Trajectory extraction.
% 28.07 30.01.18    UD  	Gals code integration
% 28.06 22.01.18    UD  	New dF/F for inhibition - multiple trials. Gal's code for detection of neurons.
% 28.05 19.01.18    UD  	New dF/F for inhibition
% 28.04 15.01.18    UD  	Fixing Excel export with names of trials and original brightness.
% 28.03 07.01.18    UD  	Fixing bugs in Import for Shahar.
% 28.02 03.01.18    UD  	Fixing Multitrial bugs for Fadi. Import timestamp mat files for Shahar.
% 28.01 28.12.17    UD  	Fadi two channel system import.
% 27.14 26.12.17    UD  	Fixing export to excel.
% 27.13 17.12.17    UD  	Event alignment threshold is lowered.
% 27.12 04.12.17    UD  	Working on trajectories.
% 27.11 22.11.17    UD  	Adding ROI tracking tool. Figures are left out.
% 27.10 08.11.17    UD  	Looking on averaged df/f and behavior traces
% 27.09 07.11.17    UD  	Analysis of averages
% 27.08 31.10.17    UD  	Fixing alignment tool - save image as tif. 
% 27.07 29.10.17    UD  	Fixing alignment tool. 
% 27.06 24.10.17    UD  	Adding alignment tool for ROIs. 
% 27.05 22.10.17    UD  	Trying to improve trajectories. 
% 27.04 22.10.17    UD  	Fixes for Pearson and cell selection. 
% 27.03 16.10.17    UD  	Developing cell detection using RCNN. Skip 2702 - at home
% 27.01 08.10.17    UD  	Cell detection RCNN
% 26.06 16.07.17    UD  	Improving clustering
% 26.05 12.07.17    UD  	Working with Jackie - improving trajectories
% 26.04 02.07.17    UD  	Browsing tool in Multitrial improved
% 26.03 19.06.17    UD  	Segmentation auto tools
% 26.02 13.06.17    UD  	MultuTrial Explorer - show cell 2D position.
% 26.01 06.06.17    UD  	SVD representation mutlitrial.
% 26.00 01.06.17    UD  	Import from Janelia image stack.
% 25.14 25.05.17    UD  	Adding noise of 10 to dFF in Image tool.
% 25.13 23.05.17    UD  	Adding tool Z stack fix.
% 25.12 18.05.17    UD  	Fixing bug in Event S+1. MaxTrialNum. Fixing merge bug
% 25.11 10.05.17    UD  	Event S+1. Moving some MultiTrialEvent files to MultiTrialEventManager.
% 25.10 04.05.17    UD  	Alignment tool for Z stacks. Fadi spike detector for all.
% 25.09 27.04.17    UD  	Detection of ROIs. Do not remove old events.
% 25.08 19.04.17    UD  	Memory of behavioral analysis improvement. Adding Manual event detect. 
% 25.07 09.04.17    UD  	JPCA. TBD.
% 25.06 05.04.17    UD  	Fixing behavioral show. 
% 25.05 03.04.17    UD  	Adding show fluorescence. Fadi - removing trend to detect long events. Filter MaxRespWidth 20.
%                           Faster behavioral data load
% 25.04 19.03.17    UD  	Events Behavior debug.
% 25.03 14.03.17    UD  	Events Behavior.
% 25.02 07.03.17    UD  	Merging with 24.17. Working on events construction.
% 25.01 06.02.17    UD  	Behavior Analysis as events. Jaaba merge option.
% 24.12 22.11.16    UD  	bug fix from Shahar. 
% 24.11 15.11.16    UD  	Updates from Jackie.
% 24.10 12.11.16    UD  	Rechecking Behavioral Events in Multi Experiment processing. MinFluorescentLevel     = 20
% 24.09 08.11.16    UD  	Adding ROI size rescaling and Multi Experiment processing
% 24.08 01.11.16    UD  	Fixing Bug with Time rescaling
% 24.07 26.10.16    UD  	Fixing Electro Phys import for Fadi
% 24.06 16.10.16    UD  	Support Bahavior 200Hz and Image Rate 30 - not an even number.
% 24.05 12.09.16    UD  	Adding registration.
% 24.04 06.09.16    UD  	Debug in the Lab. Fixing counter.
% 24.03 02.09.16    UD  	Debugging data manager in memory and session
% 24.02 23.08.16    UD  	Adding data manager in memory and session
% 23.21 23.08.16    UD  	Fixing bugs for Fadi flow
% 23.20 23.08.16    UD  	Merging between home and technion
% 23.19 22.08.16    UD  	Anchor alignment tool continued
% 23.18 10.08.16    UD  	Anchor alignment tool,  X for Fadi. ROI Counter fix.
% 23.17 05.07.16    UD  	Testing for Fadi - Cross correlation.
% 23.16 14.06.16    UD  	Data management file for Prarie directory. Matrix registration improved.
% 23.15 31.05.16    UD  	Releasing Prarie directory. 
% 23.14 21.05.16    UD  	Improving ROI snap to fluorescence. Add Effective ROI contour to ROI manager.
% 23.13 03.05.16    UD  	Manual Spikes editor save is fixed.
% 23.12 19.04.16    UD  	Manual Spikes editor has meaningful height.
% 23.11 05.04.16    UD  	Changing dF/F computation in TP viewer. Changing dF/F bias term to 10.
% 23.10 29.03.16    UD  	Spike detector editor.
% 23.09 21.03.16    UD  	Working to snap ROIs to cells.
% 23.08 15.03.16    UD  	Yael bug resolved.
% 23.07 01.03.16    UD  	Small problems in Multi Group Views.
% 23.06 23.02.16    UD  	Working with delays and spikes
% 23.05 17.02.16    UD  	Adding Maria graphs
% 23.04 16.02.16    UD  	Merging with technion version, fixing bugs
% 23.03 14.02.16    UD  	Adding Maria sort view and save spikes per ROI from Editor 
% 23.02 06.02.16    UD  	Debug roi class 
% 23.01 26.01.16    UD  	Merging with 2204 and also continue to debug
% 23.00 19.01.16    UD  	Debugging Porting Rois to Class 
% 22.03 12.01.16    UD  	Porting Rois to Class 
% 22.02 12.01.16    UD  	Bugs in Liora Prarie flow 
% 22.01 05.01.16    UD  	Liora place
% 22.00 05.01.16    UD  	Rearranging electro phys management path. Supports piezo angle decode.
% 21.23 04.01.16    UD  	Liora Load and Bug Merge, Classifier Editor, etc
% 21.22 29.12.15    UD  	Working on Prarie Stimulus load,Overlay of Spikes and Event Sequence filter.
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
