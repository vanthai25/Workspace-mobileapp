# Cập nhật Sự kiện và banner

Áp dụng cho Home web PC, web mobile và app mobile. Không thay đổi bảng database.

- Các API thêm/sửa/xóa banner kiểm tra quyền 52. API ảnh chỉ trả banner đang được bật và nằm trong thời gian hiển thị; quyền 52 được xem trước ảnh của sự kiện chưa mở/đã tắt.
- API danh sách lấy banner theo nhóm sự kiện, thay cho truy vấn riêng từng sự kiện. Danh sách vẫn giữ cấu trúc phản hồi cũ.
- Home tải lại khi quay về tab hoặc mở lại app. Thao tác quản trị thành công trong cùng phiên ứng dụng báo Home làm mới. Các thiết bị khác vẫn dùng polling 5 phút và tải lại khi quay về Home; chưa dùng thông báo đẩy thời gian thực.
- Tải ảnh lỗi có nút thử lại và được thử lại khi làm mới danh sách. Ảnh đã tải thành công được giữ trong bộ nhớ; cache được bỏ khi banner biến mất hoặc đổi IdFile.
- Tác vụ polling, tự chuyển banner và animation dừng khi Home bị ẩn hoặc app xuống nền. Tôn trọng chế độ giảm chuyển động của thiết bị.
- Nút “Tạm dừng chuyển động” dừng tự chuyển banner và hiệu ứng. Desktop tạm ngừng tự chuyển khi rê chuột lên ảnh; thao tác kéo/chạm cũng tạm dừng.
- Banner mobile dùng nền gradient nhẹ thay cho ảnh blur; tiêu đề banner và nút hành động được hiển thị trên cả mobile. Ảnh vẫn hiển thị đầy đủ.
- Hiệu ứng nền tập trung hai bên, giảm mật độ pháo hoa/confetti trên màn hình nhỏ; pháo hoa có khoảng nghỉ. Có nút xem trước PC/điện thoại và chạy lại trong phần chỉnh hiệu ứng. Xem trước không ghi trạng thái đã xem hiệu ứng trong ngày.
- Màn hình đích của banner dùng danh sách lựa chọn; hiện hỗ trợ Đào tạo / CME. Liên kết ngoài phải là http/https hợp lệ.

## Triển khai

1. Build/publish API trong `D:\HVAPI3\HV-api`, cập nhật và khởi động lại API.
2. Build/cập nhật Flutter web và app mobile. Phần này không cần chạy script SQL.
3. Kiểm tra bằng tài khoản có quyền 52 và tài khoản thường trên môi trường sử dụng thật.

## Kiểm tra tự động

```powershell
flutter test --no-pub test/su_kien_home_test.dart
dotnet build tools/su_kien_checks/SuKienChecks.csproj
dotnet tools/su_kien_checks/bin/Debug/net10.0/SuKienChecks.dll
```

Các kiểm tra API dựng chính sách quyền từ controller và xác nhận quyền xem trước ảnh; không kết nối database. Cần kiểm tra thêm tốc độ API, dung lượng ảnh thực tế và độ mượt trên thiết bị sau triển khai.
