
clear all; clc;
selpath = fullfile(pwd, 'Database'); % or selpath = '<your directory full path>';

%first for loop is for the 142 folder
for j = 1:1:142
%for every folder in database a new folder is created for segmented images.
newDirectory = strcat(selpath, num2str(j));
mkdir(newDirectory);
    %second for loop is for the all the image file in the folder.
    for i = 4:1:66
    
    %This part creates filepath to the images.
    file = strcat('EA_HW', num2str(i), '.jpg');
       
            if j <= 9
            folder = strcat('E00', num2str(j));
            filepath = fullfile(selpath, folder,   file);

        elseif  9 < j && j <= 99 
            folder = strcat('E0', num2str(j));
            filepath = fullfile(selpath, folder,  file);

        elseif 99 < j 
            folder = strcat('E', num2str(j));
            filepath = fullfile(selpath, folder,  file); 
        end
    
        %if input filepath is exist it proceed 
        if exist(filepath)
                
                I=imread(filepath);

                %Use imresize which firsts apply gaussian filter then scale by 0.5
                I=imresize(I,0.5);
%               figure(1);imshow(I);

                %convert from RGB to grayscale
                GCI=rgb2gray(I);
      
%               figure(2);imshow(GCI);
                %find size of row and column.
                 row=size(GCI,1);
                 column=size(GCI,2);

                 if mean(GCI) == 240
                     continue;
                 end
                 
                %get the size of the image
                [p,q]=size(GCI);

                minx = row;
                miny = column;
                maxx = 0;
                maxy = 0; 
                
                %This part does segmentation.
                for x=1:1:p
                    for y=1:1:q
                        if ( GCI(x,y) < 170 ) 
                                min_y = x;
                                max_y = x;
                                if ( miny > min_y )
                                    miny = min_y; 
                                end
                                if ( maxy < max_y )
                                    maxy = max_y;
                                end

                                min_x = y;
                                max_x = y;
                                if ( minx > min_x )
                                    minx = min_x;
                                end
                                if ( maxx < max_x )
                                    maxx = max_x;
                                end
                        else
                            continue;


                        end
                    end
                end

                width_distance_x = maxx-min_x;
                hight_distance_y = maxy-miny;


                croppedImage = GCI(miny:maxy, min_x:maxx);

%               figure(4);imshow(croppedImage, []);

                pixNum = width_distance_x * hight_distance_y;

                croppedImage = double(croppedImage); 

                %segmented image is save in a directory for later use
                pad=uint8(croppedImage);
                saveName = strcat(num2str(i), '.jpg');
                
                filenewDirectory = fullfile( newDirectory, saveName);
                
                imwrite(pad, filenewDirectory);

                  
               
        else
                continue;
        end            
    end
end    

%this section process segmented image
for i = 1:1:142
    FodlerSearch = strcat(selpath, num2str(i));
  
    [fid, errmsg] = fopen(FodlerSearch, 'w');
    
    file = strcat('4', '.jpg');
    checkingPath = fullfile(FodlerSearch, file);
   
    if exist(checkingPath) == 0
        continue;
    end
    
    %Validation for segmented images done in this part.
    imgSet = imageDatastore(FodlerSearch, 'LabelSource','foldernames');
    
    [imgSetTest, imgSetTrain] = splitEachLabel(imgSet,0.25);
                
    TrainSize = size(imgSetTrain.Files, 1); 
    TestSize = size(imgSetTest.Files, 1);
    
    %Features of the segmented images are taken here. 
    %Images sepeated into as two class which are test and train.
    for j = 1:1:TestSize      
        TestImages{j} = readimage(imgSetTest,j);
    end
                
    for j = 1:1:TestSize 
        image = TestImages{j};

        TestMeans(j) = mean(image, 'all');
        image = double(image);
        TestNorm(j) = std(image, 0 , 'all');
        TestStd(j) = norm(image);
    end
                
    for j = 1:1:TrainSize     
        TrainImages{j} = readimage(imgSetTrain,j);
    end
                
    for j = 1:1:TrainSize
        image = TrainImages{j};

        TrainMeans(j) = mean(image, 'all');
        image = double(image);
        TrainNorm(j) = std(image, 0 , 'all');
        TrainStd(j) = norm(image);
    end           
    
    x=size(30);
    y=size(30);

    for j = 1:1:TrainSize
       TrainFeatures(j, 1) = TrainMeans(j);
       TrainFeatures(j, 2) = TrainNorm(j);
       TrainFeatures(j, 3) = TrainStd(j);
    end
    
    for j = 1:1:TestSize
       TestFeatures(j, 1) = TestMeans(j);
       TestFeatures(j, 2) = TestNorm(j);
       TestFeatures(j, 3) = TestStd(j);
    end
    %Classification and Accurasy chechk is done here.
    
        [CorrIMAGE, D] = knnsearch(TrainFeatures, TestFeatures);
        
%         a = size(TestImages);
%         b = size(IDX);
       
        tSize(i) = TrainSize;
        tesize(i) = TestSize;
        Accuracy(i) = (size(CorrIMAGE, 2)/size(TestImages, 1))*100; 
      
end

% fprintf('Accuracy:\n');
% counter = 0;
% for i = 1:1:142
%     
%     if Accuracy(i) == 100
%         counter = counter + 1;
%     end
% 
%     fprintf('%d. - %d\n',i, Accuracy(i));
% end
% 
% fprintf('Total number of accurate images: %d\n', counter);
