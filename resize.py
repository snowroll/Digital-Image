# -*- coding: utf-8 -*-
import Image
 
infile1 = 'cruz.png'
infile2 = 'hilary.png'
outfile = 'cruz_re.png'
im = Image.open(infile1)
im2 = Image.open(infile2)
(x,y) = im.size #read image size
(x2, y2) = im2.size
out = im.resize((x2, y2),Image.ANTIALIAS) #resize image with high-quality
out.save(outfile)
 
 