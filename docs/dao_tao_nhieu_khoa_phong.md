# Lớp đào tạo theo nhiều khoa/phòng

Thay đổi tại ứng dụng Flutter và API `D:\HVAPI3\HV-api`:

- Quyền 48 được xem lớp toàn viện, lớp nội bộ thuộc khoa/phòng hiện tại và lớp mình tạo. Quyền sửa/xóa/quản lý vẫn theo người tạo; quyền 47 giữ quyền quản trị đầy đủ.
- Form tạo/sửa lớp nội bộ có danh sách chọn nhiều khoa/phòng và tìm kiếm. Khoa/phòng gốc được giữ lại. Lớp đã có người đăng ký được thêm khoa/phòng, nhưng không được bỏ khoa/phòng cũ hoặc đổi giữa toàn viện và nội bộ.
- Danh sách, chi tiết lớp, tự đăng ký, dashboard và báo cáo chấm công sử dụng phạm vi nhiều khoa/phòng.
- Giữ cột `DaoTao_LopDaoTao.IdKhoaPhong` kiểu `int` cho khoa/phòng gốc. Bảng `DaoTao_LopKhoaPhong` lưu từng cặp `(IdLopDaoTao, IdKhoaPhong)`, tránh chuỗi ID phân cách bằng dấu phẩy.
- API nhận/trả `idKhoaPhongs: [12, 21]`. Ứng dụng cũ không gửi trường này khi sửa sẽ giữ nguyên danh sách. Lớp toàn viện vẫn dùng `phamViDaoTao: 1`; lớp nội bộ dùng `2` dù được chọn nhiều khoa/phòng.

## Áp dụng

1. Trong SSMS, chọn đúng database HVOffice mà API đang dùng, chạy [script SQL](sql/20260923_dao_tao_lop_khoa_phong.sql). Script tạo bảng liên kết, chỉ mục và bổ sung dữ liệu lớp cũ; có thể chạy lại. Kết quả cuối liệt kê lớp cũ thiếu khoa/phòng hợp lệ, nếu có.
2. Build/publish và khởi động lại API sau khi script chạy thành công.
3. Build/cập nhật ứng dụng Flutter. Đóng và mở lại màn hình Lớp đào tạo để tải danh mục mới.

Script chưa được thực thi trên database thực tế trong quá trình sửa mã.

## Kiểm tra

- Dùng tài khoản chỉ có quyền 48: thấy và đăng ký lớp toàn viện, không có quyền sửa/xóa lớp của người khác.
- Tạo lớp từ khoa A, chọn thêm B: nhân viên A và B thấy/đăng ký được; nhân viên C không thấy và gọi trực tiếp API đăng ký bị từ chối.
- Mở lại form sửa: A và B vẫn được chọn. Thêm C thì C được thấy lớp. Khi chưa có đăng ký có thể bỏ B, nhưng A được giữ lại.
- Đăng ký một học viên rồi sửa lớp: có thể thêm khoa, không thể bỏ khoa đã áp dụng; API cũng kiểm tra điều này.
- Kiểm tra lớp nội bộ cũ và lớp toàn viện cũ, tài khoản không có khoa/phòng, tài khoản có cả quyền 47/48, tài khoản người tạo đã chuyển khoa.

Các kiểm tra tự động:

```powershell
flutter test --no-pub test/dao_tao_scope_test.dart test/dao_tao_dashboard_model_test.dart
dotnet build tools/dao_tao_scope_checks/DaoTaoScopeChecks.csproj
dotnet tools/dao_tao_scope_checks/bin/Debug/net10.0/DaoTaoScopeChecks.dll
```

Chương trình kiểm tra API chỉ chạy biểu thức phân quyền và sinh SQL bằng EF; không mở kết nối database. Có thể đổi vị trí API khi build bằng `-p:BackendRoot=D:/duong-dan/HV-api`.
