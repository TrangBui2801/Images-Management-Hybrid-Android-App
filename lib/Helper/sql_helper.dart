// ignore_for_file: prefer_const_declarations
import 'package:image_management_app/Entity/image.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static final String dbName = 'm_images_application';

  static final String imgTable = "images";

  static final String imgIdColumn = "id";
  static final String imgURLColumn = "imgURL";
  static final String imgNameColumn = "imgName";
  static final String imgLocationColumn = "imgLocation";

  static final String imageTableQuery = '''
    CREATE TABLE IF NOT EXISTS $imgTable(
      $imgIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
      $imgURLColumn VARCHAR(255) NOT NULL,
      $imgNameColumn VARCHAR(255),
      $imgLocationColumn VARCHAR(255)
    )
  ''';

  static Future<void> createTables(sql.Database database) async {
    await database.execute(imageTableQuery);
  }

  static Future<sql.Database> dbImage() async {
    return sql.openDatabase(
      '$dbName.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> addImage(ImageEntity imageEntity) async {
    // khởi tạo đối tượng db để thao tác vs csdl
    final database = await SQLHelper.dbImage();
    // gọi hàm toMap() để convert đối tượng sang sqlite để insert vào bảng image thông qua hàm insert()
    return await database.insert(imgTable, imageEntity.toMap());
  }

  static Future<List<ImageEntity>> getImages() async {
    // khởi tạo đối tượng db để thao tác vs csdl
    final database = await SQLHelper.dbImage();
    // khởi tạo mảng để lấy data từ bảng image thông qua hàm query()
    List<Map<String, dynamic>> data = await database.query(imgTable);
    // khởi tạo 1 mảng các đối tượng image
    List<ImageEntity> result = [];
    // convert từng đối tượng sqlite sang đối tượng image
    for (Map<String, dynamic> map in data) {
      result.add(ImageEntity.fromMap(map));
    }
    return result;
  }
}
