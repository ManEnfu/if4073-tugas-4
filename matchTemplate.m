function res = matchTemplate(I, T)
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