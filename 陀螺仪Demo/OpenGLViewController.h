//
//  OpenGLViewController.h
//  陀螺仪Demo
//
//  Created by 张诚 on 14-11-20.
//  Copyright (c) 2014年 zhangcheng. All rights reserved.
//

#import <GLKit/GLKit.h>
@class AGLKVertexAttribArrayBuffer;
typedef enum
{
	SceneTranslate = 0,
	SceneRotate,
	SceneScale,
} SceneTransformationSelector;

typedef enum
{
	SceneXAxis = 0,
	SceneYAxis,
	SceneZAxis,
} SceneTransformationAxisSelector;
@interface OpenGLViewController : GLKViewController <NSStreamDelegate>
{
    float _xxVerts[2000000];
    float _xxNormals[2000000];
    float _xxTexCoords[2000000];
    float _fixVerts[2000000];
    float _fixNormals[2000000];
    float _fixTexCoords[2000000];
    unsigned int v_idx[2000000][3];
    unsigned int n_idx[2000000][3];
    unsigned int t_idx[2000000][3];
    float maxVertX;
    float maxVertY;
    float maxVertZ;
    float minVertX;
    float minVertY;
    float minVertZ;
    float sumVertX;
    float sumVertY;
    float sumVertZ;
    unsigned int _xxNumVerts;
    unsigned int _xxNumNormals;
    unsigned int _xxNumTexCoords;
    unsigned int _xxNumFaces;
    
    SceneTransformationSelector      transform1Type;
    SceneTransformationAxisSelector  transform1Axis;
    float                            transform1Value;
    SceneTransformationSelector      transform2Type;
    SceneTransformationAxisSelector  transform2Axis;
    float                            transform2Value;
    SceneTransformationSelector      transform3Type;
    SceneTransformationAxisSelector  transform3Axis;
    float                            transform3Value;
    
    //放大的倍率
    float                            transformScale;
    //记录上一个中心点的坐标
    CGPoint                          panPoint;
    float                            panX;
    float                            panY;
}


@property (nonatomic, retain) NSString *filepath;
@property (strong, nonatomic) GLKBaseEffect
*baseEffect;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer
*vertexPositionBuffer;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer
*vertexNormalBuffer;
@property (strong,nonatomic)  AGLKVertexAttribArrayBuffer
*vertexTexCoordsBuffer;


@end
