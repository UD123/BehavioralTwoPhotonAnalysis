classdef TPA_MultiExperimentFunctionalReconstruction
    % TPA_MultiExperimentFunctionalReconstruction - Collects TwoPhoton info of all ROIs from multiple experiments
    % and performs functional correlation between different Z - stacks to identify similar ROIs.
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 19.30 05.05.15 UD     Functional reconstruction
    % 19.29 01.05.15 UD     Created from Omri Barak TPA_corr2
    %-----------------------------
    properties (Constant)
        PIX2UM              = 1;  % transform pixels to um
        NEURON2UM           = 10;  % cell radius in um
    end
    
    properties
        
        % Experiment Setup
        AnalysisDir         % cell array of all experiments
        AnalysisDepth       % description of the depth for each z-stack
        
        % All data container
        AnalysisStr         % Contains, dFF Data, Trials and ROI info 
        
        
        
        
    end % properties
    properties (SetAccess = private)
    end

    methods
        
        % ==========================================
        function obj = TPA_MultiExperimentFunctionalReconstruction()
            % TPA_MultiExperimentFunctionalReconstruction - constructor
            % Input:
            %    -
            % Output:
            %     default values
        end
        
        
        % ==========================================
        function obj = LoadSingleExperiment(obj, expId) 
           % LoadSingleExperiment - loads single experiment data
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to load
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;

            % checks
            expNum      = length(obj.AnalysisDir);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less than expNum');
            
            % xcorr2 code
            analysisDir         = obj.AnalysisDir{expId};
            
            % Load Two Photon ROI data
            fileNames           = dir(fullfile(analysisDir,'TPA_*.mat'));
            fileNum             = length(fileNames);
            if fileNum < 1,
                error('TwoPhoton : Can not find data files in the directory %s. Check file or directory names.',analysisDir);
            end;
            [fileNamesRoi{1:fileNum,1}] = deal(fileNames.name);
            fileNumRoi                  = fileNum;

            allTrialRois                    = {}; count = 0; %cell(fileNumRoi,1);
            for trialInd = 1:fileNumRoi,
                fileToLoad                 = fullfile(analysisDir,fileNamesRoi{trialInd});
                usrData                    = load(fileToLoad);
                % bad trial
                if length(usrData.strROI{1}.procROI) < 1, continue; end;
                count                      = count + 1;
                allTrialRois{count}        = usrData.strROI;
            end


            % Flatten
            nTrials     = length(allTrialRois);
            nROI        = length(allTrialRois{1});
            nTime       = length(allTrialRois{end}{1}.procROI);
            dataRoi     = nan(nTime, nTrials,nROI);
            namesRoi    = cell(1,nROI);
            xyzPos      = zeros(nROI,3);
            % extract all the data
            for i=1:nROI
                for j=1:nTrials
                    a = allTrialRois{j}{i}.procROI;
                    if ~isempty(a)
                        dataRoi(:,j,i)=a;
                    end
                end
                % last trial
                namesRoi{i}     = allTrialRois{1}{i}.Name;
                xyzPos(i,1:2)   = mean(allTrialRois{1}{i}.xyInd);   
                xyzPos(i,3)     = allTrialRois{1}{i}.zInd;
            end
%             zInd    = nan(nROI,1);
%             for j = 1:nROI,
%                 zInd(j) = allTrialRois{1}{j}.zInd;
%             end
%             I1 = find(zInd==1);
%             I2 = find(zInd==2);

            %dataRoi     = reshape( dataRoi, nROI, nTime*nTrials )';
            %badId       = find( any(isnan(dataRoi),2) );
            dataRoi     = reshape( dataRoi, nTime*nTrials,nROI);
            badId       = find( any(isnan(dataRoi),1) );
            assert(isempty(badId),'Should not have a bad data');
            
            [p,f] = fileparts(analysisDir);
            
            % save
            obj.AnalysisStr{expId}.DffData  = dataRoi;
            obj.AnalysisStr{expId}.PosXYZ   = xyzPos;
            obj.AnalysisStr{expId}.RoiNames = namesRoi;
            obj.AnalysisStr{expId}.ExpName  = f;

        end
        
        % ==========================================
        function obj = FunctionalExperimentCorrelation(obj, expId, figNum) 
           % FunctionalExperimentCorrelation - functional correlation between experiment data
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to correlate with expId+1
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 103; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less or equal expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId+0}),'Current Experiment data is not loaded');
            
            % select appropriate Z indexes
            zCurrInd            = obj.AnalysisStr{expId+0}.PosXYZ(:,3);
            
            % may be an opposite order
            indCurr             = find(zCurrInd==1);
            indNext             = find(zCurrInd==2);
%             indCurr             = 1:length(zCurrInd); % find(zCurrInd==1);
%             indNext             = 1:length(zNextInd); %find(zNextInd==2);

            % check again
            assert(~isempty(indCurr),  'Current Experiment data does not have z index 1');
            assert(~isempty(indNext),  'Current Experiment data does not have z index 2');
            
            % select data
            dataCurr            = obj.AnalysisStr{expId+0}.DffData(:,indCurr);
            dataNext            = obj.AnalysisStr{expId+0}.DffData(:,indNext);
            
%             % equalize rows
%             minRowNum           = min(size(dataCurr,1),size(dataNext,1));
%             dataCurr            = dataCurr(1:minRowNum,:);
%             dataNext            = dataNext(1:minRowNum,:);
            
%             % debug - show side by side
%             figure(101),imagesc(dataCurr);title('Curr')
%             figure(102),imagesc(dataNext);title('Next')

            expNameCurr        = obj.AnalysisStr{expId+0}.ExpName;
            %expNameNext        = obj.AnalysisStr{expId+1}.ExpName;
            
            
            % do the correlation
            %[c,p]               = corrcoef( obj.AnalysisStr{expId}.DffData(:,indCurr),obj.AnalysisStr{expId+1}.DffData(:,indNext));
            [corrData ,p]        = corrcoef([dataCurr,dataNext]);
            %[c ,lag]              = xcov( dataCurr,dataNext,20,'coeff');
            
            % extract correlation data
            corrData            = corrData - diag(diag(corrData));
            corrThr             = 0.8;
            % current inside
            [currInd,nextInd]   = find(corrData > corrThr);
            %currInternalLink    = [posXYZCurr(currInd,:) posXYZCurr(nextInd,:)]';
            

            % save
            obj.AnalysisStr{expId}.CorrData  = corrData;
            obj.AnalysisStr{expId}.CurrIndZ1 = indCurr;
            obj.AnalysisStr{expId}.CurrIndZ2 = indNext;
            obj.AnalysisStr{expId}.CurrIndF  = (currInd);
            obj.AnalysisStr{expId}.NextIndF  = (nextInd);
            
            
            if figNum < 1, return; end
            
            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            imagesc(corrData);
            title(sprintf('Correlation Map of %s. Click on the image to see the traces.',expNameCurr),'interpreter','none');
            xlabel('ROIs from Z = 2'),ylabel('ROIs from Z = 1')
            colormap(jet)
            hFig1 = gcf;
            % install user click
            UD.expId    = expId;
            UD.dataCurr = dataCurr;
            UD.dataNext = dataNext;
            set(hFig1,'UserData',UD,'WindowButtonDownFcn',@(s,e)ShowTraces(obj,s,e));% store new update

        end
        
        % ==========================================
        function obj = FunctionalExperimentCorrelationDual(obj, expId, figNum) 
           % FunctionalExperimentCorrelation - functional correlation between experiment data
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to correlate with expId+1
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 103; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum > expId ,'expId must be less than expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId+0}),'Current Experiment data is not loaded');
            assert(~isempty(obj.AnalysisStr{expId+1}),'Next Experiment data is not loaded');
            
            % select appropriate Z indexes
            zCurrInd            = obj.AnalysisStr{expId+0}.PosXYZ(:,3);
            zNextInd            = obj.AnalysisStr{expId+1}.PosXYZ(:,3);
            
            % may be an opposite order
%             indCurr             = find(zCurrInd==1);
%             indNext             = find(zNextInd==2);
            indCurr             = 1:length(zCurrInd); % find(zCurrInd==1);
            indNext             = 1:length(zNextInd); %find(zNextInd==2);

            % check again
            assert(~isempty(indCurr),  'Current Experiment data does not have z index 2');
            assert(~isempty(indNext),  'Next Experiment data does not have z index 1');
            
            % select data
            dataCurr            = obj.AnalysisStr{expId+0}.DffData(:,indCurr);
            dataNext            = obj.AnalysisStr{expId+1}.DffData(:,indNext);
            
            % equalize rows
            minRowNum           = min(size(dataCurr,1),size(dataNext,1));
            dataCurr            = dataCurr(1:minRowNum,:);
            dataNext            = dataNext(1:minRowNum,:);
            
%             % debug - show side by side
%             figure(101),imagesc(dataCurr);title('Curr')
%             figure(102),imagesc(dataNext);title('Next')

            expNameCurr        = obj.AnalysisStr{expId+0}.ExpName;
            expNameNext        = obj.AnalysisStr{expId+1}.ExpName;
            
            
            % do the correlation
            %[c,p]               = corrcoef( obj.AnalysisStr{expId}.DffData(:,indCurr),obj.AnalysisStr{expId+1}.DffData(:,indNext));
            [c ,p]              = corrcoef( [dataCurr,dataNext]);
            %[c ,lag]              = xcov( dataCurr,dataNext,20,'coeff');

            % save
            obj.AnalysisStr{expId}.CorrData  = c;
            
            if figNum < 1, return; end
            
            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            imagesc(c);
            title(sprintf('Correlation Map between %s and %s. Click on the image to see the traces.',expNameCurr,expNameNext),'interpreter','none');
            xlabel('All ROIs from 2 groups'),ylabel('All ROIs from 2 groups')
            colormap(jet)
            hFig1 = gcf;
            % install user click
            UD.expId    = expId;
            UD.dataCurr = dataCurr;
            UD.dataNext = dataNext;
            set(hFig1,'UserData',UD,'WindowButtonDownFcn',@(s,e)ShowTracesDual(obj,s,e));% store new update

        end
         
        % ==========================================
        function obj = ShowTraces(obj,  src, e)
            % ShowTraces - a callback
            % Shows traces on the figure
            hFig = src;
            if ~strcmp(get(src,'SelectionType'),'normal'), return; end;
            %set(src,'pointer','circle')
            cp = get(gca,'CurrentPoint');
            xinit = round(cp(1,1));
            yinit = round(cp(1,2));
            XLim = get(gca,'XLim'); YLim = get(gca,'YLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % estimate where
                        
            UD             = get(hFig,'UserData');
            [nR,nCurrRois] = size(UD.dataCurr);
            [nR,nNextRois] = size(UD.dataNext);
            expId          = UD.expId;
            
%             % check
%             xinit           = max(1,min(nNextRois,xinit));
%             yinit           = max(1,min(nCurrRois,yinit));
            
            
            % extract traces
            if xinit > nCurrRois,
                xinit  = xinit - nCurrRois;
                trace1 = UD.dataNext(:,xinit);
                name1  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{xinit});
            else
                trace1 = UD.dataCurr(:,xinit);  
                name1  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{xinit});
            end
            name1 = sprintf('X-%d:%s:',xinit,name1);
            if yinit > nCurrRois,
                yinit  = yinit - nCurrRois;
                trace2 = UD.dataNext(:,yinit);
                name2  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{yinit});
            else
                trace2 = UD.dataCurr(:,yinit);  
                name2  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{yinit});
            end
            name2 = sprintf('Y-%d:%s:',yinit,name2);
            
            
            % extract traces
            
            figure(105),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            plot([trace1 trace2]),s = legend(name1,name2); set(s,'interpreter','none');
            title('Selected Traces')
            

            
        end
        
        % ==========================================
        function obj = ShowTracesDual(obj,  src, e)
            % ShowTraces - a callback
            % Shows traces on the figure
            hFig = src;
            if ~strcmp(get(src,'SelectionType'),'normal'), return; end;
            %set(src,'pointer','circle')
            cp = get(gca,'CurrentPoint');
            xinit = round(cp(1,1));
            yinit = round(cp(1,2));
            XLim = get(gca,'XLim'); YLim = get(gca,'YLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % estimate where
                        
            UD   = get(hFig,'UserData');
            [nR,nCurrRois] = size(UD.dataCurr);
            [nR,nNextRois] = size(UD.dataNext);
            expId  = UD.expId;
            expNameCurr        = obj.AnalysisStr{expId}.ExpName;
            expNameNext        = obj.AnalysisStr{expId+1}.ExpName;
            
            
            % extract traces
            if xinit > nCurrRois,
                xinit  = xinit - nCurrRois;
                trace1 = UD.dataNext(:,xinit);
                name1  = sprintf('%s:%s',expNameNext,obj.AnalysisStr{expId+1}.RoiNames{xinit});
            else
                trace1 = UD.dataCurr(:,xinit);  
                name1  = sprintf('%s:%s',expNameCurr,obj.AnalysisStr{expId}.RoiNames{xinit});
            end
            name1 = sprintf('X-%d:%s:',xinit,name1);
            if yinit > nCurrRois,
                yinit  = yinit - nCurrRois;
                trace2 = UD.dataNext(:,yinit);
                name2  = sprintf('%s:%s',expNameNext,obj.AnalysisStr{expId+1}.RoiNames{yinit});
            else
                trace2 = UD.dataCurr(:,yinit);  
                name2  = sprintf('%s:%s',expNameCurr,obj.AnalysisStr{expId}.RoiNames{yinit});
            end
            name2 = sprintf('Y-%d:%s:',yinit,name2);
            
            figure(105),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            plot([trace1 trace2]),s = legend(name1,name2); set(s,'interpreter','none');
            title('Selected Traces')
            

            
        end
        
        % ==========================================
        function obj = SpatialExperimentCorrelation(obj, expId, figNum) 
           % SpatialExperimentCorrelation - spatial correlation between experiment data
           % Compares location of Z-1 expId and Z-2 expId+1
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to correlate with expId+1
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 103; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum > expId ,'expId must be less than expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId+0}),'Current Experiment data is not loaded');
            assert(~isempty(obj.AnalysisStr{expId+1}),'Next Experiment data is not loaded');
            
            % select appropriate Z indexes
            zCurrInd            = obj.AnalysisStr{expId+0}.PosXYZ(:,3);
            zNextInd            = obj.AnalysisStr{expId+1}.PosXYZ(:,3);
            
            % may be an opposite order
            indCurr             = find(zCurrInd==1);
            indNext             = find(zNextInd==2);
%             indCurr             = 1:length(zCurrInd); % find(zCurrInd==1);
%             indNext             = 1:length(zNextInd); %find(zNextInd==2);

            % check again
            assert(~isempty(indCurr),  'Current Experiment data does not have z index 1');
            assert(~isempty(indNext),  'Next Experiment data does not have z index 2');
            
            % select spatial data
            xyCurr              = obj.AnalysisStr{expId+0}.PosXYZ(indCurr,1:2);
            xyNext              = obj.AnalysisStr{expId+1}.PosXYZ(indNext,1:2);
            
            
%             % debug - show side by side
%             figure(101),imagesc(dataCurr);title('Curr')
%             figure(102),imagesc(dataNext);title('Next')

            expNameCurr        = obj.AnalysisStr{expId+0}.ExpName;
            expNameNext        = obj.AnalysisStr{expId+1}.ExpName;
            
            
            % do the spatial distance
            distData            = distfcm(xyCurr,xyNext);
            %[c,p]               = corrcoef( obj.AnalysisStr{expId}.DffData(:,indCurr),obj.AnalysisStr{expId+1}.DffData(:,indNext));
            %[c ,p]              = corrcoef( [dataCurr,dataNext]);
            %[c ,lag]              = xcov( dataCurr,dataNext,20,'coeff');
            
            
            % current-next matching
            distThr             = 25; % distance in um
            [currInd,nextInd]   = find(distData < distThr);


            % save
            %obj.AnalysisStr{expId}.CorrData  = c;
            obj.AnalysisStr{expId}.DistData     = distData;
            obj.AnalysisStr{expId}.CurrIndZ1    = indCurr;
            obj.AnalysisStr{expId}.NextIndZ2    = indNext;
            obj.AnalysisStr{expId}.CurrIndS     = (currInd);
            obj.AnalysisStr{expId}.NextIndS     = (nextInd);
            
            
            if figNum < 1, return; end
            
            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            imagesc(distData);
            title(sprintf('2D Distance Map between %s and %s. Click on the image to see the pairs.',expNameCurr,expNameNext),'interpreter','none');
            xlabel(sprintf('Z=2 ROIs from %s',expNameNext)),ylabel(sprintf('Z=1 ROIs from %s',expNameCurr))
            colormap(jet)
            hFig1 = gcf;
            % install user click
            UD.expId    = expId;
            UD.dataCurr = xyCurr;
            UD.dataNext = xyNext;
            
            % show positions
            figure(figNum+1),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            hCurr = plot(xyCurr(:,1),xyCurr(:,2),'or','MarkerSize',16);hold on;
            hNext = plot(xyNext(:,1),xyNext(:,2),'og','MarkerSize',12);
            s = legend(sprintf('Z=1 ROIs from %s',expNameCurr),sprintf('Z=2 ROIs from %s',expNameNext));set(s,'interpreter','none');
            hSelect     = plot(xyCurr(1:2,1),xyCurr(1:2,2),'y','visible','off');
            hold off;
            xlabel('X [um]'),ylabel('Y [um]')
            title('Cell positions')
            % 
            UD.hSelect  = hSelect;
            set(hFig1,'UserData',UD,'WindowButtonDownFcn',@(s,e)ShowPositions(obj,s,e));% store new update

        end

        % ==========================================
        function obj = ShowPositions(obj,  src, e)
            % ShowTraces - a callback
            % Shows traces on the figure
            hFig = src;
            if ~strcmp(get(src,'SelectionType'),'normal'), return; end;
            %set(src,'pointer','circle')
            cp = get(gca,'CurrentPoint');
            xinit = round(cp(1,1));
            yinit = round(cp(1,2));
            XLim = get(gca,'XLim'); YLim = get(gca,'YLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % estimate where
            UD          = get(hFig,'UserData');
            [nCurrRois] = size(UD.dataCurr,1);
            [nNextRois] = size(UD.dataNext,1);
            expId       = UD.expId;
            distData    = obj.AnalysisStr{expId}.DistData;
            
            % check
            yinit       = max(1,min(nCurrRois,yinit));
            xinit       = max(1,min(nNextRois,xinit));
            
            % corr value
            corrValue   = distData(yinit,xinit);
            fprintf('Spatial Selection Value %4.3f : %s - %s\n',corrValue,obj.AnalysisStr{expId}.RoiNames{yinit},obj.AnalysisStr{expId+1}.RoiNames{xinit});
            
            % show on the map
            %if ~isempty(UD.hSelect), delete(UD.hSelect); end;
            %figure(src+1)
            set(UD.hSelect,'xdata',[UD.dataCurr(yinit,1);UD.dataNext(xinit,1)],'ydata',[UD.dataCurr(yinit,2);UD.dataNext(xinit,2)],'Visible','on')
            
            
            
        end
        
        % ==========================================
        function obj = ShowText(obj,  txt, severity ,quiet)
            % This manages info display
            
            % Ver    Date     Who  Description
            % ------ -------- ---- -------
            % 01.01  12/09/12 UD   adopted from SMT
            
            if nargin < 2, txt = 'connect';                 end;
            if nargin < 3, severity = 'I';                  end;
            if nargin < 4, quiet = 0;                       end;
            
            if quiet > 0, return; end;
            
            % print to screen
            %NoGUI = 1; %isempty(obj.Handles);
            
            
            if strcmp(severity,'I')
                col = 'k';
            elseif strcmp(severity,'W')
                col = 'b';
            elseif strcmp(severity,'E')
                col = 'r';
            else
                col = 'k';
            end;
            
            if true, %NoGUI,
                fprintf('%s : %s\n',severity,txt);
                %fprintf('%s',txt);
            else
                set(obj.Handles.textLabel,'string',txt,'ForegroundColor',col);
            end;
            
        end
        
        % ==========================================
        function obj = ShowLayer(obj, expId, figNum, zId )
           % ShowLayer - loads single experiment data and shows units in 3D space
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to show
            %    figNum - on what figure
            %    zId    - which z stack to show
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 105; end;
            if nargin < 4, zId = [1 2]; end;
            

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less or equal expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId}),  'Current Experiment data is not loaded');
 
            zNum                = size(obj.AnalysisDepth,2);
            assert(any(0 < zId & zId <= zNum), sprintf('zId must be in range [1:%d]',zNum));
            
            % color coding
            cmap                = jet(expNum*zNum);

            
            % create XYZ data in um
            posXYZ              = obj.AnalysisStr{expId}.PosXYZ;
            
            
            % select appropriate Z indexes and assign depth
            posZ                = zeros(size(posXYZ,1),1);
            for z = 1:zNum,
                if ~any(z == zId), continue; end;
                zBool           = obj.AnalysisStr{expId}.PosXYZ(:,3) == z;
                posXYZ(zBool,3) = obj.AnalysisDepth(expId,z);
                posZ(zBool)     = z;
            end
            % cut the non relevant
            posXYZ              = posXYZ(posZ>0,:);
            posZ                = posZ(posZ>0,:);
            
            % select XY and scale to um
            posXYZ(:,1:2)       = posXYZ(:,1:2)*obj.PIX2UM;
            
            % plot spheres
            %[xS,yS,zS]          = sphere;       
            % plot cylinder
            [xS,yS,zS]          = cylinder(linspace(0,.5,32).^2);       
            [xS,yS,zS]          = deal(xS*3,yS*3,zS*3);

            [xS,yS,zS]          = deal(xS*obj.NEURON2UM,yS*obj.NEURON2UM,zS*obj.NEURON2UM);
            
            figure(figNum),
            if isempty(findobj('Tag','AnalysisROI'))
            set(gcf,'Tag','AnalysisROI','Color','b','Name','Functional Reconstruction'),clf; colordef(gcf,'none');
            end
            hold on;
            for m = 1:size(posXYZ,1),
                s = surfl(xS + posXYZ(m,1),yS+posXYZ(m,2),zS + posXYZ(m,3));
                %set(s,'EdgeColor','none','FaceColor','interp','FaceLighting','phong')
                if posZ(m) == 1,
                    %set(s,'EdgeColor','none','FaceColor',cmap(zNum*(expId-1)+1,:),'FaceLighting','phong')
                    set(s,'EdgeColor','none','FaceColor',[0.7 0.7 0],'FaceLighting','phong')
                else
                    %set(s,'EdgeColor','none','FaceColor',cmap(zNum*(expId-1)+2,:),'FaceLighting','phong')
                    set(s,'EdgeColor','none','FaceColor',[0.7 0.7 0],'FaceLighting','phong')
                end
                %text( posXYZ(m,1)+15, posXYZ(m,2), posXYZ(m,3),obj.AnalysisStr{expId}.RoiNames{m},'FontSize',6)
            end
            hold off;
            axis equal; colormap(cool)
            xlabel('X [um]'),ylabel('Y [um]'),zlabel('Z [um]'),set(gca,'zdir','reverse');
            grid on;
            view(3)
            title('Functional Reconstruction Stack')
            %shading interp
         
        end
        
        % ==========================================
        function obj = ShowFunctionalConnections(obj, expId, figNum )
           % ShowFunctionalConnections - show correlations between different units
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to correlate with expId+1
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 105; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less or equal expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId}),  'Current Experiment data is not loaded');
            
            % check more
            assert(isfield(obj.AnalysisStr{expId},'CorrData'),'Current Experiment data is not correlated');
            zNum                = size(obj.AnalysisDepth,2);
            
 
            % Current data
            % create XYZ data in um
            posXYZ              = obj.AnalysisStr{expId}.PosXYZ;
           
            % select appropriate Z indexes and assign depth
            for z = 1:zNum,
                zBool           = obj.AnalysisStr{expId}.PosXYZ(:,3) == z;
                posXYZ(zBool,3) = obj.AnalysisDepth(expId,z);
            end
            
            % select XY and scale to um
            posXYZ(:,1:2)       = posXYZ(:,1:2)*obj.PIX2UM;
            
            % correlation info
            currInd             = obj.AnalysisStr{expId}.CurrIndF;
            nextInd             = obj.AnalysisStr{expId}.NextIndF;
            
            % current inside
            currInternalLink    = [posXYZ(currInd,:) posXYZ(nextInd,:)]';
            
            
            % plot spheres            
            figure(figNum),
%             if isempty(findobj('Tag','AnalysisROI'))
%             set(gcf,'Tag','AnalysisROI','Color','b','Name','Functional Reconstruction'),clf; colordef(gcf,'none');
%             end
            hold on;
            plot3(currInternalLink([1 4],:),currInternalLink([2 5],:),currInternalLink([3 6],:),'g','LineWidth',1);
            %plot3(nextInternalLink([1 4],:)+1,nextInternalLink([2 5],:)+1,nextInternalLink([3 6],:),'g');
            %plot3(currExternalLink([1 4],:),currExternalLink([2 5],:),currExternalLink([3 6],:),'r');

                %set(s,'EdgeColor','none','FaceColor','interp','FaceLighting','phong')
                %text( posXYZ(m,1), posXYZ(m,2), posXYZ(m,3),obj.AnalysisStr{expId}.RoiNames)
            hold off;
            axis equal; %colormap(cool)
            xlabel('X [um]'),ylabel('Y [um]'),zlabel('Z [um]'),set(gca,'zdir','reverse');
            grid on;
            view(3)
            title('Functional Reconstruction Stack')
            %shading interp
         
        end
        
        % ==========================================
        function obj = ShowFunctionalConnectionsDual(obj, expId, figNum )
           % ShowFunctionalConnections - show correlations between different units
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to correlate with expId+1
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 105; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum > expId ,'expId must be less than expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId}),  'Current Experiment data is not loaded');
            assert(~isempty(obj.AnalysisStr{expId+1}),'Next Experiment data is not loaded');
            
            % check more
            assert(isfield(obj.AnalysisStr{expId},'CorrData'),'Current Experiment data is not correlated');
            zNum                = size(obj.AnalysisDepth,2);
            
 
            % Current data
            % create XYZ data in um
            posXYZ              = obj.AnalysisStr{expId}.PosXYZ;
           
            % select appropriate Z indexes and assign depth
            for z = 1:zNum,
                zBool           = obj.AnalysisStr{expId}.PosXYZ(:,3) == z;
                posXYZ(zBool,3) = obj.AnalysisDepth(expId,z);
            end
            
            % select XY and scale to um
            posXYZ(:,1:2)       = posXYZ(:,1:2)*obj.PIX2UM;
            posXYZCurr          = posXYZ;
            currNum             = size(posXYZ,1);
            
            % Next data
            % create XYZ data in um
            posXYZ              = obj.AnalysisStr{expId+1}.PosXYZ;
           
            % select appropriate Z indexes and assign depth
            for z = 1:zNum,
                zBool           = obj.AnalysisStr{expId+1}.PosXYZ(:,3) == z;
                posXYZ(zBool,3) = obj.AnalysisDepth(expId+1,z);
            end
            
            % select XY and scale to um
            posXYZ(:,1:2)       = posXYZ(:,1:2)*obj.PIX2UM;
            posXYZNext          = posXYZ;
            nextNum             = size(posXYZ,1);
            
            % extract correlation data
            corrData            = obj.AnalysisStr{expId}.CorrData;
            corrData            = corrData - diag(diag(corrData));
            corrThr             = 0.7;
            % current inside
            [currInd,nextInd]   = find(corrData(1:currNum,1:currNum) > corrThr);
            currInternalLink    = [posXYZCurr(currInd,:) posXYZCurr(nextInd,:)]';
            
            % next inside
            [currInd,nextInd]   = find(corrData(currNum + (1:nextNum),currNum + (1:nextNum)) > corrThr);
            nextInternalLink    = [posXYZNext(currInd,:) posXYZNext(nextInd,:)]';
            
            % current-next 
            corrThr             = 0.4;
            [currInd,nextInd]   = find(corrData(1:currNum,currNum + (1:nextNum)) > corrThr);
            currExternalLink    = [posXYZCurr(currInd,:) posXYZNext(nextInd,:)]';
            
            
            % plot spheres            
            figure(figNum),
%             if isempty(findobj('Tag','AnalysisROI'))
%             set(gcf,'Tag','AnalysisROI','Color','b','Name','Functional Reconstruction'),clf; colordef(gcf,'none');
%             end
            hold on;
            plot3(currInternalLink([1 4],:),currInternalLink([2 5],:),currInternalLink([3 6],:),'g','LineWidth',4);
            %plot3(nextInternalLink([1 4],:)+1,nextInternalLink([2 5],:)+1,nextInternalLink([3 6],:),'g');
            %plot3(currExternalLink([1 4],:),currExternalLink([2 5],:),currExternalLink([3 6],:),'r');

                %set(s,'EdgeColor','none','FaceColor','interp','FaceLighting','phong')
                %text( posXYZ(m,1), posXYZ(m,2), posXYZ(m,3),obj.AnalysisStr{expId}.RoiNames)
            hold off;
            axis equal; %colormap(cool)
            xlabel('X [um]'),ylabel('Y [um]'),zlabel('Z [um]'),set(gca,'zdir','reverse');
            grid on;
            view(3)
            title('Functional Reconstruction Stack')
            %shading interp
         
        end
        
        
        % ==========================================
        function obj = ShowSpatialConnections(obj, expId, figNum )
           % ShowSpatialConnections - show spatial correlations between different units
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to correlate with expId+1
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 105; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum > expId ,'expId must be less than expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId+0}),'Current Experiment data is not loaded');
            assert(~isempty(obj.AnalysisStr{expId+1}),'Next Experiment data is not loaded');
            
            % check more
            assert(isfield(obj.AnalysisStr{expId},'DistData'),'Current Experiment does not spatial distance measuremetns');
            %zNum                = size(obj.AnalysisDepth,2);
            
            % extract correlation data
            %distData            = obj.AnalysisStr{expId}.DistData;
            %distData            = distData + diag(diag(distData)+1000);
            indCurr             = obj.AnalysisStr{expId}.CurrIndZ1;
            indNext             = obj.AnalysisStr{expId}.NextIndZ2;
            
            % select spatial data curr Z=1, Next z=2
            xyzCurr              = obj.AnalysisStr{expId+0}.PosXYZ(indCurr,:);
            xyzCurr(:,1:2)       = xyzCurr(:,1:2)*obj.PIX2UM;
            xyzCurr(:,3)         = obj.AnalysisDepth(expId,1);
            
            xyzNext              = obj.AnalysisStr{expId+1}.PosXYZ(indNext,:);
            xyzNext(:,1:2)       = xyzNext(:,1:2)*obj.PIX2UM;
            xyzNext(:,3)         = obj.AnalysisDepth(expId+1,2);
            
            % matching
            currInd             = obj.AnalysisStr{expId}.CurrIndS;
            nextInd             = obj.AnalysisStr{expId}.NextIndS;
            currExternalLink    = [xyzCurr(currInd,:) xyzNext(nextInd,:)]';
            
            
            % plot spheres            
            figure(figNum),
%             if isempty(findobj('Tag','AnalysisROI'))
%             set(gcf,'Tag','AnalysisROI','Color','b','Name','Functional Reconstruction'),clf; colordef(gcf,'none');
%             end
            hold on;
            %plot3(currInternalLink([1 4],:),currInternalLink([2 5],:),currInternalLink([3 6],:),'g','LineWidth',8);
            %plot3(nextInternalLink([1 4],:)+1,nextInternalLink([2 5],:)+1,nextInternalLink([3 6],:),'g');
            plot3(currExternalLink([1 4],:),currExternalLink([2 5],:),currExternalLink([3 6],:),'b','LineWidth',1);

                %set(s,'EdgeColor','none','FaceColor','interp','FaceLighting','phong')
                %text( posXYZ(m,1), posXYZ(m,2), posXYZ(m,3),obj.AnalysisStr{expId}.RoiNames)
            hold off;
            axis equal; %colormap(cool)
            xlabel('X [um]'),ylabel('Y [um]'),zlabel('Z [um]'),set(gca,'zdir','reverse');
            grid on;
            view(3)
            title('Functional Reconstruction Stack')
            %shading interp
         
        end
        
        
        % ==========================================
        function obj = TestSelect(obj, testType)
            % TestSelect - which test data to use 
            % Input:
            %   testType - which test to run
            % Output:
            %   ExperimentDir - creates directories to align
            
            if nargin < 2, testType    = 1; end;
            
            % params
            switch testType,
                
                case 1, % Uri
                    % Latest data ROI data
                    analysisDir{1}         = 'C:\Uri\DataJ\Janelia\Analysis\D30\8_17_14_81-90';
                    analysisDir{2}         = 'C:\Uri\DataJ\Janelia\Analysis\D30\8_17_14_91-100';
                    analysisDir{3}         = 'C:\Uri\DataJ\Janelia\Analysis\D30\8_17_14_101-117';
                    analysisDir{4}         = 'C:\Uri\DataJ\Janelia\Analysis\D30\8_17_14_116-125';
                    
                    % depth of each layer and Z-stacks (Jackies Document)
                    %                        Level 1    Level 2 in um
                    analysisDepth(1,1:2)   = [428       542];       
                    analysisDepth(2,1:2)   = [328       428];       
                    analysisDepth(3,1:2)   = [228       328];       
                    analysisDepth(4,1:2)   = [69        228];   % UD better picture  change 154 to 228
          
                case 2, % Lab
                    % Latest data ROI data
                    analysisDir{1}         = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D30a\8_17_14_81-90';
                    analysisDir{2}         = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D30a\8_17_14_91-100';
                    analysisDir{3}         = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D30a\8_17_14_101-117';
                    analysisDir{4}         = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D30a\8_17_14_116-125';
                    
                    % depth of each layer and Z-stacks (Jackies Document)
                    %                        Level 1    Level 2 in um
                    analysisDepth(1,1:2)   = [428       542];       
                    analysisDepth(2,1:2)   = [328       428];       
                    analysisDepth(3,1:2)   = [228       328];       
                    analysisDepth(4,1:2)   = [69        154];     
                    
                    
                    
                case 11, % user specified selection
                    
                    dirName             = uigetdir(pwd,'Select First Analysis Directory with TPA mat files');
                    if isnumeric(dirName), return; end;  % cancel button  
                    analysisDir{1}      = dirName;
                    
                    dirName             = uigetdir(dirName,'Select Second Analysis Directory with TPA mat files');
                    if isnumeric(dirName), return; end;  % cancel button  
                    analysisDir{2}      = dirName;
                    
                    % stam
                    analysisDepth(1,1:2)   = [428       542];       
                    analysisDepth(2,1:2)   = [328       428];       
                    
                    
                otherwise
                    error('Bad testType')
            end
            
            % create linear dimension
                                   
            % save
            obj.AnalysisDir             = analysisDir;
            obj.AnalysisDepth           = analysisDepth;
            
        end
        
        % ==========================================
        function obj = TestSingleLoad(obj,expId)
            % TestSingleLoad - single experiment load
            if nargin < 2,             expId  = 1; end;
           
            % params
            testType                    = 1;
            figNum                      = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % check load
            obj                         = LoadSingleExperiment(obj, expId) ;        
            
        end
        
        % ==========================================
        function obj = TestFunctionalCorrelation(obj,expId)
            % TestSingleLoad - single experiment load
            if nargin < 2,             expId  = 1; end;
           
            % params
            testType                    = 2;
            figNum                      = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % check load
            obj                         = LoadSingleExperiment(obj, expId) ;        
            %obj                         = LoadSingleExperiment(obj, expId+1) ; 
            
            % correlate
            obj                         = FunctionalExperimentCorrelation(obj, expId, figNum + 10); 
            
            % show
            obj                         = ShowLayer(obj, expId, figNum) ;             
            obj                         = ShowFunctionalConnections(obj, expId, figNum) ;  
            
        end
       
        % ==========================================
        function obj = TestSpatialCorrelation(obj,expId)
            % TestSpatialCorrelation - dual experiment load
            % check how the cells are aligned between experiments
            
            if nargin < 2,             expId  = 1; end;
           
            % params
            testType                    = 2;
            figNum                      = 201;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % check load
            obj                         = LoadSingleExperiment(obj, expId+0) ;        
            obj                         = LoadSingleExperiment(obj, expId+1) ; 
            
            % correlate
            obj                         = SpatialExperimentCorrelation(obj, expId, figNum + 10);   
            
            % show
            obj                         = ShowLayer(obj, expId+0, figNum, 1) ;             
            obj                         = ShowLayer(obj, expId+1, figNum, 2) ;             
            obj                         = ShowSpatialConnections(obj, expId, figNum) ;  
            
            
        end
        
        % ==========================================
        function obj = TestShowLayers(obj)
            % TestShowLayers - show single units on the 3D map
            
           
            % params
            testType                    = 2;
            figNum                      = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            expNum                      = size(obj.AnalysisDepth,1);
            
            % load
            for expId  = 1:expNum,
                obj                     = LoadSingleExperiment(obj, expId) ; 
                obj                     = ShowLayer(obj, expId, figNum) ; 
            end
            
            
        end
        
        % ==========================================
        function obj = TestShowFunctionalConnections(obj)
            % TestShowFunctionalConnections - show single units on the 3D map with correlation
            % base connections
            
           
            % params
            testType                    = 2;
            figNum                      = 111;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            expNum                      = size(obj.AnalysisDepth,1);
            
            % load
            for expId  = 1:expNum,
                obj                     = LoadSingleExperiment(obj, expId) ; 
                obj                     = ShowLayer(obj, expId, figNum) ; 
            end
            
            % correlation
            for expId  = 1:expNum,
                obj                     = FunctionalExperimentCorrelation(obj, expId, 0); 
                obj                     = ShowFunctionalConnections(obj, expId, figNum ) ;                
            end
            
            
        end
        
        % ==========================================
        function obj = TestShowAllConnections(obj)
            % TestShowAllConnections - show single units on the 3D map with correlation
            % based on function connections and proximity information
            
           
            % params
            testType                    = 1;
            figNum                      = 111;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            expNum                      = size(obj.AnalysisDepth,1);
            
            % load
            for expId  = 1:expNum,
                obj                     = LoadSingleExperiment(obj, expId) ; 
                obj                     = ShowLayer(obj, expId, figNum) ; 
            end
            
            % correlation functional
            for expId  = 1:expNum,
                obj                     = FunctionalExperimentCorrelation(obj, expId, 0); 
                obj                     = ShowFunctionalConnections(obj, expId, figNum ) ;                
            end
  
            % correlation spatial
            for expId  = 1:expNum-1,
                obj                     = SpatialExperimentCorrelation(obj, expId, 0); 
                obj                     = ShowSpatialConnections(obj, expId, figNum ) ;                
            end
            
            % make it nice
            figure(figNum)
            camlight(-45,45)
            set(gcf,'Renderer','zbuffer')
            lighting phong
            zoom(1.5)            
            
        end
        

        

    end % methods

end    % EOF..
