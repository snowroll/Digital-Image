I = imread('test.jpg');
J = imread('match.jpg');
%subplot(121), imshow(I), title('orignal')
subplot(131), imshow(I), title('orignal');
subplot(132), imshow(J), title('match');


%Brighten(I);
%Contrast(I);
%gammaCorrection(I, 1, 1.2);
%Equal(I);
Match(I, J);

function Brighten(I)
    Brightness = I;
    [R, C] = size(Brightness);
    for i = 1 : R
        for j = 1 : C
            Brightness(i, j) = min(255, Brightness(i, j) + 50);
        end
    end
    subplot(122), imshow(Brightness), title('Brightness');
end

function Contrast(I)
    Contra = I; T = I;
    [R, C] = size(Contra);
    for i = 1 : R
        for j = 1 : C
            T(i, j) = 2 * (Contra(i, j) - 127) + 127;
            Contra(i, j) = max(T(i,j), 0);
            Contra(i, j) = min(Contra(i,j), 255);
        end
    end
    subplot(122), imshow(Contra), title('Contrast');
end

function gammaCorrection(img, a, gamma) %gamma
    I = im2double(img);
    s = a * (I .^ gamma);
    subplot(122), imshow(s), title(sprintf('Gamma: %0.1f', gamma));
end

function Equal(I)
    [R, C, B] = size(I);
    f = Cal_Pro(I);
    for k = 1 : B %reorder pixel histogram
        for i = 1 : 256
            f(k, i) = f(k, i) * 255;
        end
    end
    Eq = double(I);
    for i = 1 : R
        for j = 1 : C
            for k = 1 : B
                Eq(i, j, k) = f(k, I(i, j, k) + 1);
            end
        end
    end
    Eq = uint8(Eq);
    subplot(122), imshow(Eq), title('histogram equalization');
end

function Match(I, J)
    [R0, C0, B0] = size(I);
    [R1, C1, B1] = size(J);

    PI = zeros(B0, 256); PJ = zeros(B1, 256);
    PI = double(PI);     PJ = double(PJ);
    PI = Cal_Pro(I); PJ = Cal_Pro(J);

    LUT = zeros(B0, 256);  %look up table
    for i = 1 : B0
        gJ = 0;
        for gI = 0 : 255
            while PJ(i, gJ + 1) < PI(i, gI + 1) && gJ < 255
                gJ = gJ + 1;
            end
            LUT(i, gI + 1) = gJ;
        end
    end

    I = double(I);  %reallocate color histogram
    for i = 1 : R0
        for j = 1 : C0
            for k = 1 : B0
                I(i, j, k) = LUT(k, I(i, j, k) + 1);
            end
        end
    end
    I = uint8(I);
    subplot(133), imshow(I), title('match result');
end

function pro = Cal_Pro(I)
    [R, C, B] = size(I);  % B is color band number
    cnt = zeros(B, 256);  %get the num of every pixel occur
    for i = 1 : R
        for j = 1 : C
            for k = 1 : B
                cnt(k, I(i, j, k) + 1) = cnt(k, I(i, j, k) + 1) + 1;
            end
        end
    end

    pro = zeros(3, 256); pro = double(pro);
    cnt = double(cnt); num_pix = R * C;
    for k = 1 : B  %get probability
        for i = 1 : 256
            pro(k, i) = cnt(k, i) / num_pix;
        end
    end

    for k = 1 : B  %get cdf
        for i = 2 : 256
            pro(k, i) = pro(k, i - 1) + pro(k, i);
        end
    end
end