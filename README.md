# ScreenReorderDemo
一个录屏demo，包含了两种实现方案，一种是系统自己提供的ReplayKit录制，一种是自己实现的录屏方式。

系统录制方案有以下缺点：
 - 开始录制时总会有一个弹出框询问用户是否使用麦克风，且界面是是全英文的，UI体验不好
 - 录制完成后自动保存至本地相册，无法程序获取视频地址
 
因此自己实现了一个录屏方案，但是有个bug，就是录制过程中如果进入后台，自动暂停，然后进入前台再恢复录制会闪退，
这里临时使用beginBackgroundTaskWithExpirationHandler申请后台活动解决，这样进入后台后AVAssetWriterInputPixelBufferAdaptor的pixelBufferPool就不会释放
 
支持暂停、恢复功能
 
