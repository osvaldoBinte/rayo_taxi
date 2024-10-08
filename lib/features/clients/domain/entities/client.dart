class Client {
  int? id;
  String? name;
  String? email;
  String? password;
  String? new_password;
  String? current_password;
  int? years_old;
  int? id_company;
  String? token;
  String? birthdate;

  String? photo_profile;
  String? path_photo;

  Client(
      {this.id,
      this.name,
      this.email,
      this.password,
      this.new_password,
      this.current_password,
      this.years_old,
      this.id_company,
      this.token,
      this.birthdate,
      this.photo_profile,
      this.path_photo});
}
