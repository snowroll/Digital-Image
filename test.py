# -*- coding: utf-8 -*-
import dlib
import numpy as np
import cv2
import sys

def isInside(rect, point) :
    if point[0] < rect[0] or point[1] < rect[1] or point[0] > rect[2] or point[1] > rect[3]:
        return False
    return True

def getkeypoints(face_path, detector, predictor): #h获取特征点
    face = cv2.imread(face_path)
    dets = detector(face, 1)
    if len(dets) != 1:
        print ("more one face")
        return []
    shape = predictor(face, dets[0])
    keyPoints = []
    for i in range(0,shape.num_parts):  #68个特征点
        keyPoints.append((shape.part(i).x, shape.part(i).y))
    npsize = face.shape
    boundary_point = [(0, 0), (0, npsize[0]-1), (npsize[1]-1, 0), (npsize[1]-1, npsize[0]-1), (0, (npsize[0]-1)/2), ((npsize[1]-1)/2, 0), (npsize[1]-1, (npsize[0]-1)/2), ((npsize[1]-1)/2, npsize[0]-1)]
    for i in range(0 , 7):
        keyPoints.append(boundary_point[i])
    return keyPoints

def find_key_Index(npArray, peak): #找到三角刨分顶点对应的特征点的index
    for i in range(0, npArray.shape[0]):
        if npArray[i,0] == int(peak[0]) and npArray[i,1] == int(peak[1]):
            return i
    return -1

def Add_nozero(face1, face2): #找出图像的非零点
    face3 = face1 + face2
    face3Over = np.transpose(np.nonzero(face1 * face2))  #np.transpose为转置
    for pixel in face3Over:
        face3[pixel[0]][pixel[1]] = face1[pixel[0]][pixel[1]]/2 + face2[pixel[0]][pixel[1]]/2
    return face3

def get_Trianle(Ori_face, tr1, tr2):#三角形的仿射变换
    Conv_face = np.zeros_like(Ori_face) 
    r1 = cv2.boundingRect(tr1) #计算轮廓的垂直边界最小矩形，返回值为(x,y,w,h),为左上角的点的坐标，以及矩形的宽高
    r2 = cv2.boundingRect(tr2)
    tri1Cropped = []
    tri2Cropped = []
	
    for i in range(0, 3):
        tri1Cropped.append(((tr1[0][i][0] - r1[0]),(tr1[0][i][1] - r1[1])))  #这里是得到相对的三角形坐标值，即我们只需要变换最小矩形，不变换整张图像
        tri2Cropped.append(((tr2[0][i][0] - r2[0]),(tr2[0][i][1] - r2[1])))
    img1Cropped = Ori_face[r1[1]:r1[1] + r1[3], r1[0]:r1[0] + r1[2]]  #这里得到最小矩形复制
    warpMat = cv2.getAffineTransform(np.float32(tri1Cropped), np.float32(tri2Cropped)) #仿射变换
    img2Cropped = cv2.warpAffine(img1Cropped, warpMat, (r2[2], r2[3]), None, flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT_101 )#旋转变换
    
    mask = np.zeros((r2[3], r2[2], 3), dtype = np.float32)
    cv2.fillConvexPoly(mask, np.int32(tri2Cropped), (1.0, 1.0, 1.0), 16, 0); #得到三角形的掩码，便于赋值
    img2Cropped = img2Cropped * mask  #下面开始赋像素点值
    Conv_face[r2[1]:r2[1]+r2[3], r2[0]:r2[0]+r2[2]] = Conv_face[r2[1]:r2[1]+r2[3], r2[0]:r2[0]+r2[2]] * ( (1.0, 1.0, 1.0) - mask ) #三角形外赋值为0
    Conv_face[r2[1]:r2[1]+r2[3], r2[0]:r2[0]+r2[2]] = Conv_face[r2[1]:r2[1]+r2[3], r2[0]:r2[0]+r2[2]] + img2Cropped #三角形内赋值为变换的像素点
    return Conv_face

def generateMorphingImage(face1, face2, lm1, lm2, alpha):
    lm3 = lm1*alpha + lm2*(1-alpha) #得到我们需要的图像的特征点的68个位置
    lm3 = lm3.astype("uint32")
    for i in range(0, len(lm3)):
        lm3[i] = (lm3[i, 0], lm3[i, 1])
		
    A = face1.shape
    rect = (0, 0, A[1], A[0])
    subdiv = cv2.Subdiv2D(rect) #三角剖分，Subdiv2D是三角剖分的类，此处是建立一个对象，调用的是构造函数
	
    for i in lm3:        #得到新的三角剖分的点，即是我们需要的图像的特征点的68个位置
        subdiv.insert((i[0], i[1]))
    triangles3 = subdiv.getTriangleList() #从Delaunay三角剖分中计算三角形，使用getTiangleList()函数。
    triangleAsId = [];
    for i in triangles3: #调用之后，在三角形中的每个Vec6f包含三个顶点：（x1,y1,x2,y2,x3,y3,）。将坐标点放入triangleAsid中
        pt1 = (i[0], i[1])
        pt2 = (i[2], i[3])
        pt3 = (i[4], i[5])
        if isInside(rect, pt1) and isInside(rect, pt2) and isInside(rect, pt3):#判断三角形是否在矩形中
            triangleAsId.append([find_key_Index(lm3, pt1), find_key_Index(lm3, pt2), find_key_Index(lm3, pt3)])#这里调用find_key_Index函数，具体作用看函数注释
    
	#构造新的图像
    imgMorphingFrom1 = np.zeros_like(face1) #这个图像用于将src图像通过三角的仿射变换到所得的中间图像
    imgMorphingFrom2 = np.zeros_like(face2) #这个图像用于将dst图像通过三角的仿射变换到所得的中间图像
    for i in range(0, len(triangleAsId)):
		#下面的tr11，tr22,tr33都是把三角形的三点坐标取出，带入函数
        tr11 = np.float32([[[lm1[triangleAsId[i][0]][0], lm1[triangleAsId[i][0]][1]],[lm1[triangleAsId[i][1]][0], lm1[triangleAsId[i][1]][1]],[lm1[triangleAsId[i][2]][0],lm1[triangleAsId[i][2]][1]]]])
        tr33 = np.float32([[[lm3[triangleAsId[i][0]][0], lm3[triangleAsId[i][0]][1]],[lm3[triangleAsId[i][1]][0], lm3[triangleAsId[i][1]][1]],[lm3[triangleAsId[i][2]][0],lm3[triangleAsId[i][2]][1]]]])
        imgMorphingFrom1 = Add_nozero(imgMorphingFrom1, get_Trianle(face1, tr11, tr33)) #src三角仿射得到中间图像，一个三角一个三角的像素点赋值，调用的函数作用见函数注释
        tr22 = np.float32([[[lm2[triangleAsId[i][0]][0], lm2[triangleAsId[i][0]][1]],[lm2[triangleAsId[i][1]][0], lm2[triangleAsId[i][1]][1]],[lm2[triangleAsId[i][2]][0],lm2[triangleAsId[i][2]][1]]]])
        imgMorphingFrom2 = Add_nozero(imgMorphingFrom2, get_Trianle(face2, tr22, tr33)) #dst三角仿射得到中间图像，调用的函数作用见函数注释
		
    imgResult = cv2.addWeighted(imgMorphingFrom1, alpha, imgMorphingFrom2, 1-alpha, 0) #将两个图像加权即为所得图像
    return imgResult

	
#开始基本的输入
predictor_path = "shape_predictor_68_face_landmarks.dat"
face1path = "cruz_re.png"
face2path = "hilary.png"
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(predictor_path)

#得到特征点
landmark1 = getkeypoints(face1path, detector, predictor)
landmark2 = getkeypoints(face2path, detector, predictor)

if len(landmark1)==0 or len(landmark2)==0:
    print( "Error!")

L1 = np.array(landmark1)
L2 = np.array(landmark2)

face1 = cv2.imread(face1path)
face2 = cv2.imread(face2path)


#得到过程中的10张图片
for i in range(1,10):
    result = generateMorphingImage(face1, face2, L1, L2, np.float32(i)/10)
    cv2.imwrite(str(i)+".png", result)







	



