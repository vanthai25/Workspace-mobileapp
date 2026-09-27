using HV_api.Entities.HVOffice;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

var count = 0;
void Check(bool result, string scenario)
{
    if (!result) throw new Exception(scenario);
    count++;
    Console.WriteLine($"PASS: {scenario}");
}

var wholeHospital = new OfficeDaoTaoLopDaoTao { PhamViDaoTao = 1, MaNguoiTao = "other" };
var internalClass = new OfficeDaoTaoLopDaoTao
{
    PhamViDaoTao = 2, IdKhoaPhong = 12, MaNguoiTao = "creator",
    KhoaPhongs = [new() { IdKhoaPhong = 21 }, new() { IdKhoaPhong = 31 }]
};
// Role 48 and ordinary employees use the same student scope; role 47 has full visibility.
foreach (var role in new[] { "48", "ordinary" })
{
    Check(DaoTaoLopScope.VisibleTo(false, "student", 99).Compile()(wholeHospital), $"{role}: hospital class visible");
    Check(DaoTaoLopScope.VisibleTo(false, "student", 12).Compile()(internalClass), $"{role}: original department visible");
    Check(DaoTaoLopScope.VisibleTo(false, "student", 21).Compile()(internalClass), $"{role}: additional department visible");
    Check(!DaoTaoLopScope.VisibleTo(false, "student", 99).Compile()(internalClass), $"{role}: unrelated department denied");
    Check(!DaoTaoLopScope.VisibleTo(false, "student", null).Compile()(internalClass), $"{role}: missing department denied");
    Check(DaoTaoLopScope.VisibleTo(false, "student", null).Compile()(wholeHospital), $"{role}: hospital class visible without department");
}
Check(DaoTaoLopScope.VisibleTo(false, "creator", 99).Compile()(internalClass), "Creator retains access after moving department");
Check(DaoTaoLopScope.VisibleTo(true, "admin", null).Compile()(internalClass), "Role 47 retains full visibility");
Check(DaoTaoLopScope.VisibleTo(false, "student", 12).Compile()(new() { PhamViDaoTao = 2, IdKhoaPhong = 12 }), "Legacy class without links visible");
Check(!DaoTaoLopScope.VisibleTo(false, "student", 12).Compile()(new() { PhamViDaoTao = 2 }), "Unassigned internal class does not become public");

// Generate SQL without connecting to any database: verify correlated link predicate translation.
using var db = new HvOfficeContext(new DbContextOptionsBuilder<HvOfficeContext>()
    .UseSqlServer("Server=localhost;Database=NotUsed;Integrated Security=True;TrustServerCertificate=True")
    .Options);
foreach (int? department in new int?[] { 12, null })
{
    var sql = db.DaoTaoLopDaoTaos
        .Where(DaoTaoLopScope.VisibleTo(false, "student", department)).ToQueryString();
    Check(sql.Contains("DaoTao_LopDaoTao"), $"SQL translation succeeds (department={department?.ToString() ?? "null"})");
    if (department.HasValue)
        Check(sql.Contains("EXISTS") && sql.Contains("DaoTao_LopKhoaPhong"), "SQL checks exact department membership");
}
var linkType = db.Model.FindEntityType(typeof(OfficeDaoTaoLopKhoaPhong))!;
Check(linkType.FindPrimaryKey()!.Properties.Count == 2, "Composite key prevents duplicate departments");
Check(linkType.GetForeignKeys().Any(k => k.PrincipalEntityType.ClrType == typeof(OfficeDaoTaoLopDaoTao)
    && k.DeleteBehavior == DeleteBehavior.Cascade), "Deleting class also removes department links");

var options = new JsonSerializerOptions(JsonSerializerDefaults.Web);
var oldRequest = JsonSerializer.Deserialize<LopDaoTaoUpdateDTO>("{\"tenLopDaoTao\":\"Old client\"}", options)!;
Check(oldRequest.IdKhoaPhongs is null, "Legacy update omits scope instead of clearing it");
var newRequest = JsonSerializer.Deserialize<LopDaoTaoCreateDTO>("{\"tenLopDaoTao\":\"New class\",\"idKhoaPhongs\":[12,21]}", options)!;
Check(newRequest.IdKhoaPhongs!.SequenceEqual(new[] { 12, 21 }), "API accepts department array");
Console.WriteLine($"Passed {count} checks. No database connection or writes.");
