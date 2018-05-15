//  ViewController.swift
//  hellostorage
//
//  Created by 申潤五 on 2018/3/31.
//  Copyright © 2018年 申潤五. All rights reserved.
//
import UIKit
import Firebase
import FirebaseStorageUI

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var theImageView: UIImageView!
    @IBOutlet weak var sharedImagesCollection: UICollectionView!
    @IBOutlet weak var uploadStatus: UIProgressView!
    var uploadedImages = [[String:String]]()
    var storageRef:StorageReference!
    override func viewDidLoad() {
        super.viewDidLoad()
        // 匿名登入
        Auth.auth().signInAnonymously(completion: nil)
        // 不顯示進度條
        uploadStatus.isHidden = true
        storageRef = Storage.storage().reference().child("pic")
        sharedImagesCollection.delegate = self
        sharedImagesCollection.dataSource = self
        self.uploadedImages.removeAll()
        
        
        let dataRef = Database.database().reference().child("pic")
        dataRef.observe(.childAdded) { (snapshot) in
            let uid = snapshot.childSnapshot(forPath: "uid").value as! String
            let link = snapshot.childSnapshot(forPath: "link").value as! String
            let path = snapshot.childSnapshot(forPath: "path").value as! String
            let value = ["uid":uid,"link":link,"path":path]
            self.uploadedImages.append(value)
            self.sharedImagesCollection.reloadData()
        }
    }
    
    @IBAction func uploadImage(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // 設定儲存位置
        let storageRef = Storage.storage().reference().child("pic")
        
        // 取得選取影像
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        //設定顯示圖示
        self.theImageView.image = image
        
        // 設定上傳檔案名
        var filename = "image.JPG"
        if let url = info[UIImagePickerControllerImageURL] as? URL{
            filename = url.lastPathComponent
        }
        
        // 取得目前使用者 ID
        if let theUid = Auth.auth().currentUser?.uid{
            // 取得破壞性壓縮 Jpeg 影像
            if let data = UIImageJPEGRepresentation(image, 0.5){
                //建立中介資料
                let myMetadata = StorageMetadata()
                myMetadata.customMetadata = ["myKye":"my Value"]
                // 顯示進度條
                uploadStatus.isHidden = false
                //上傳到 Storage
                let task = storageRef.child(theUid).child(filename).putData(data, metadata: myMetadata) { (metadata, error) in
                    self.uploadStatus.isHidden = true
                    if error == nil{
                        
                        //上傳成功更新資料庫
                        let path = "/pic/" + theUid + "/" + filename
                        let dataRef = Database.database().reference().child("pic")
                        let value = ["uid":theUid,"link":(metadata?.downloadURL())!.absoluteString,"path":path]
                        dataRef.childByAutoId().setValue(value)
                        
                        //通知使用者上傳成功
                        let alert = UIAlertController.init(title: "上傳成功", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }else{
                        print(error?.localizedDescription)
                    }
                }
                
                // 進度顯示
                task.observe(.progress) { (snapshot) in
                    if let theProgress = snapshot.progress?.fractionCompleted{
                        self.uploadStatus.progress = Float(theProgress)
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uploadedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = sharedImagesCollection.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as! MyCollectionViewCell
        let imageRef = Storage.storage().reference(withPath: uploadedImages[indexPath.row]["path"]!)
        cell.image.sd_setImage(with: imageRef)
        return cell
    }
}

