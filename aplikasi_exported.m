classdef aplikasi_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        OriginalImageRotatedImageCroppedImageandFinalImagePanel  matlab.ui.container.Panel
        GridLayout2               matlab.ui.container.GridLayout
        ImageCropped              matlab.ui.control.Image
        ImageRotated              matlab.ui.control.Image
        ImageFiltered             matlab.ui.control.Image
        ImageOriginal             matlab.ui.control.Image
        DetectedPlateNumberPanel  matlab.ui.container.Panel
        LabelPlateNumber          matlab.ui.control.Label
        LoadImageButton           matlab.ui.control.Button
    end

    
    properties (Access = private)
        OriginalImage
        FilteredImage
        RotatedImage
        CroppedImage
        TemplateImg
        TemplateStr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    end
    
    methods (Access = private)

        function Process(app)
            app.FilteredImage = rgb2gray(app.OriginalImage);
            app.ImageFiltered.ImageSource = cat(3, app.FilteredImage, app.FilteredImage, app.FilteredImage);

            app.RotatedImage = app.FilteredImage;
            app.ImageRotated.ImageSource = cat(3, app.RotatedImage, app.RotatedImage, app.RotatedImage);

            app.CroppedImage = app.RotatedImage;
            app.ImageCropped.ImageSource = cat(3, app.CroppedImage, app.CroppedImage, app.CroppedImage);
        end
        
        function Detect(app)
            vPlateImage = app.getCharElement(app.CroppedImage, 9);
            vPlateNumber = app.matchCharElement(vPlateImage, app.TemplateImg, app.TemplateStr);

            app.LabelPlateNumber.Text = vPlateNumber;
        end

        function res = matchTemplate(~, I, T)
            maxMatch = 0;
            res = 0;
            for z = 1: size(T, 3)
                m = bwarea(~xor(I, T(:,:,z)));
                if m > maxMatch
                    maxMatch = m;
                    res = z;
                end
            end
        end

        function res = matchCharElement(app, K, T, templateStr)
            res = "";
            for z = 1: size(K, 3)
                i = app.matchTemplate(K(:,:,z), T);
                res = res + templateStr(i);
            end
        end

        function K = getCharElement(~, I, maxnchar)
            % segmentation
            J = imbinarize(I);
            J = imopen(J, strel('disk', 2));
            J = imclearborder(J,8);
            J = bwareaopen(J, 100);
            %imshow(J);
            
            L = J;
            maxsegment = 0;
            segmentsum = 0;
            segmentarea = 0;
            for i = 1: maxnchar
                newL = bwareafilt(J,i);
                newsegmentsum = bwarea(newL);
                newsegmentarea = newsegmentsum-segmentsum;
                %newsegmentarea
                %maxsegment
                if newsegmentarea < 0.3 * maxsegment
                    break;
                end
                segmentarea = newsegmentarea;
                if segmentarea > maxsegment
                    maxsegment = segmentarea;
                end
                L = newL;
                segmentsum = newsegmentsum;
            end
        
            %imshow(L);
            % crop row
            rowBlocks = bwareafilt(max(L,[],2),1);
            toprow = 0; 
            botrow = 0;
            for y = 1: size(rowBlocks, 1)
                if toprow == 0 && rowBlocks(y)
                    toprow = y;
                elseif toprow ~= 0 && ~rowBlocks(y)
                    botrow = y-1;
                    break;
                end
            end
            if botrow == 0
                botrow = size(rowBlocks);
            end
            L = L(toprow:botrow,:);
        
            % crop individual character
            colBlocks = max(L,[],1);
            leftcol = 0;
            % rightcol = 0;
            K = logical([]);
            for x = 1: size(colBlocks, 2)
                if leftcol == 0 && colBlocks(x)
                    leftcol = x;
                elseif leftcol ~= 0 && (~colBlocks(x) || x == size(colBlocks, 2)) 
                    rightcol = x-1;
                    C = L(:,leftcol:rightcol);
                    toprow = 0; 
                    botrow = 0;
                    rowBlocks = max(C,[],2);
                    for y = 1: size(rowBlocks, 1)
                        if toprow == 0 && rowBlocks(y)
                            toprow = y;
                        elseif toprow ~= 0 && ~rowBlocks(y)
                            botrow = y-1;
                            break;
                        end
                    end
                    if botrow == 0
                        botrow = size(rowBlocks);
                    end
                    C = C(toprow:botrow,:);
                    K = cat(3,K,imresize(C, [128 128]));
                    leftcol = 0;
                end
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            J = rgb2gray(imread("images/template.png"));
            app.TemplateImg = app.getCharElement(J, 36);
        end

        % Button pushed function: LoadImageButton
        function LoadImageButtonPushed(app, event)
            [file,path] = uigetfile({'*.png;*.jpg;*.jpeg','Images'});
            if (file ~= 0)
                app.OriginalImage = imread(fullfile(path,file));
                app.ImageOriginal.ImageSource = app.OriginalImage;
                app.Process();
                app.Detect();
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'0.15x', '1.6x', '0.4x'};

            % Create LoadImageButton
            app.LoadImageButton = uibutton(app.GridLayout, 'push');
            app.LoadImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImageButtonPushed, true);
            app.LoadImageButton.Layout.Row = 1;
            app.LoadImageButton.Layout.Column = 1;
            app.LoadImageButton.Text = 'Load Image';

            % Create DetectedPlateNumberPanel
            app.DetectedPlateNumberPanel = uipanel(app.GridLayout);
            app.DetectedPlateNumberPanel.Title = 'Detected Plate Number';
            app.DetectedPlateNumberPanel.Layout.Row = 3;
            app.DetectedPlateNumberPanel.Layout.Column = 1;

            % Create LabelPlateNumber
            app.LabelPlateNumber = uilabel(app.DetectedPlateNumberPanel);
            app.LabelPlateNumber.HorizontalAlignment = 'center';
            app.LabelPlateNumber.FontSize = 16;
            app.LabelPlateNumber.FontWeight = 'bold';
            app.LabelPlateNumber.Position = [0 0 620 61];
            app.LabelPlateNumber.Text = '-';

            % Create OriginalImageRotatedImageCroppedImageandFinalImagePanel
            app.OriginalImageRotatedImageCroppedImageandFinalImagePanel = uipanel(app.GridLayout);
            app.OriginalImageRotatedImageCroppedImageandFinalImagePanel.Title = 'Original Image, Rotated Image, Cropped Image, and Final Image';
            app.OriginalImageRotatedImageCroppedImageandFinalImagePanel.Layout.Row = 2;
            app.OriginalImageRotatedImageCroppedImageandFinalImagePanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.OriginalImageRotatedImageCroppedImageandFinalImagePanel);

            % Create ImageOriginal
            app.ImageOriginal = uiimage(app.GridLayout2);
            app.ImageOriginal.Layout.Row = 1;
            app.ImageOriginal.Layout.Column = 1;

            % Create ImageFiltered
            app.ImageFiltered = uiimage(app.GridLayout2);
            app.ImageFiltered.Layout.Row = 1;
            app.ImageFiltered.Layout.Column = 2;

            % Create ImageRotated
            app.ImageRotated = uiimage(app.GridLayout2);
            app.ImageRotated.Layout.Row = 2;
            app.ImageRotated.Layout.Column = 1;

            % Create ImageCropped
            app.ImageCropped = uiimage(app.GridLayout2);
            app.ImageCropped.Layout.Row = 2;
            app.ImageCropped.Layout.Column = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = aplikasi_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end