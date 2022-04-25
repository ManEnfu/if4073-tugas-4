classdef aplikasi_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        InputPanel                      matlab.ui.container.Panel
        FixImageRotationCheckBox        matlab.ui.control.CheckBox
        CropImageCheckBox               matlab.ui.control.CheckBox
        LoadImageButton                 matlab.ui.control.Button
        OriginalandProcessedImagePanel  matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        ImageCropped                    matlab.ui.control.Image
        ImageRotated                    matlab.ui.control.Image
        ImageGray                       matlab.ui.control.Image
        ImageOriginal                   matlab.ui.control.Image
        DetectedPlateNumberPanel        matlab.ui.container.Panel
        LabelPlateNumber                matlab.ui.control.Label
    end

    
    properties (Access = private)
        OriginalImage
        GrayImage
        RotatedImage
        CroppedImage
        TemplateImg
        TemplateStr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    end
    
    methods (Access = private)
        
        % Fungsi utama
        function Process(app, aImage)

            % Ubah gambar menjadi grayscale
            app.GrayImage = rgb2gray(aImage);
            app.ImageGray.ImageSource = cat(3, app.GrayImage, app.GrayImage, app.GrayImage);

            % Jika mode perbaikan kemiringan dinyalakan, perbaiki kemiringan gambar 
            if app.FixImageRotationCheckBox.Value
                app.RotatedImage = app.FixRotation(app.GrayImage);
                app.ImageRotated.ImageSource = cat(3, app.RotatedImage, app.RotatedImage, app.RotatedImage);
            else
                app.RotatedImage = app.GrayImage;
                app.ImageRotated.ImageSource = '';
            end

            % Jika mode cropping dinyalakan, lakukan cropping pada gambar
            if app.CropImageCheckBox.Value
                app.CroppedImage = app.Crop(app.RotatedImage);
                app.ImageCropped.ImageSource = cat(3, app.CroppedImage, app.CroppedImage, app.CroppedImage);
            else
                app.CroppedImage = app.RotatedImage;
                app.ImageCropped.ImageSource = '';
            end

            % Deteksi nomor plat mobil pada gambar final
            app.LabelPlateNumber.Text = app.Detect(app.CroppedImage);
        end
        
        % Fungsi deteksi nomor plat mobil
        function result = Detect(app, aImage)
            vPlateImage = app.GetCharElement(aImage, 9);
            vPlateNumber = app.MatchCharElement(vPlateImage, app.TemplateImg, app.TemplateStr);

            result = vPlateNumber;
        end

        % Fungsi cropping untuk mengambil hanya plat nomor pada gambar
        function result = Crop(~, aImage)

            % Pertama, lakukan edge detection dengan metode prewitt
            vImage = edge(aImage, 'prewitt');
            
            % Kemudian, gunakan regionprops untuk mencari daerah tertutup
            % paling besar pada gambar yang memenuhi persyaratan rasio
            % panjang bagi lebar di antara 2 dan 7. Angka 2 dan 7
            % didapatkan dari uji coba.
            vRegionProp = regionprops(vImage, 'BoundingBox', 'Area', 'MajorAxisLength', 'MinorAxisLength');
            vArea = vRegionProp(1).Area;
            vBoundingBox = vRegionProp(1).BoundingBox;
            vCount = numel(vRegionProp);
            vMaxArea = vArea;
            for i=2:vCount
                vRatio = vRegionProp(i).MajorAxisLength / vRegionProp(i).MinorAxisLength;
                if vRatio > 2 && vRatio < 7 && vMaxArea < vRegionProp(i).Area
                    vMaxArea = vRegionProp(i).Area;
                    vBoundingBox = vRegionProp(i).BoundingBox;
                end
            end
            
            % Terakhir, gunakan imcrop untuk memotong hanya daerah tersebut
            % dari gambar
            result = imcrop(aImage, vBoundingBox);
        end

        % Fungsi perbaikan kemiringan gambar
        function result = FixRotation(~, aImage)

            % Pertama, lakukan edge detection dengan metode Canny, lalu
            % sambungkan tepi-tepi yang terpisah dengan operasi thicken
            binaryImage = edge(aImage,'canny');
            binaryImage = bwmorph(binaryImage,'thicken');

            % Lakukan proyeksi transformasi radon pada gambar sepanjang 180
            % derajat, dari -90 hingga +89.
            theta = -90:89;
            [R,~] = radon(binaryImage,theta);
            [R1,~] = max(R); 

            % Cari transformasi dengan kemiringan gambar terkecil
            theta_max = 90;
            while(theta_max > 50 || theta_max<-50)
                [~,theta_max] = max(R1);
                R1(theta_max) = 0;
                theta_max = theta_max - 91;
            end

            % Rotasi gambar asli sesuai transformasi dengan kemiringan
            % terkecil dengan imrotate, lalu ubah pixel hitam pengisi
            % menjadi putih
            result = imrotate(aImage,-theta_max);
            result(result == 0) = 255;
        end

        function res = MatchTemplate(~, I, T)
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

        function res = MatchCharElement(app, K, T, templateStr)
            res = "";
            for z = 1: size(K, 3)
                i = app.MatchTemplate(K(:,:,z), T);
                res = res + templateStr(i);
            end
        end

        function K = GetCharElement(~, I, maxnchar)
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
            app.TemplateImg = app.GetCharElement(J, 36);
        end

        % Button pushed function: LoadImageButton
        function LoadImageButtonPushed(app, event)
            [file,path] = uigetfile({'*.png;*.jpg;*.jpeg','Images'});
            if (file ~= 0)
                app.OriginalImage = imread(fullfile(path,file));
                app.ImageOriginal.ImageSource = app.OriginalImage;
                app.Process(app.OriginalImage);
            end
        end

        % Value changed function: CropImageCheckBox, 
        % FixImageRotationCheckBox
        function FixImageRotationCheckBoxValueChanged(app, event)
            app.Process(app.OriginalImage);
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
            app.GridLayout.RowHeight = {'0.5x', '1.6x', '0.4x'};

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
            app.LabelPlateNumber.Position = [1 -11 620 61];
            app.LabelPlateNumber.Text = '-';

            % Create OriginalandProcessedImagePanel
            app.OriginalandProcessedImagePanel = uipanel(app.GridLayout);
            app.OriginalandProcessedImagePanel.Title = 'Original and Processed Image';
            app.OriginalandProcessedImagePanel.Layout.Row = 2;
            app.OriginalandProcessedImagePanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.OriginalandProcessedImagePanel);

            % Create ImageOriginal
            app.ImageOriginal = uiimage(app.GridLayout2);
            app.ImageOriginal.Layout.Row = 1;
            app.ImageOriginal.Layout.Column = 1;

            % Create ImageGray
            app.ImageGray = uiimage(app.GridLayout2);
            app.ImageGray.Layout.Row = 1;
            app.ImageGray.Layout.Column = 2;

            % Create ImageRotated
            app.ImageRotated = uiimage(app.GridLayout2);
            app.ImageRotated.Layout.Row = 2;
            app.ImageRotated.Layout.Column = 1;

            % Create ImageCropped
            app.ImageCropped = uiimage(app.GridLayout2);
            app.ImageCropped.Layout.Row = 2;
            app.ImageCropped.Layout.Column = 2;

            % Create InputPanel
            app.InputPanel = uipanel(app.GridLayout);
            app.InputPanel.Title = 'Input';
            app.InputPanel.Layout.Row = 1;
            app.InputPanel.Layout.Column = 1;

            % Create LoadImageButton
            app.LoadImageButton = uibutton(app.InputPanel, 'push');
            app.LoadImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImageButtonPushed, true);
            app.LoadImageButton.Position = [11 36 599 22];
            app.LoadImageButton.Text = 'Load Image';

            % Create CropImageCheckBox
            app.CropImageCheckBox = uicheckbox(app.InputPanel);
            app.CropImageCheckBox.ValueChangedFcn = createCallbackFcn(app, @FixImageRotationCheckBoxValueChanged, true);
            app.CropImageCheckBox.Text = 'Crop Image';
            app.CropImageCheckBox.Position = [524 12 85 22];

            % Create FixImageRotationCheckBox
            app.FixImageRotationCheckBox = uicheckbox(app.InputPanel);
            app.FixImageRotationCheckBox.ValueChangedFcn = createCallbackFcn(app, @FixImageRotationCheckBoxValueChanged, true);
            app.FixImageRotationCheckBox.Text = 'Fix Image Rotation';
            app.FixImageRotationCheckBox.Position = [400 12 123 22];

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