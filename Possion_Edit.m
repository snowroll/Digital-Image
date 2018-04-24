function result = Possion_Edit(object, background, insert_x, insert_y, mask)
    [R, C] = find(object > 0);  %找出要融合物体的非零元,新建一个矩阵
    min_L = min(R); max_L = max(R); min_W = min(C); max_W = max(C);  %找出非零元的四个边界
    L = max_L - min_L + 3; W = max_W - min_W + 3;

    New_Object = zeros(L, W); New_Mask = zeros(L, W);
    for i = min_L : max_L
        for j = min_W : max_W
            New_Object(i - min_L + 2, j - min_W + 2) = object(i, j);
            New_Mask(i - min_L + 2, j - min_W + 2) = mask(i, j);
        end
    end

    boundary_filter = zeros(L, W); %检测边界
    bound_ary = zeros(L, W); 
    for i = 1 : L
        for j = 1 : W
            if(boundary_test(New_Mask, i, j) == 1) %1表示是边界
                boundary_filter(i, j) = 1;
                %bound_ary(i, j) = background(double(round(insert_y - L / 2 + i)), double(round(insert_x - W / 2 + j)))
            end
        end
    end

    boundary = zeros(L, W);
    for i = 1 : L
        for j = 1 : W
            if (boundary_test(New_Mask,i,j)==1)  %is a boundary
                boundary(i,j) =  background(double(round(insert_y-L/2+i)),double(round(insert_x-W/2+j)));
            end
        end
    end

    %poisson 编辑
    %第一步 计算粘贴图像的梯度
    grad = zeros(L, W);
    grad_filter = [0  -1 0;
                   -1 4 -1;
                   0  -1 0];
    grad = conv2(double(New_Object), grad_filter, 'same');
    grad = grad .* New_Mask;
    grad = grad .* (1 - boundary_filter);
    grad = grad +boundary;

    grad_filter2 = [0 1 0;
                    1 0 1;
                    0 1 0];
    Ori_Object = double(boundary);
    New_Object = Ori_Object;

    region_no_boundary = New_Mask - boundary_filter;
    for k = 1: 5000
        Rx = conv2(Ori_Object, grad_filter2, 'same');
        for i = 1 : L
            for j = 1 : W
                if(region_no_boundary(i, j) > 0) %在选择的区域里
                    New_Object(i, j) = 1/4 * (grad(i, j) + Rx(i, j));
                end
            end
        end
        Ori_Object = New_Object;
    end
    New_Object = Ori_Object;
    New_Object = New_Object .* New_Mask;

    for i = 1 : L
        for j = 1 : W
            if(New_Object(i, j) ~= 0)
                background(double(round(insert_y - L / 2 + i)), double(round(insert_x - W / 2 + j))) = New_Object(i, j);
            end
        end
    end
    result = uint8(background);
end



function over = boundary_test(img, x, y)  %检测边界，像素点在图像内为0，在边界为1，不在图像上为-1
    [R, C] = size(img);
    if((x - 1 >= 1) && (x + 1 <= R) && (y - 1 >= 1) && (y + 1 <= C))
        over = 0;
        if(img(x, y) ~= 0) 
            if(img(x + 1, y) * img(x - 1, y) * img(x, y + 1) * img(x, y - 1) == 0)
                over = 1;
            end
        else
            over = -1;
        end
    else
        over = -1;
    end
end