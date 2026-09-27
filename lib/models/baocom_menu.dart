class BaoComMenu {
  final int id;
  final String ngay;
  final String? menuTrua;
  final String? menuToi;

  BaoComMenu({required this.id, required this.ngay, this.menuTrua, this.menuToi});

  factory BaoComMenu.fromJson(Map<String, dynamic> json) {
    return BaoComMenu(
      id: json['id'],
      ngay: json['ngay'],
      menuTrua: json['menuTrua'],
      menuToi: json['menuToi'],
    );
  }
}