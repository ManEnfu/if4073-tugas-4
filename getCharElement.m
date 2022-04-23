function K = getCharElement(I, sizeThreshold)
    % segmentation
    J = im2bw(I, graythresh(I));
    J = imclearborder(J,8);
    J = bwareaopen(J, sizeThreshold);
    % J = imopen(J, strel('disk', brushThreshold));
    
    % crop row
    rowBlocks = bwareafilt(max(J,[],2),1);
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
    J = J(toprow:botrow,:);

    % crop individual character
    colBlocks = max(J,[],1);
    leftcol = 0;
    % rightcol = 0;
    K = logical([]);
    for x = 1: size(colBlocks, 2)
        if leftcol == 0 && colBlocks(x)
            leftcol = x;
        elseif leftcol ~= 0 && (~colBlocks(x) || x == size(colBlocks, 2)) 
            rightcol = x-1;
            C = J(:,leftcol:rightcol);
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