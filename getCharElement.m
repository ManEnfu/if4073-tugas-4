function K = getCharElement(I, maxnchar)
    % Pengambangan
    J = im2bw(I, graythresh(I));
    % Lakukan operasi NOT jika tulisan gelap di latar terang
    if bwarea(J) > size(J,1) * size(J,2) / 2
        J = ~J;
    end
    J = imerode(J, strel('disk', 3));
    imshow(J);
    J = imclearborder(J,8);
    J = bwareaopen(J, 100);
    
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