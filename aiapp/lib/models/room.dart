import 'package:capaiapp/models/user.dart';

class Room {
  String id;
  String name;
  String description;
  String created_at;
  String updated_at;
  User user;
}

class RoomList {
  List<Room> rooms;
}

class RoomCreate {
  String name;
  String description;
}

class RoomUpdate {
  String name;
  String description;
}

class RoomDelete {
  String id;
}

class RoomJoin {
  String id;
}

class RoomLeave {
  String id;
}