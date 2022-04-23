I = rgb2gray(imread("images/platnomor1.jpg"));
J = rgb2gray(imread("images/template.png"));

K = getCharElement(I, 5000);
T = getCharElement(J, 5);
templatestr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

reg = matchCharElement(K,T,templatestr)