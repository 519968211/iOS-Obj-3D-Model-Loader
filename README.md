# iOS-Obj-3D-Model-Loader
load .obj 3d model file in iOS app and show in opengl

    本项目是取自github上的iOS_3DMax-master进行了修改。
    原项目需要通过github上的HBehrens-obj2opengl项目把OBJ文件转换成.h文件再引入Xcode中使用,这样不能实现动态加载，而且生成的.h文件可能会很大，我有
一个5MB的OBJ文件生成的.h文件有40多MB，通过Xcode打开这个.h文件会造成Xcode卡顿很久，我自己参照HBehrens-obj2opengl项目中的obj2oopengl.pl(perl语
言命令)的内容自己写了一个算法来读取OBJ文件并把数据存储到内存（数组形式xxVerts,xxNormals,xxTexCoords），xxVerts长度为法线量x3, xxNormals长度为法
线量x3,xxTexCoords长度为法线量x2。
    我也用过Scenekit直接加载obj或者加载包含obj+mtl的.scnassets，显示的效果纯黑或纯白，虽然可以加光照显示细节，但不能显示OBJ模型原本的颜色，有用
SceneKit解决了这个问题的朋友请指点一下email:519968211@qq.com。

