//
//  OpenGLViewController.m
//  陀螺仪Demo
//
//  Created by 张诚 on 14-11-20.
//  Copyright (c) 2014年 zhangcheng. All rights reserved.
//

#import "OpenGLViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"
#import "ZCMotionManager.h"

/*
 iOS研究院 305044955
 本工程是加载3D模型使用，需要改的地方有几个
 1、需要从3DMax中导出obj的模型，之后转换为.h文件，需要在windows本上完成这个操作，之后你会有一个。h文件，这个文件非常大，里面记录4个数据，分别是顶点坐标，法线、纹理，以及还有记录一共多少数据
 2、把这个。h文件加入到工程内，如果电脑不好，你电脑在之后，会写代码完全没提示
 3、替换几个地方  替换_xxVierts、_xxNormals、_xxTexCoords 、_xxNumVerts  这4个数据是你导入的。h文件获得的
 //加载顶点坐标
 self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]
 initWithAttribStride:(3 * sizeof(double))
 numberOfVertices:sizeof(_xxVerts) /
 (3 * sizeof(double))
 bytes:_xxVerts
 usage:GL_STATIC_DRAW];
 //加载法线
 self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]
 initWithAttribStride:(3 * sizeof(double))
 numberOfVertices:sizeof(_xxNormals) /
 (3 * sizeof(double))
 bytes:_xxNormals
 usage:GL_STATIC_DRAW];
 //加载纹理
 self.vertexTexCoordsBuffer=[[AGLKVertexAttribArrayBuffer alloc]
 initWithAttribStride:(3 * sizeof(double))
 numberOfVertices:sizeof(_xxTexCoords) /
 (3 * sizeof(double))
 bytes:_xxTexCoords
 usage:GL_STATIC_DRAW];
 
 [AGLKVertexAttribArrayBuffer
 drawPreparedArraysWithMode:GL_TRIANGLES
 startVertexIndex:0
 numberOfVertices:_xxNumVerts];
 */

@implementation NSData (EnumerateComponents)

- (void)obj_enumerateComponentsSeparatedBy:(NSData *)delimiter usingBlock:(void(^)(NSData *data, BOOL isLast))block
{
    //current location in data
    NSUInteger location = 0;
    
    while (YES) {
        //get a new component separated by delimiter
        NSRange rangeOfDelimiter = [self rangeOfData:delimiter
                                             options:0
                                               range:NSMakeRange(location, self.length - location)];
        
        //has reached the last component
        if (rangeOfDelimiter.location == NSNotFound) {
            break;
        }
        
        NSRange rangeOfNewComponent = NSMakeRange(location, rangeOfDelimiter.location - location + delimiter.length);
        //get the data of every component
        NSData *everyComponent = [self subdataWithRange:rangeOfNewComponent];
        //invoke the block
        block(everyComponent, NO);
        //make the offset of location
        location = NSMaxRange(rangeOfNewComponent);
    }
    
    //reminding data
    NSData *reminder = [self subdataWithRange:NSMakeRange(location, self.length - location)];
    //handle reminding data
    block(reminder, YES);
}

@end

@interface OpenGLViewController ()

@property (strong, nonatomic) NSInputStream     *inputStream;
@property (strong, nonatomic) NSOperationQueue  *queue;
@property (strong, nonatomic) NSMutableData     *reminder;
@property (copy, nonatomic)   NSData            *delimiter;

@end

@implementation OpenGLViewController

static GLKMatrix4 SceneMatrixForTransform(
                                          SceneTransformationSelector type,
                                          SceneTransformationAxisSelector axis,
                                          float value);

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delimiter = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
    [self enumerateOBJFileLines];
}

- (void)resetDatas
{
    //处理verts
    float diffa = maxVertX - minVertX;
    float diffb = maxVertY - minVertY;
    float diffc = maxVertZ - minVertZ;
    float scalefac = MAX(MAX(diffa, diffb), diffc);
    scalefac = 1/scalefac;
    float centerVertX = sumVertX/(float)_xxNumVerts;
    float centerVertY = sumVertY/(float)_xxNumVerts;
    float centerVertZ = sumVertZ/(float)_xxNumVerts;
    for(int i=0;i<_xxNumFaces;i++)
    {
        _fixVerts[i*9]   = (_xxVerts[v_idx[i][0]*3]-centerVertX)*scalefac;;
        _fixVerts[i*9+1] = (_xxVerts[v_idx[i][0]*3+1]-centerVertY)*scalefac;
        _fixVerts[i*9+2] = (_xxVerts[v_idx[i][0]*3+2]-centerVertZ)*scalefac;
        _fixVerts[i*9+3] = (_xxVerts[v_idx[i][1]*3]-centerVertX)*scalefac;
        _fixVerts[i*9+4] = (_xxVerts[v_idx[i][1]*3+1]-centerVertY)*scalefac;
        _fixVerts[i*9+5] = (_xxVerts[v_idx[i][1]*3+2]-centerVertZ)*scalefac;
        _fixVerts[i*9+6] = (_xxVerts[v_idx[i][2]*3]-centerVertX)*scalefac;
        _fixVerts[i*9+7] = (_xxVerts[v_idx[i][2]*3+1]-centerVertY)*scalefac;
        _fixVerts[i*9+8] = (_xxVerts[v_idx[i][2]*3+2]-centerVertZ)*scalefac;
    }
    
    //处理法线
    for(int i=0;i<_xxNumNormals;i++)
    {
        float a = _xxNormals[i*3];
        float b = _xxNormals[i*3+1];
        float c = _xxNormals[i*3+2];
        float d = sqrt(a*a+b*b+c*c);
        if(d==0)
        {
            _xxNormals[i*3] = 1;
            _xxNormals[i*3+1] = 0;
            _xxNormals[i*3+2] = 0;
        }
        else{
            _xxNormals[i*3] = a/d;
            _xxNormals[i*3+1] = b/d;
            _xxNormals[i*3+2] = c/d;
        }
    }
    for(int i=0;i<_xxNumFaces;i++)
    {
        _fixNormals[i*9]   = _xxNormals[n_idx[i][0]*3];
        _fixNormals[i*9+1] = _xxNormals[n_idx[i][0]*3+1];
        _fixNormals[i*9+2] = _xxNormals[n_idx[i][0]*3+2];
        _fixNormals[i*9+3] = _xxNormals[n_idx[i][1]*3];
        _fixNormals[i*9+4] = _xxNormals[n_idx[i][1]*3+1];
        _fixNormals[i*9+5] = _xxNormals[n_idx[i][1]*3+2];
        _fixNormals[i*9+6] = _xxNormals[n_idx[i][2]*3];
        _fixNormals[i*9+7] = _xxNormals[n_idx[i][2]*3+1];
        _fixNormals[i*9+8] = _xxNormals[n_idx[i][2]*3+2];
    }
    
    //处再texCoords
    for(int i=0;i<_xxNumFaces;i++)
    {
        _fixTexCoords[i*6]   = _xxTexCoords[t_idx[i][0]*2];
        _fixTexCoords[i*6+1] = _xxTexCoords[t_idx[i][0]*2+1];
        _fixTexCoords[i*6+2] = _xxTexCoords[t_idx[i][1]*2];
        _fixTexCoords[i*6+3] = _xxTexCoords[t_idx[i][1]*2+1];
        _fixTexCoords[i*6+4] = _xxTexCoords[t_idx[i][2]*2];
        _fixTexCoords[i*6+5] = _xxTexCoords[t_idx[i][2]*2+1];
    }
    
    dispatch_async(dispatch_get_main_queue(),^{[self drawGL];});
}

- (void)drawGL
{
    //声明
    GLKView *view = (GLKView *)self.view;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    view.context = [[AGLKContext alloc]
                    initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:view.context];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    
    // Configure a light to simulate the Sun
    self.baseEffect.light0.enabled = GL_TRUE;
//    
//    //设置背景颜色
    ((AGLKContext *)view.context).clearColor = GLKVector4Make(
                                                              0.0f, // Red
                                                              0.5f, // Green
                                                              0.0f, // Blue
                                                              1.0f);// Alpha
    
    //加载顶点坐标
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                 initWithAttribStride:(3 * sizeof(GLfloat))
                                 numberOfVertices:_xxNumFaces*3
                                 bytes:_fixVerts
                                 usage:GL_STATIC_DRAW];
    //加载法线
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                               initWithAttribStride:(3 * sizeof(GLfloat))
                               numberOfVertices:_xxNumFaces*3
                               bytes:_fixNormals
                               usage:GL_STATIC_DRAW];
    //加载纹理
    self.vertexTexCoordsBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                initWithAttribStride:(3 * sizeof(GLfloat))
                                numberOfVertices:_xxNumFaces*2
                                bytes:_fixTexCoords
                                usage:GL_STATIC_DRAW];
    
    [((AGLKContext *)view.context) enable:GL_DEPTH_TEST];
    
    GLKMatrix4 modelviewMatrix = GLKMatrix4MakeRotation(
                                                        GLKMathDegreesToRadians(30.0f),
                                                        1.0,  // Rotate about X axis
                                                        0.0,
                                                        0.0);
    modelviewMatrix = GLKMatrix4Rotate(
                                       modelviewMatrix,
                                       GLKMathDegreesToRadians(-30.0f),
                                       0.0,
                                       1.0,  // Rotate about Y axis
                                       0.0);
    modelviewMatrix = GLKMatrix4Translate(
                                          modelviewMatrix,
                                          -0.25,
                                          0.0,
                                          -0.20);
    
    self.baseEffect.transform.modelviewMatrix = modelviewMatrix;
    
    [((AGLKContext *)view.context) enable:GL_BLEND];
    [((AGLKContext *)view.context)
     setBlendSourceFunction:GL_SRC_ALPHA
     destinationFunction:GL_ONE_MINUS_SRC_ALPHA];
    
    
    /*********************/
    //设置转换模式R 按照中心点进行旋转
    transform1Type=0;
    transform2Type=1;
    transform3Type=2;
    //设置xyz
    transform1Axis=0;
    transform2Axis=1;
    transform3Axis=2;
    
    
    //    manager=[ZCMotionManager shareManager];
    //    [manager starUpdatesBlock:^(CMDeviceMotion *motion) {
    //
    //        transform1Value=motion.attitude.pitch;
    //        transform2Value=motion.attitude.yaw;
    //        transform3Value=motion.attitude.roll;
    //
    //    }];
    /*********************/
    //添加捏合手势，模型的放大和缩小
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchClick:)];
    [self.view addGestureRecognizer:pinch];
    /*对于移动3D模型x为左右移动  y为上下移动  */
    //添加移动手势，控制模型的移动
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panClick:)];
    [self.view addGestureRecognizer:pan];
}

-(void)panClick:(UIPanGestureRecognizer*)pan{
//记录上一个点 然后下一个点之间的x轴和y轴
    if (pan.state==UIGestureRecognizerStateBegan) {
        panPoint=[pan locationInView:pan.view];
        return;
    }else{
        CGPoint location = [pan locationInView:pan.view];
        //计算x和y的偏差
        float x=location.x-panPoint.x;
        float y=panPoint.y-location.y;
        panPoint=location;
        panX=x/100.0+panX;
        panY=y/100.0+panY;
        
        
        NSLog(@"%f~~%f",panX,panY);
    
    }
}

-(void)pinchClick:(UIPinchGestureRecognizer*)pinch{
    
    //放大范围控制在-0.05~2之间
    float x=transformScale+(pinch.scale-1);
    if (x<-0.5) {
        transformScale=-0.5;
    }else{
        if (x>2.0) {
            x=2;
        }
        transformScale=x;
        
    }
}

//这里开始绘制模型,该方法会一直调用
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    const double  aspectRatio =
    (double)view.drawableWidth / (double)view.drawableHeight;
    
    //旋转角度
    self.baseEffect.transform.projectionMatrix =
    GLKMatrix4MakeOrtho(
                        -0.5 * aspectRatio,
                        0.5 * aspectRatio,
                        -0.5,
                        0.5,
                        -5.0,
                        5.0);
    
    // Clear back frame buffer (erase previous drawing)
    [((AGLKContext *)view.context)
     clear:GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT];
  

    [self.vertexPositionBuffer
     prepareToDrawWithAttrib:GLKVertexAttribPosition
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexNormalBuffer
     prepareToDrawWithAttrib:GLKVertexAttribNormal
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexTexCoordsBuffer
     prepareToDrawWithAttrib:GLKVertexAttribTexCoord1
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];

    //读取之前的默认位置
    GLKMatrix4 savedModelviewMatrix =
    self.baseEffect.transform.modelviewMatrix;
    
    
    
    //设置空间位置移动 SceneMatrixForTransform代表空间位置  1Axis代表x  2Axis代表y 3Axis代表z
    /*********************************/
    //修改按照中心点进行旋转的,也就是依照陀螺仪进行旋转
    GLKMatrix4 newModelviewMatrix =
    GLKMatrix4Multiply(savedModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform2Type,
                                               transform1Axis,
                                               transform1Value));
    newModelviewMatrix =
    GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform2Type,
                                               transform2Axis,
                                               transform2Value));
    newModelviewMatrix =
    GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform2Type,
                                               transform3Axis,
                                               transform3Value));
    
    //修改模型放大和缩小
    newModelviewMatrix =
GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform3Type,
                                               transform1Axis,
                                               transformScale));
    newModelviewMatrix =
    GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform3Type,
                                               transform2Axis,
                                               transformScale));
    newModelviewMatrix =
    GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform3Type,
                                               transform3Axis,
                                               transformScale));
    
    //修改模型移动的位置
    newModelviewMatrix =
    GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform1Type,
                                               transform1Axis,
                                               panX));
    newModelviewMatrix =
    GLKMatrix4Multiply(newModelviewMatrix,
                       SceneMatrixForTransform(
                                               transform1Type,
                                               transform2Axis,
                                               panY));
//    newModelviewMatrix =
//    GLKMatrix4Multiply(newModelviewMatrix,
//                       SceneMatrixForTransform(
//                                               transform1Type,
//                                               transform3Axis,
//                                               transformScale));
    
    
    
    
    // Set the Modelview matrix for drawing
    self.baseEffect.transform.modelviewMatrix = newModelviewMatrix;
    
    //设置模型颜色
//    self.baseEffect.light0.diffuseColor = GLKVector4Make(
//                                                         0.8f, // Red
//                                                         0.4f, // Green
//                                                         1.0f, // Blue
//                                                         1.0f);// Alpha

    
    [self.baseEffect prepareToDraw];
    
    // Draw triangles using vertices in the prepared vertex
    // buffers
    [AGLKVertexAttribArrayBuffer
     drawPreparedArraysWithMode:GL_TRIANGLES
     startVertexIndex:0
     numberOfVertices:_xxNumFaces*3];
    
    // Restore the saved Modelview matrix
    self.baseEffect.transform.modelviewMatrix = 
    savedModelviewMatrix;
    

    //prepareToDraw会在重复绘制一个新的Draw
    //[self.baseEffect prepareToDraw];
//   [AGLKVertexAttribArrayBuffer
//     drawPreparedArraysWithMode:GL_TRIANGLES
//     startVertexIndex:0
//     numberOfVertices:_xxNumVerts];
}
static GLKMatrix4 SceneMatrixForTransform(
                                          SceneTransformationSelector type,
                                          SceneTransformationAxisSelector axis,
                                          float value)
{
    GLKMatrix4 result = GLKMatrix4Identity;
    
    switch (type) {
        case SceneRotate:
            switch (axis) {
                case SceneXAxis:
                    result = GLKMatrix4MakeRotation(
                                                    GLKMathDegreesToRadians(180.0 * value),
                                                    1.0,
                                                    0.0,
                                                    0.0);
                    break;
                case SceneYAxis:
                    result = GLKMatrix4MakeRotation(
                                                    GLKMathDegreesToRadians(180.0 * value),
                                                    0.0,
                                                    1.0,
                                                    0.0);
                    break;
                case SceneZAxis:
                default:
                    result = GLKMatrix4MakeRotation(
                                                    GLKMathDegreesToRadians(180.0 * value),
                                                    0.0,
                                                    0.0,
                                                    1.0);
                    break;
            }
            break;
        case SceneScale:
            switch (axis) {
                case SceneXAxis:
                    result = GLKMatrix4MakeScale(
                                                 1.0 + value,
                                                 1.0,
                                                 1.0);
                    break;
                case SceneYAxis:
                    result = GLKMatrix4MakeScale(
                                                 1.0,
                                                 1.0 + value,
                                                 1.0);
                    break;
                case SceneZAxis:
                default:
                    result = GLKMatrix4MakeScale(
                                                 1.0, 
                                                 1.0, 
                                                 1.0 + value);
                    break;
            }
            break;
        default:
            switch (axis) {
                case SceneXAxis:
                    result = GLKMatrix4MakeTranslation(
                                                       0.3 * value, 
                                                       0.0, 
                                                       0.0);
                    break;
                case SceneYAxis:
                    result = GLKMatrix4MakeTranslation(
                                                       0.0, 
                                                       0.3 * value, 
                                                       0.0);
                    break;
                case SceneZAxis:
                default:
                    result = GLKMatrix4MakeTranslation(
                                                       0.0, 
                                                       0.0, 
                                                       0.3 * value);
                    break;
            }
            break;
    }
    
    return result;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 读取文件
- (void)enumerateOBJFileLines
{
    //initial the NSOperationQueue whice can only be sequencial
    if (self.queue == nil) {
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
    }
    
    NSAssert(self.queue.maxConcurrentOperationCount == 1, @"Cannot read file concurrently");
    NSAssert(self.inputStream == nil, @"Cannot progress multiple input stream in parallel");
    
    //we use NSInputStream to read file
    //here the delegate should be retained(NO ARC) or the global variable(ARC)
    NSURL *fileURL = [NSURL fileURLWithPath:_filepath];
    self.inputStream = [NSInputStream inputStreamWithURL:fileURL];
    self.inputStream.delegate = self;
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
            
        case NSStreamEventOpenCompleted:
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccureed: error when reading file");
            break;
            
        case NSStreamEventEndEncountered: {
            [self emitLineWithData:self.reminder];          //handle last part of data
            self.reminder = nil;
            [self.inputStream close];
            self.inputStream = nil;
            [self.queue addOperationWithBlock:^{
                [self resetDatas];
            }];
            break;
        }
            
        case NSStreamEventHasBytesAvailable: {
            NSMutableData *buffer = [[NSMutableData alloc] initWithLength:44 * 1024];
            NSUInteger length = (NSUInteger)[self.inputStream read:[buffer mutableBytes] maxLength:[buffer length]];
            if (length > 0) {
                [buffer setLength:length];
                __weak id weakSelf = self;
                [self.queue addOperationWithBlock:^{
                    [weakSelf processDataChunk:buffer];
                }];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)emitLineWithData:(NSData *)data
{
    //invoke the block to handle these data
    if (data.length > 0) {
        //get content of current line
        @autoreleasepool {
            NSString *line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if (line.length >3) {
                line = [line stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
                if ([[line substringToIndex:3] isEqualToString:@"vt "]) {
                    NSArray *arrayTmp = [line componentsSeparatedByString:@" "];
                    _xxTexCoords[_xxNumTexCoords*2] = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:1]] floatValue];
                    _xxTexCoords[_xxNumTexCoords*2+1] = 1-[[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:2]] floatValue];
                    _xxNumTexCoords++;
                }
                else if ([[line substringToIndex:3] isEqualToString:@"vn "]) {
                    NSArray *arrayTmp = [line componentsSeparatedByString:@" "];
                    _xxNormals[_xxNumNormals*3] = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:1]] floatValue];
                    _xxNormals[_xxNumNormals*3+1] = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:2]] floatValue];
                    _xxNormals[_xxNumNormals*3+2] = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:3]] floatValue];
                    _xxNumNormals++;
                }
                else if ([[line substringToIndex:2] isEqualToString:@"v "]) {
                    NSArray *arrayTmp = [line componentsSeparatedByString:@" "];
                    NSMutableArray *mutArray = [arrayTmp mutableCopy];[mutArray removeObject:@""];
                    arrayTmp = mutArray;
                    float a = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:1]] floatValue];
                    float b = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:2]] floatValue];
                    float c = [[NSDecimalNumber decimalNumberWithString:[arrayTmp objectAtIndex:3]] floatValue];
                    if(_xxNumVerts==0)
                    {
                        minVertX = a;
                        maxVertX = a;
                        minVertY = b;
                        minVertY = b;
                        minVertZ = c;
                        minVertZ = c;
                    }
                    else{
                        if(minVertX>a)
                        {
                            minVertX = a;
                        }
                        if(maxVertX<a)
                        {
                            maxVertX = a;
                        }
                        if(minVertY>b)
                        {
                            minVertY = b;
                        }
                        if(maxVertY<b)
                        {
                            maxVertY = b;
                        }
                        if(minVertZ>c)
                        {
                            minVertZ = c;
                        }
                        if(maxVertZ<c)
                        {
                            maxVertZ = c;
                        }
                    }
                    sumVertX += a;
                    sumVertY += b;
                    sumVertZ += c;
                    _xxVerts[_xxNumVerts*3] = a;
                    _xxVerts[_xxNumVerts*3+1] = b;
                    _xxVerts[_xxNumVerts*3+2] = c;
                    _xxNumVerts++;
                }
                else if ([[line substringToIndex:2] isEqualToString:@"f "]) {
                    NSArray *arrayTmp = [line componentsSeparatedByString:@" "];
                    if(arrayTmp.count>3 && ![[arrayTmp objectAtIndex:3] isEqualToString:@""])
                    {
                        NSArray *a = [[arrayTmp objectAtIndex:1] componentsSeparatedByString:@"/"];
                        NSArray *b = [[arrayTmp objectAtIndex:2] componentsSeparatedByString:@"/"];
                        NSArray *c = [[arrayTmp objectAtIndex:3] componentsSeparatedByString:@"/"];
//                        if(a.count==1)
//                        {
//                            NSLog(@"a=%@",a);
//                        }
//                        if(b.count==1)
//                        {
//                            NSLog(@"b=%@",b);
//                        }
//                        if(c.count==1)
//                        {
//                            NSLog(@"%@",line);
//                            NSLog(@"arrayTemp=%@",arrayTmp);
//                        }
                        v_idx[_xxNumFaces][0] = [[a objectAtIndex:0] intValue]-1;
                        v_idx[_xxNumFaces][1] = [[b objectAtIndex:0] intValue]-1;
                        v_idx[_xxNumFaces][2] = [[c objectAtIndex:0] intValue]-1;
                        t_idx[_xxNumFaces][0] = [[a objectAtIndex:1] intValue]-1;
                        t_idx[_xxNumFaces][1] = [[b objectAtIndex:1] intValue]-1;
                        t_idx[_xxNumFaces][2] = [[c objectAtIndex:1] intValue]-1;
                        n_idx[_xxNumFaces][0] = [[a objectAtIndex:2] intValue]-1;
                        n_idx[_xxNumFaces][1] = [[b objectAtIndex:2] intValue]-1;
                        n_idx[_xxNumFaces][2] = [[c objectAtIndex:2] intValue]-1;
                        _xxNumFaces++;
                        
                        if([[line componentsSeparatedByString:@" "] count] == 6)
                        {
                            NSArray *d = [[arrayTmp objectAtIndex:4] componentsSeparatedByString:@"/"];
                            v_idx[_xxNumFaces][0] = [[a objectAtIndex:0] intValue]-1;
                            v_idx[_xxNumFaces][1] = [[d objectAtIndex:0] intValue]-1;
                            v_idx[_xxNumFaces][2] = [[c objectAtIndex:0] intValue]-1;
                            t_idx[_xxNumFaces][0] = [[a objectAtIndex:1] intValue]-1;
                            t_idx[_xxNumFaces][1] = [[d objectAtIndex:1] intValue]-1;
                            t_idx[_xxNumFaces][2] = [[c objectAtIndex:1] intValue]-1;
                            n_idx[_xxNumFaces][0] = [[a objectAtIndex:2] intValue]-1;
                            n_idx[_xxNumFaces][1] = [[d objectAtIndex:2] intValue]-1;
                            n_idx[_xxNumFaces][2] = [[c objectAtIndex:2] intValue]-1;
                            _xxNumFaces++;
                        }
                    }
                }
            }
        }
    }
}

- (void)processDataChunk:(NSMutableData *)buffer
{
    if (self.reminder == nil) {
        self.reminder = buffer;
    } else {
        //last chunk of data have some data (part of last line) reminding.
        [self.reminder appendData:buffer];
    }
    
    //separate self.reminder to lines and handle them
    [self.reminder obj_enumerateComponentsSeparatedBy:self.delimiter usingBlock:^(NSData *data, BOOL isLast) {
        
        //if it isn't last line. handle each one
        if (isLast == NO) {
            [self emitLineWithData:data];
        } else if (data.length > 0) {
            //if last line has some data reminding, save these data
            self.reminder = [data mutableCopy];
        } else {
            self.reminder = nil;
        }
    }];
}

@end
