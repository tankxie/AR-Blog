
> 本文主要讲解如何加载一些3D模型到AR项目中去。


## 0. 写在前面
本文分三节内容：

- 第一节会介绍与之相关的一些基本概念；
- 第二节讲述如何具体实施；
- 第三节小结。

本文开发环境如下：

- Xcode Version 9.4 beta 
- iPhone X iOS 11.4 beta

本文会完成一个[Demo，放在GitHub上面](https://github.com/tankxie/AR-Blog/tree/master/Load3DContentToNode)。


##1. 相关的概念

### 1.1 scene 和 node

新建基于SceneKit的AR project时候，系统默认生成一个`ship.scn`文件，这个文件就是一个 scene（场景）文件，在这个文件中，ship是其中的一个node，3D模型必须“附着”在node上才能被呈现。

在之前的文章[《iOS AR开发基础02 | ARKit开发基本套路和核心API》](https://www.jianshu.com/p/0a67582f201d)中有讲到相关概念，如果还有对这个概念模糊的话，请移步去翻阅。

### 1.2 SCNReferenceNode类

SCNReferenceNode是用来从场景文件中加载node。

接下来分析一下这个类，加深对它的理解！

reference ，引用的意思，这个词在oc中很常见，一个实例的引用，表示指向该实例的指针。

那么，reference node 到底是什么意思？我们先给SCNReferenceNode下一个定义：

**SCNReferenceNode 是 SCNNode的一个子类，用来表示从外部场景文件中加载的node。**

SCNReferenceNode 有两个重要的方法：

- `init?(url: URL)`方法，使用改方法来实例化SCNReferenceNode，传入的参数是场景文件的地址，注意，新生成的SCNReferenceNode对象是没有“附着”任何内容的，是个空白的node
- `load()`方法，只有运行该方法之后，才会将场景文件中的内容，加载到我们上一步实例化的node中

结合上面两个方法可以看出，我新实例化的SCNReferenceNode是没有内容的，它只是一个引用，指向外部场景文件的某些内容，只有当我们运行load()方法之后，这些"外部场景文件中的内容"才会加载进来！！！！

所以，我们前面给出的，对SCNReferenceNode的定义不是很准确，我们需要重新描述一下:

**SCNReferenceNode 是 SCNNode的一个子类，SCNReferenceNode实例在调用`load()`方法之前，它只是一个空的占位符，在调用`load()`方法之后，它用来呈现“外部的场景文件中的内容”**

## 2. 从不同类型的场景文件中加载3D模型

新建一个AR project，选用SceneKit作为渲染引擎。

![image.png](https://upload-images.jianshu.io/upload_images/1444901-0041798a7575bf32.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

在ViewController中，默认生成的代码中，向我们展示了如何加载 ship.scn 文件：

```
let scene = SCNScene(named: "art.scnassets/ship.scn")!
```

默认生成的代码中，将上面获取到的scene赋给sceneView的scene属性，我们在真机上run这个project，在我们屏幕上就会出现这个ship。

但是通常我们开发的过程中，我们并不是直接修改我们当前sceneView的scene属性，我们通常是在现有的scene中，添加或者删除node。所以，我们更多时候的需求是“将scene文件中的内容添加到某个node上面”！

明白我们的需求之后，我们开始编写demo，我们删除系统默认的生成的代码，demo实现的功能是，通过ARKit进行水平面检测，将scene中的node放到我们检测到的平面上。

删除`viewDidLoad`中加载 ship.scn 文件的代码，然后开始撸我们自己的工程。

### 2.1 从加载dae文件中加载3D模型

> 项目中用到的资源放在 resource.zip 压缩包中。

 将资源文件添加到project中来，资源文件中包含，三个文件，其中dea文件是模型，另外两个png是模型上的贴纸！
 
![image.png](https://upload-images.jianshu.io/upload_images/1444901-fd287e5f7e0af30b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


新建一个类 `BadyGrootNode` 类，继承自SCNNode，这个node用来“附着”3D模型。

实现思路是实例化一个`SCNReferenceNode`,用来**加载**dae文件中的内容，然后这个 reference node 作为子node添加到`BadyGrootNode`上，返回`BadyGrootNode`实例。

给这个类添加init方法：

```
 override init(){
        super.init()
        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "dae") else {
            fatalError("baby_groot.dae not exit.")
        }
        guard let customNode = SCNReferenceNode(url: url) else {
            fatalError("load baby_groot error.")
        }
        customNode.load()
        self.addChildNode(customNode)
    }
    
```

在里面就用到了**1.2节**中提到的两个方法！！


然后在实现`ARSCNViewDelegate`方法，当系统检测到水平面之后，将这个`BadyGrootNode`实例添加到平面anchor上。

```
func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor  else { return }
        print("-----------------------> session did add anchor!")
        node.addChildNode(customNode)
    }
    
```

效果如下：

![image.png](https://upload-images.jianshu.io/upload_images/1444901-4e810f8cb1a50569.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



### 2.2 从加载obj文件中加载3D模型

现在我们用obj格式的素材，步骤还是一样，先导入原材料到项目中。

![image.png](https://upload-images.jianshu.io/upload_images/1444901-fd8a33579aa38e11.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



理论上讲，我们只要将上面加载模型的代码稍微改动一下，就可以直接将我们obj格式的模型加载出来。

```
//        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "dae") else {
//            fatalError("baby_groot.dae not exit.")
//        }
        
        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "obj") else {
            fatalError("baby_groot.obj not exit.")
        }
```

好，改完run一把发现，小人是加载出来了，但是黑乎乎的，看不清楚。

此时我们在scene editor中预览我们的模型文件，发现果然是黑乎乎的：

![image.png](https://upload-images.jianshu.io/upload_images/1444901-b3b30d07eca8e421.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



额。。。

明明是一份3D文件，只是不同格式导出，怎么有如此差异？？

莫慌，一般来说，这种看不清的情况大都是由于light造成的，我们试着添加一个light试一下，选择一个Omni light添加到editor中。

![image.png](https://upload-images.jianshu.io/upload_images/1444901-7a67352224739701.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![image.png](https://upload-images.jianshu.io/upload_images/1444901-b37b0efbd80b2316.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)





此时发现，小人变亮了，但是身上貌似没有贴纸。怎么办？？？

这种材质没有加载出来的情况，去查看一下Diffuse，选择一个Diffuse试一下，然鹅，选了还是不行，预览并没有按照我们预期出来。

![image.png](https://upload-images.jianshu.io/upload_images/1444901-8c918ee372c1914b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



run我们的项目，和预期一样，出现的小人没有贴纸。

此时，我做了以下假设，SceneKit在对.obj格式的文件加载兼容性不好。（此假设纯属个人推论，没有官方依据，酌情接受）

兼容性不好怎么办？那就转化成兼容性好的呗，比如说dae，比如说scn。

Xcode为我们提供了转化工具，如下方法使用：

![image.png](https://upload-images.jianshu.io/upload_images/1444901-bf35f8a70497fe41.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


点击选择之后，会弹出一个弹窗，现在convert：

![image.png](https://upload-images.jianshu.io/upload_images/1444901-4e72efa8e622524b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


转化之后，我们发现 .obj 格式的文件已经转化成.scn格式的文件了。

![image.png](https://upload-images.jianshu.io/upload_images/1444901-aa38b52a48624496.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



### 2.3 从加载scn文件中加载3D模型



此时，我们只要将`BadyGrootNode`中的init方法稍作改动就可以完成scn文件的加载：

```
//        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "dae") else {
//            fatalError("baby_groot.dae not exit.")
//        }
        
        guard  let url = Bundle.main.url(forResource: "baby_groot", withExtension: "scn") else {
            fatalError("baby_groot.scn not exit.")
        }
```

运行一下，效果如下：

![image.png](https://upload-images.jianshu.io/upload_images/1444901-900f7b8c4a6b1e44.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



###2.4 扩展

- 我们发现2.3加载出来的模型2.1加载出来的模型大很多，可以通过调节node的scale来使其变小，此处也不做详细讲述；
- 2.3加载出来的模型灯光看着比较亮，不柔和，这是因为我只加了一个灯，具体的灯光设计不属于本文的范畴，此处也不做详细讲述；
- 3D文件还有很多格式，此处不一一列举实验了，有需求的小伙伴可以按照上面的思路自己尝试。

**另外，由于scn格式文件是scene editor直接可用的，还有其他思路可以从scn文件中加载node**，比如：

- 先通过`SCNScene(named: "baby_groot.scn")!`取到scene
- 然后在通过遍历sceneView.scene.rootNode.childNodes的方式，获取你需要的node

这种方式灵活性更高，你可以在开发中按需选择不同的方式！！！

所以此时，我们再回看我们的2.1小节，我们可以在一开始就把dae转化成为scn文件。

## 3. 小结

本文讲述了如何加载自定义的3D模型到你的AR项目中，希望可以对你的思路有所启发。
如果您对文中内容有疑问，欢迎和我沟通指正。






