function K = getCharElement(I, sizeThreshold, brushThreshold)
    % segmentation
    J = im2bw(I, graythresh(I));
    J = bwareaopen(J, sizeThreshold);
    J = imopen(J, strel('disk', brushThreshold));
    
    % crop row
    rowBlocks = max(J,[],2);
    toprow = 0; 
    botrow = 0;
    for y = 1: size(rowBlocks, 1)
        if toprow == 0 && rowBlocks(y)
            toprow = y;
        elseif toprow ~= 0 && ~rowBlocks(y)
            botrow = y-1;
            break;
        end;
    end
    if botrow == 0
        botrow = size(rowBlocks);
    end
    J = J(toprow:botrow,:);

    % crop individual character
    colBlocks = max(J,[],1);
    leftcol = 0;
    rightcol = 0;
    K = [];
    for x = 1: size(colBlocks, 2)
        if leftcol == 0 && colBlocks(x)
            leftcol = x;
        elseif leftcol ~= 0 && (~colBlocks(x) || x == size(colBlocks, 2)) 
            rightcol = x-1;
            C = J(:,leftcol:rightcol);
            K = cat(3,K,imresize(C, [128 128]));
            leftcol = 0;
            rightcol = 0;
        end
    end
end