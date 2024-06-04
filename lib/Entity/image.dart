
// xây dựng đối tượng image để lưu ảnh có các thuộc tính cần dùng
class ImageEntity {
  int id = 0;
  String imgURL = "";
  String imgName = "";
  String imgLocation = "";


  ImageEntity(this.id, this.imgURL, this.imgName, this.imgLocation);

// xây dựng một đối tượng có các thuộc tính default 
  ImageEntity.newImage(String imgURL, String imgName, String imgLocation)
      : this(0, imgURL, imgName, imgLocation);
  ImageEntity.emptyImage();
  

// convert data nhận về từ sqlite sang object
  ImageEntity.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    imgURL = map['imgURL'];
    imgName = map['imgName'];
    imgLocation = map['imgLocation'];
  }

// convert object sang sqlite
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = <String, dynamic>{
      'imgURL': imgURL,
      'imgName': imgName,
      'imgLocation': imgLocation
    };
    return map;
  }
}
