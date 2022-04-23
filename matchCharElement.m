function res = matchCharElement(K, T, templateStr)
    res = "";
    for z = 1: size(K, 3)
        i = matchTemplate(K(:,:,z), T);
        res = res + templateStr(i);
    end
end