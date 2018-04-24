source = imread('test1_src.jpg'); 
background = imread('test1_target.jpg');
ROI_Mask = im2bw(imread('test1_mask.jpg'));  %把图像变�?2值图像，纯黑和纯�?

S_R = double(source(:, :, 1));  back_R = background(:, :, 1);
S_G = double(source(:, :, 2));  back_G = background(:, :, 2);
S_B = double(source(:, :, 3));  back_B = background(:, :, 3);
subplot(121), imshow(S_G);
subplot(122), imshow(back_G);


ROI_Mask = double(ROI_Mask);  %标记要截取的目标图像区域g
object_R = S_R .* ROI_Mask;
object_G = S_G .* ROI_Mask;
object_B = S_B .* ROI_Mask;

object(:, :, 1) = object_R(:, :);
object(:, :, 2) = object_G(:, :);
object(:, :, 3) = object_B(:, :);
imshow(uint8(object)), title('object');

figure, imshow(background);  %选取植入�?
[insert_x, insert_y] = ginput(1);
close all;

%分成单色处理
result_R = Possion_Edit(object_R, back_R, insert_x, insert_y, ROI_Mask);
result_G = Possion_Edit(object_G, back_G, insert_x, insert_y, ROI_Mask);
result_B = Possion_Edit(object_B, back_B, insert_x, insert_y, ROI_Mask);

result(:, :, 1) = result_R(:, :);  %拼接结果图像
result(:, :, 2) = result_G(:, :);
result(:, :, 3) = result_B(:, :);
imshow(result), title('poisson edit result');