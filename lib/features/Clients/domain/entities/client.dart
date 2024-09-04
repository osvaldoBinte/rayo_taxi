class Client {
  int? id;
  final String name;
  final String email;
  final String password;
  final int years_old;
  int? id_company;
  String? token;

  Client(
      {this.id,
      required this.name,
      required this.email,
      required this.password,
      required this.years_old,
      this.id_company,
      this.token});
}
