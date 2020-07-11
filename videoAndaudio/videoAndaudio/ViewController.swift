//
//  ViewController.swift
//  VideoCapture
//
//  Created by 孙震 on 2020/7/11.
//  Copyright © 2020 孙震. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var audioQueue = DispatchQueue.global()
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate lazy var previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    fileprivate var videoInput: AVCaptureDeviceInput?
    
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var movieOutput : AVCaptureMovieFileOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}


//MARK: -视频采集/&停止采集
extension ViewController{
    @IBAction func startcapture(){
        //1.设置视频输入输出
         setupVideo()
        
        //2.设置音频输入输出
        setupAudio()
        
        //3.添加文件
        let movieOutput = AVCaptureMovieFileOutput()
        session.addOutput(movieOutput)
        self.movieOutput = movieOutput
        
        //设置写入稳定性
        let connection = movieOutput.connection(with: AVMediaType.video)
        connection?.preferredVideoStabilizationMode = .auto
        
        
        //4.给用户看到预览图层（可选）
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        //5.开始采集
        session.startRunning()
        
        //6.将采集到的画面写入文件
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "abc.mp4"
        let url = URL(fileURLWithPath: path)
        movieOutput.startRecording(to: url, recordingDelegate: self)
        
     }
     
     @IBAction func stopCapture(){
        movieOutput?.stopRecording()
        session.stopRunning()
        previewLayer.removeFromSuperlayer()
         
     }
    
    
    @IBAction func switchscene(){
        //1,获取之前的镜头
        guard var position = videoInput?.device.position else {return}
        
        //2.获取当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //3.根据当前镜头创建新的device
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        guard let device = devices.filter({$0.position == .front}).first else{return}
        
        //4.根据新的device创建新的input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {return}
        
        
        
        //5.在session中切换input
        session.beginConfiguration()
        session.removeInput(self.videoInput!)
        session.addInput(videoInput)
        session.commitConfiguration()
        self.videoInput = videoInput
        
    }

}

extension ViewController{
    fileprivate func setupVideo(){
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)

        guard let device = devices.filter({$0.position == .front}).first else{return}
        
        //2.2通过device创建AVCaptureInput对象
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {return}
        self.videoInput = videoInput
        
        //2.3添加到会话
        session.addInput(videoInput)
        
        //3.给捕捉回话设置输出源
        //3.1设置输出源
        let videoOutput = AVCaptureVideoDataOutput()
        //3.2位输出源添加数据
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        session.addOutput(videoOutput)
        
        //3.获取video对应的connection
        self.videoOutput = videoOutput
    }
}

extension ViewController{
    fileprivate func setupAudio(){
        //1.设置音频输入
        guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else {return}
        
        guard let audioInput = try? AVCaptureDeviceInput(device: device) else {return}
        
        session.addInput(audioInput)
        
        let audioOutput = AVCaptureVideoDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        session.addOutput(audioOutput)
    }
}

//MARK: - 获取数据
extension ViewController:AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection == videoOutput?.connection(with: AVMediaType.video){
            print("采集视频")
        }else{
            print("采集音频")
        }
    }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("结束写入")
    }
}
