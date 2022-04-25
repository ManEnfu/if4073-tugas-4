I = rgb2gray(imread("images/platnomor7.jpg"));
J = rgb2gray(imread("images/template.png"));

K = getCharElement(I, 9);
T = getCharElement(J, 36);
templatestr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

reg = matchCharElement(K,T,templatestr)