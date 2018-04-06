> 本篇写一个 AR demo，demo包含三个部分的内容：
> 
> - 基于后置摄像头的平面检测
> - 基于前置摄像头的人脸追踪
> - 基于ARKit的图像识别

## 写在前面
本文在一个项目中实现引言部分提到的三个AR功能，由于是一个AR 的 Hello World 项目，本文只编写实现 AR 功能的核心代码，和 3D 渲染相关的内容本文只展示代码，不会详细讲解，后面的文章会做系统的讲解。


本文内容结构如下：

![本文内容结构](https://upload-images.jianshu.io/upload_images/1444901-ccc7f1250fe45acb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

[本文简书地址](https://www.jianshu.com/p/3e96a74a84fd)。

## 1. 搭建第一个AR项目
### 1.1 搭建过程

本文的开发环境：Xcode9.3 + iPhone X真机 iOS 11.3。

打开Xcode > Create a new Xcode project > Augmented Reality App > next，如下图：

![新建项目-1](https://upload-images.jianshu.io/upload_images/1444901-af6acc38fdfa0846.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

应用名称命名为 HelloWorld，开发语言选swift，Content Technology 选择 SceneKit，然后点击下一步：

![新建项目-2](https://upload-images.jianshu.io/upload_images/1444901-e8344d408d94c6e1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 1.2 项目结构和默认添加的源码解读
打开刚刚新建的工程，和Single View App模板相比，使用 Augmented Reality App 模板新建的工程，初始化内容有如下差异：
- 添加了 art.scnassets 资源文件夹，里面放着资源文件，打开 ship.scn 文件，是一个3D的飞船模型
- 打开 Main.storyboard ，默认给启动页的 ViewController对象 添加了一个ARSCNView实例
- ViewController.swift 文件中添加了一些添加3D飞船模型的代码

现在直接在真机上 run 这个项目，效果如下：

![项目演示](https://upload-images.jianshu.io/upload_images/1444901-206da395ad14b609.gif?imageMogr2/auto-orient/strip)

Amazing，飞船渲染在我们的真实世界中了，看看是怎么通过代码加载进来的。

**1. 查看 main.storyboard，发现系统为我们的 ViewController 实例的 view 添加了一个ARSCNView类型的subview，并将其设置为ViewController的属性。**


```
    @IBOutlet var sceneView: ARSCNView!
```

**2. 查看 ViewController.swift 的 viewDidLoad: 方法：**
 
```
sceneView.delegate = self
```
 这行代码给 sceneView 设置 ARSCNViewDelegate 代理，在ViewController 中就可以获取 sceneView 的渲染状态回调。
```
sceneView.showsStatistics = true
```
`showsStatistics` 是 SCNView 的一个性能统计属性，设置为 true 之后，sceneView 底部就会显示一个sceneView 的性能统计状态栏，点击上面的加号之后，这个状态栏会展开，上面的 gif 有展示这个过程。

```
// Create a new scene
let scene = SCNScene(named: "art.scnassets/ship.scn")!
      
 // Set the scene to the view       
sceneView.scene = scene
```
这两行代码从我们资源文件夹 art.scnassets 中读取资源文件 ship.scn ，把这个文件转换为一个名为 scene 的 SCNScene 实例，然后将这个场景设置为 sceneView 的 scene 属性。
这样我们加载这个包含飞船的场景到真实世界中。

**3. 查看 ViewController.swift 的 viewWillAppear: 方法，在视图即将出现的时候，初始化一个 ARWorldTrackingConfiguration 实例 configuration ，然后用这个configuration 运行  ARSession对象。**


```
// Create a session configuration
let configuration = ARWorldTrackingConfiguration()

// Run the view's session
sceneView.session.run(configuration)
```

**4. 查看 ViewController.swift 的 viewWillDisappear:方法，在视图消失的时候，停止这个session，和 `session.run` 成对出现。**

```
 // Pause the view's session
 sceneView.session.pause()
```
但是！我们发现这个飞船是在viewDidLoad的时候加载的，并没有融入对世界理解，也没有交互！

看完系统默认添加的代码之后，在编写AR 代码之前，我们先给我们 Demo 搭建一个简单的视图框架。

### 1.3  利用storyboard快速构建Demo视图层级

新建三个ViewController，继承自UIViewController，每一个控制器代表一个功能：
- TKWorldTrackingViewController 负责实现平面检测功能
- TKFaceTrackingViewController 负责实现人脸检测相关功能
- TKImageRecognizeViewController 负责实现物体识别相关功能

并利用storyboard快速构建整个如图层级，关于storyboard的使用，本教程不做阐述，完成之后如下如所示：

![利用storyboard快速构建demo视图层级](https://upload-images.jianshu.io/upload_images/1444901-061976e9a93a360c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

此时，准备完毕，下面正式编写AR代码！！！

## 2. 开发 World Tracking 功能
首先在 `TKWorldTrackingViewController` 中引入 ARKit。

```
import ARKit
```
添加`sceneView`属性，用来展示AR视图。

```
    var sceneView : SCNView!
```
在 `viewDidLoad:` 中初始化 sceneView，并作为 subview 添加到view上。

```
 override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = SCNView(frame: view.bounds)
        view.addSubview(sceneView)
        
    }
```
sceneView 已经初始化完成，现在需要运行 sceneView 的 AR会话，我们希望在 当前 view 出现的时候运行会话。在 `viewWillAppear:`中创建一个`ARWorldTrackingConfiguration` 实例 configuration ，然后用 configuration 运行 AR session。

```
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
```
在当前 view 消失的时候，在`viewWillDisappear:`中停止AR session。

```
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
```
到目前为止，AR session 已经成功运行了，接下来要做的就是，在检测到平面之后，接收并处理ARKit发出来的通知。

实现思路如下：
- 上一遍文章关于世界追踪的描述中有提到过，ARKit 检测到平面后，会在场景中添加锚点
- 遵守 sceneView 的 ARSCNViewDelegate ，实现 `renderer(: didAdd: for:) `方法，当场景中添加锚点的时候，viewcontroller 就可以收到通知
- 判断新添加锚点的类型，如果是 ARPlaneAnchor 类型，就认为检测到平面了

让 `TKWorldTrackingViewController` 遵守 `ARSCNViewDelegate`。

```
class TKWorldTrackingViewController: UIViewController,ARSCNViewDelegate
```
然后在`viewDidLoad:`中添加如下代码：

```
sceneView.delegate = self
```
并实现代理方法，判断当前新增的锚点类型，如果是 ARPlaneAnchor，就在当前锚点出添加一个 box。

```
func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
     // 1. 判断当前新增的锚点类型
     guard anchor is ARPlaneAnchor else { return }        

     // 2. 在检测到的平面处添加 box
     let box = SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0)
     let boxNode = SCNNode(geometry: box)
     node.addChildNode(boxNode)
    
}
```

此时，代码写完了，在真机上 run 项目，点击 **“Demo1:平面检测”** 按钮，效果如下：

![World Tracking 平面检测演示](https://upload-images.jianshu.io/upload_images/1444901-f0a35401c58505ef.gif?imageMogr2/auto-orient/strip)

## 3. 开发 Face Tracking 功能

 TKFaceTrackingViewController 中引入 ARKit、添加 sceneView 属性、在 `viewDidLoad:` 中初始化 sceneView 的代码，和上一节“开发 World Tracking 功能”中一样。

运行 session 代码如下：

```
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
  
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
```

获取人脸和添加box方法和上一节讲的类似，代码如下：

```
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // 1. 判断anchor是否为ARFaceAnchor
        guard anchor is ARFaceAnchor else { return }
        
        // 2. 在检测到的人脸处添加 box
        let box = SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0)
        let boxNode = SCNNode(geometry: box)
        node.addChildNode(boxNode)
    }
```

在真机上 run 项目，点击 “Demo2:人脸检测” 按钮，效果如下：

![Face Tracking演示](https://upload-images.jianshu.io/upload_images/1444901-5c2423ef5bee24df.gif?imageMogr2/auto-orient/strip)

## 4. 开发基于AR的图像识别功能
### 4.1  将需要识别的2D图片导入到项目中
在 Assets.xcassets 文件目录下新建一个 AR Resource Group 类型的目录。
![新建AR Resource Group.gif](https://upload-images.jianshu.io/upload_images/1444901-34a0cefdb057e8e8.gif?imageMogr2/auto-orient/strip)

然后将要识别的对象，对应的2D图片拖拽到如下图片中的红框位置。

![Apr-06-2018 19-29-55.gif](https://upload-images.jianshu.io/upload_images/1444901-ab62e08e9cc5f676.gif?imageMogr2/auto-orient/strip)

接下来的步骤很重要，查看图片的 Show the Attributes inspector，给图片设置大小，这个值是我们需要识别的物体在真实世界中的大小！！！

这个值的精度直接决定了识别效果。

经过测量，我需要识别的企鹅，高度约为13cm，这里的单位选 Meters，设置如下。

![企鹅高度参数设置](https://upload-images.jianshu.io/upload_images/1444901-db405adb076edae0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 4.2  加载上面导入的图片

TKImageRecognizeViewController 中引入 ARKit、添加 sceneView 属性、在 viewDidLoad: 中初始化 sceneView 的代码，和前面“开发 World Tracking 功能”中一样。

运行 session 代码稍有变化。

`ARReferenceImage` 提供的 `referenceImages(:)`方法可以导入项目中 AR Resources 文件夹下的所有图片，如果项目中没有这个文件，会抛出异常。在`viewWillApper:` 中添加如下代码。

```
    guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("AR Resources 资源文件不存在 。")
        }
```
接着，新建一个ARWorldTrackingConfiguration实例，将 referenceImages 赋给 `detectionImages `属性。

```
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
```
用上面的 configuration 运行AR 会话。

```
sceneView.session.run(configuration)
```

### 4.3 添加图像识别代码

在`renderer(: didAdd: for:)`方法中处理图像识别结果的回调，在识别到图像的位置添加一个平面，做识别结果可视化标识。

```
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1. 判断anchor是否为ARImageAnchor
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // 2. 在检测到的物体图像处添加 plane
        let referenceImage = imageAnchor.referenceImage
        let plane = SCNPlane(width: referenceImage.physicalSize.width,
                             height: referenceImage.physicalSize.height)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 3. 将plane添加到检测到的图像锚点处
        node.addChildNode(planeNode)  
    }

```

在真机上 run 项目，点击 “Demo3:物体识别” 按钮，效果如下：

![物体识别演示](https://upload-images.jianshu.io/upload_images/1444901-e4d02dd3728a92de.gif?imageMogr2/auto-orient/strip)

至此，我们完成了关于我们第一个AR项目，接下来会围绕SceneKit，系统的介绍和 3D 内容渲染相关的内容。
