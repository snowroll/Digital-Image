I = imread('test.jpg');
Bright = I;
Contrast = I;
T = I;
[h, w] = size(I);
for i = 1 : h
    for j = 1 : w
        Bright(i, j) = min(255, I(i, j) + 50);
        T(i, j) = 2 * (I(i, j) - 127) + 127;
        Contrast(i, j) = max(T(i,j), 0);
        Contrast(i, j) = min(Contrast(i,j), 255);
    end
end
gammaCorrection(I, 1, 1.2)
histogram(I)
%imshow(Bright);
%imshow(Contrast)
%imshow(Gamma);
%imwrite(Bright, 'Brightness.png');
%imwrite(Contrast, 'Contrast.png');

function gammaCorrection(img, a, gamma) %gamma
I = im2double(img);
%I = rgb2gray(I);
s = a * (I .^ gamma);
subplot(1, 2, 1), imshow(I), title('Original');
subplot(1, 2, 2), imshow(s), title(sprintf('Gamma: %0.1f', gamma));
end

function h=histogram(I)
[R, C, B] = size(I);
h = zeros(256, 1, B);  %allocate the histogram
for g = 0 : 255
    h(g+1, 1, :) = sum(sum(I == g));
end
disp(h)
end