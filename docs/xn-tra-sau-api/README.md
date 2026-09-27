# Hướng dẫn hoàn thiện API XNTraSau

## 1. Những gì đã có và những gì sẽ thêm

Hướng dẫn này dựa trên controller hiện có trong `D:\HVAPI3\HV-api\HV-api` và ba stored gốc bạn gửi. Chưa đọc trực tiếp được định nghĩa các stored mới bạn đã sửa trong SQL Server. Vì vậy mã mới kiểm tra cả số bảng và các cột bắt buộc, không âm thầm đọc nhầm bảng khi stored khác dự kiến.

Hai file `XNTraSauMoRongController.cs.txt` và `XNTraSauLoaiKetQua.cs.txt` là mã mẫu để bạn tự chép. Việc soạn tài liệu này không sửa controller đang chạy, appsettings hay database.

| Chức năng | GET endpoint | Trạng thái trước hướng dẫn |
|---|---|---|
| Danh sách chỉ định | `/api/XNTraSau` | Đã có |
| Danh sách mẫu/form và loại kết quả | `/api/XNTraSau/{id}/cau-hinh-ket-qua` | Thêm trong file mới |
| Kết quả xét nghiệm | `/api/XNTraSau/{id}/ket-qua/xet-nghiem` | Đã có, thêm kiểm tra loại mẫu ở bước 5 |
| Kết quả GPB, gồm trường checkbox V2 | `/api/XNTraSau/{id}/ket-qua/gpb` | Thêm trong file mới |
| Kết quả kháng sinh đồ | `/api/XNTraSau/{id}/ket-qua/khang-sinh-do` | Thêm trong file mới |
| Chữ ký HIS, ảnh và trạng thái HSM | `/api/XNTraSau/{id}/chu-ky?kemAnh=true` | Đã có, dùng chung cả ba loại |

`id` trong URL luôn là `XNTraSau.Id` tại NSTL_test. API tự tìm `mathanhtoanct`, `mahh`, `makcb`, sau đó xác nhận với HIS. Không nhập `mathanhtoanct` thay cho `id` trong URL.

Phân biệt các loại mã:

| Mã | Nguồn | Vai trò |
|---|---|---|
| `mahh` | XNTraSau và dmdichvu | Dịch vụ |
| `maloaidichvu` | dmdichvu, lấy qua stored ThongTin | Chọn stored xét nghiệm, GPB hoặc KSD |
| `idMauIn` | dmdichvu.idmauketqua, có thể chứa nhiều mã | Mẫu in, ví dụ 376 |
| `idMauKqKhac` | cdhaketquakhac.idform | Form lưu các trường name/value, ví dụ 12 |

Không truyền `idMauIn=12` chỉ vì form nhập kết quả có `idform=12`.

## 2. Kiểm tra điều kiện trước khi chép code

Các connection string `NSTL_test`, `HISDatabase`, `ConfigCADatabase` đã được bạn cấu hình. Giữ nguyên, không chép mật khẩu vào tài liệu hay gửi ảnh connection string.

Trên **database HIS**, cần có:

```text
dbo.usp_App_XNTraSau_ThongTin
dbo.usp_App_XNTraSau_XetNghiem
dbo.usp_App_XNTraSau_GPB
dbo.usp_App_XNTraSau_KhangSinhDo
dbo.usp_App_XNTraSau_ChuKy
```

Nếu muốn kiểm tra tham số mà không sửa gì, chạy trong SSMS trên HIS:

```sql
SELECT
    OBJECT_NAME(p.object_id) AS stored,
    p.parameter_id,
    p.name,
    TYPE_NAME(p.user_type_id) AS kieu,
    p.max_length
FROM sys.parameters AS p
WHERE p.object_id IN (
    OBJECT_ID(N'dbo.usp_App_XNTraSau_ThongTin'),
    OBJECT_ID(N'dbo.usp_App_XNTraSau_GPB'),
    OBJECT_ID(N'dbo.usp_App_XNTraSau_KhangSinhDo'),
    OBJECT_ID(N'dbo.usp_App_XNTraSau_ChuKy')
)
ORDER BY stored, p.parameter_id;
```

Stored GPB cần các tham số đã có trong bản gốc:

```text
@makcb, @mathanhtoan, @mahh, @mauketqua,
@manvdangnhap_, @mathanhtoanct,
@laydendong, @NoiDungHinhAnhKhac,
@idmauin, @idmaukqk, @fordesign
```

Nếu bản clone có thêm `@DocHinhAnh`, code sẽ phát hiện và truyền `true` để lấy ảnh nội dung GPB. Nếu không có, code gọi theo chữ ký gốc. Lỗi đọc ảnh từ stored sẽ hiện lỗi API, cần xem log và kiểm tra quyền đọc ảnh trên máy HIS.

GPB cần trả 10 bảng theo thứ tự gốc, **kể cả bảng rỗng**:

```text
0: Bệnh nhân
1: Chỉ định
2: Dịch vụ
3: Kết quả GPB
4: Chẩn đoán
5: Kết quả khác/pivot
6: Kết quả mở rộng thứ hai hoặc bảng cot1
7: Nhân viên thực hiện
8: Nhân viên in (có thể rỗng)
9: Ảnh nội dung GPB (có thể chỉ có Anh = NULL)
```

Không xóa SELECT cuối chỉ vì không lấy ảnh. Nếu bỏ đoạn đọc file, vẫn phải trả bảng có cột `Anh`, ví dụ:

```sql
SELECT CAST(NULL AS VARBINARY(MAX)) AS Anh;
```

Trong clone GPB, kiểm tra chỗ join nhân viên chỉ định đã sửa từ `b8.manv = b8.manv` thành `b8.manv = b7.manv`. Điều kiện cũ có thể nhân bản dữ liệu và lấy sai tên nhân viên.

KSD cần 5 bảng theo bản gốc. Các cột bạn đã bổ sung phải có:

```text
Bảng 0 - kháng sinh:
vikhuanid, mavikhuan, khangsinhid, tenkhangsinh, MIC, SIR, ...

Bảng 3 - chỉ định/vi khuẩn:
vikhuanid, mavikhuan, tenvikhuan, daduyet, ketluan, ...
```

Nếu trước đây chưa sửa xong lỗi GROUP BY, xem mục 10 bên dưới. Không bỏ kiểm tra cột trong API để lách lỗi này; cần các mã để không trộn kháng sinh của nhiều vi khuẩn.

## 3. Thêm controller mới

1. Mở hai file mẫu cạnh tài liệu này: `XNTraSauMoRongController.cs.txt` và `XNTraSauLoaiKetQua.cs.txt`.
2. Trong project API, tạo hai file:

   `D:\HVAPI3\HV-api\HV-api\Controllers\XNTraSauMoRongController.cs`

   `D:\HVAPI3\HV-api\HV-api\Controllers\XNTraSauLoaiKetQua.cs`

3. Chép toàn bộ nội dung từng file mẫu vào file tương ứng. Nếu đã chép controller theo bản hướng dẫn trước, cập nhật file đó bằng mã mẫu mới; không tạo controller thứ hai cùng route.
4. Đảm bảo đuôi cả hai file đích là **.cs**, không phải `.cs.txt`.
5. Giữ `XNTraSauKetQuaController.cs` và `XNTraSauChuKyController.cs` hiện có.
6. Build lại solution rồi chạy API.

Không cần cài NuGet mới. Mã sử dụng SqlClient, EF Core và cơ chế controller/DI hiện có. Không cần thêm `AddScoped` riêng cho controller này.

Nếu build bằng terminal, đứng ở thư mục project API:

```powershell
dotnet build
```

Các endpoint mới có `[Authorize]`. Trong Scalar, nhập Bearer token giống lúc test chữ ký. Quyền truy cập hiện theo phạm vi ứng dụng nhân viên đang có; chưa phải thiết kế endpoint công khai cho bệnh nhân tự truy cập.

## 4. Chọn stored theo maloaidichvu và test danh sách mẫu

Bảng chọn loại đã được cập nhật theo mã bạn cung cấp:

| dmdichvu.maloaidichvu | Loại trả về | Stored được gọi |
|---|---|---|
| 8, 9, 10, 11, 33, 34, 41 | `XET_NGHIEM` | `usp_App_XNTraSau_XetNghiem` |
| 13 | `GPB` | `usp_App_XNTraSau_GPB` |
| 42, 12 | `KHANG_SINH_DO` | `usp_App_XNTraSau_KhangSinhDo` |

Quy tắc dùng chung nằm trong `XNTraSauLoaiKetQua.GetLoai`. Không cần khai báo từng `mahh` hoặc mẫu in trong appsettings. Nếu đã thêm `XNTraSauKetQua:LoaiTheoDichVu` theo hướng dẫn cũ, phần này không còn được dùng sau khi cập nhật cả controller mở rộng và bước 5; bạn có thể xóa riêng mục đó. Giữ nguyên connection strings.

Luồng chọn: `XNTraSau.Id → mahh → HIS.dmdichvu.maloaidichvu → loại kết quả/stored`. `idmauketqua` vẫn xác định các mẫu in hợp lệ; GPB V2 vẫn chọn `idform` theo dữ liệu của chính chỉ định.

Gọi trước:

```http
GET http://localhost:5078/api/XNTraSau/10200/cau-hinh-ket-qua
Authorization: Bearer <token>
```

Kiểm tra trong `data`:

```text
mathanhtoanct
mahh
tenDichVu
maLoaiDichVu
danhSachMau
suDungKetQuaKhacV2
danhSachForm
```

**Chỉ nếu** `mathanhtoanct` đúng chỉ định đã test SSMS và `danhSachForm` có `idForm=12`, mới dùng form 12 cho bản ghi này. Ảnh trước đó chưa đủ để khẳng định `XNTraSau.Id=10200` luôn tương ứng `mathanhtoanct=13217075`.

Trong từng phần tử `danhSachMau`, `loaiKetQua` và `endpoint` được chọn theo `maLoaiDichVu`. Ví dụ nếu `maLoaiDichVu=13`, mẫu trả loại `GPB` và endpoint `/api/XNTraSau/10200/ket-qua/gpb`.

Nếu mã loại ngoài danh sách hoặc bị NULL, endpoint danh sách vẫn trả thông tin để đối chiếu, nhưng `loaiKetQua` và `endpoint` là `null`. Endpoint kết quả trả `422 LOAI_DICH_VU_CHUA_HO_TRO`, không tự chọn một stored mặc định. Cần xác nhận thêm quy tắc rồi bổ sung vào helper nếu có loại mới.

Mã loại dịch vụ và mã form là hai trường độc lập: `maloaidichvu=12` chọn KSD; `idform=12` trong dữ liệu GPB không làm GPB thành KSD.

## 5. Thêm kiểm tra loại vào API xét nghiệm đang có

Trong `Controllers/XNTraSauKetQuaController.cs`, làm ba thay đổi dưới đây. Controller này và helper đều dùng namespace `HV_api.Controllers`, nên không cần thêm using riêng.

**5.1. Khai báo biến trước khối gọi stored ThongTin**, cạnh biến `danhSachMau`:

```csharp
object? maLoaiDichVu = null;
```

**5.2. Trong khối đọc ThongTin**, ngay sau đoạn `if (!await reader.ReadAsync(...)) { ... }`, trước `reader.NextResultAsync(...)`, thêm:

```csharp
maLoaiDichVu = reader["maloaidichvu"] == DBNull.Value
    ? null
    : reader["maloaidichvu"];
```

Phải đọc ở bảng đầu tiên của stored ThongTin. Bảng thứ hai là danh sách mẫu, không có cột này.

**5.3. Tìm đoạn kiểm tra mẫu hợp lệ**:

```csharp
if (idMauIn.Length > 50 || !danhSachMau.Contains(idMauIn))
```

Chèn đoạn sau **sau toàn bộ khối if này**, trước đoạn gọi `usp_App_XNTraSau_XetNghiem`. Nếu đã thêm đoạn đọc `LoaiTheoDichVu` của hướng dẫn cũ, thay toàn bộ đoạn kiểm tra loại cũ bằng đoạn này:

```csharp
var loaiKetQua = XNTraSauLoaiKetQua.GetLoai(maLoaiDichVu);

if (loaiKetQua is null)
{
    return UnprocessableEntity(new
    {
        success = false,
        code = "LOAI_DICH_VU_CHUA_HO_TRO",
        message = "Mã loại dịch vụ HIS bị thiếu hoặc chưa được hỗ trợ.",
        data = new { maLoaiDichVu }
    });
}

if (loaiKetQua != "XET_NGHIEM")
{
    return BadRequest(new
    {
        success = false,
        code = "SAI_LOAI_KET_QUA",
        message = "Mẫu này không thuộc API kết quả xét nghiệm.",
        data = new { maLoaiDichVu, loaiKetQua }
    });
}
```

Build lại. Xét nghiệm, GPB và KSD giờ dùng chung bảng mã loại ở bước 4. Vẫn giữ nguyên bước kiểm tra `idMauIn` thuộc danh sách mẫu của dịch vụ.

Nếu bạn cần `mahh` ngay trên danh sách, trong `Services/XNTraSauService.cs`, tìm phần `new XNTraSauDTO` của `GetAllAsync`. DTO đã có thuộc tính `Mahh`; thêm phép gán còn thiếu:

```csharp
Mahh = q.xn.Mahh,
```

Không thêm lần nữa nếu đã có. Việc này không thay thế kiểm tra HIS ở endpoint chi tiết.

## 6. Test GPB trước

Sau khi bước 4 xác nhận đúng các mã, gọi:

```http
GET http://localhost:5078/api/XNTraSau/10200/ket-qua/gpb?idMauIn=376&idMauKqKhac=12
Authorization: Bearer <token>
```

Nếu chỉ định chỉ có một mẫu và một form, API cũng cho phép bỏ trống hai tham số để tự chọn duy nhất. Nếu có nhiều mẫu/form, API trả 409 kèm danh sách để chọn, không lấy dòng đầu tùy ý.

Bản mẫu đặt điều kiện **GPB đã ký HIS** mới trả kết quả chính thức; sử dụng chính stored chữ ký đã test, không chỉ kiểm tra chuỗi `daky` khác rỗng. Kết quả chưa ký trả `409 KET_QUA_CHUA_KY`. Đây là quy ước phát hành của bản mẫu API; nếu muốn nhân viên xem bản nháp, cần xác định riêng luồng hiển thị bản nháp trước khi mở điều kiện này.

Kết quả thành công có các phần:

```text
data.benhNhan[]
data.chiDinh[]
data.ketQua[]
data.chanDoan[]
data.truongKetQuaKhac[]
data.ketQuaKhacCu
data.nhanVien[]
data.hinhAnh[]
data.endpointChuKy
```

Với V2, tìm phần sau trong `truongKetQuaKhac`:

```json
{
  "name": "tthnoibieumoactinh",
  "value": "True",
  "giaTriBoolean": true
}
```

`value` giữ dữ liệu gốc; `giaTriBoolean` chỉ chuyển được giá trị True/False. Giá trị trống hoặc không phải boolean là `null`, không tự đổi thành false. Không suy ra ô tích từ `ketluan`.

API không tự ghép tên kỹ thuật của tất cả trường thành nhãn y khoa. Khi dựng giao diện, map chính xác tên trường với nhãn trên mẫu HIS; `tthnoibieumoactinh` là ô bạn đã đối chiếu trong ảnh.

Nếu HIS không dùng V2, dữ liệu cũ từ bảng số 5 được trả tại `ketQuaKhacCu`; không truyền `idMauKqKhac`. Các mẫu dùng `@laydendong` hoặc `@NoiDungHinhAnhKhac` khác mặc định cần đối chiếu cấu hình mẫu HIS rồi mở rộng tham số ở backend. Bản này dùng 0 và chuỗi rỗng như luồng đang test, chưa tuyên bố bao phủ mọi mẫu in đặc biệt trong HIS.

Ảnh tại `hinhAnh` là ảnh nội dung GPB do stored trả. Ảnh chữ ký dùng endpoint chữ ký riêng để lấy đúng ảnh, tên, thời điểm ký và HSM. Không dùng cột ảnh chữ ký cũ trong bảng nhân viên để thay thế luồng đã chốt.

## 7. Test kháng sinh đồ

1. Chọn `XNTraSau.Id` thực tế có kết quả KSD. Không lấy `mathanhtoanct` điền vào URL.
2. Gọi `/api/XNTraSau/{id}/cau-hinh-ket-qua`.
3. Xác nhận `mahh`, `mathanhtoanct`, mẫu in khớp bản đã chạy được trong SSMS.
4. Xác nhận `maLoaiDichVu` là 42 hoặc 12; mẫu phải có `loaiKetQua=KHANG_SINH_DO`.
5. Gọi:

```http
GET http://localhost:5078/api/XNTraSau/{id-thuc-te}/ket-qua/khang-sinh-do?idMauIn={mau-thuc-te}
Authorization: Bearer <token>
```

Response gồm:

```text
data.benhNhan[]
data.viKhuanVaChiDinh[]
data.khangSinh[]
data.soDongKhangSinh
data.chanDoan[]
data.endpointChuKy
```

Đối chiếu từng vi khuẩn và từng kháng sinh với phiếu HIS. Dùng cặp `vikhuanid` + `mavikhuan` để ghép dòng kháng sinh vào đúng dòng vi khuẩn theo các khóa stored trả; không gom theo tên hiển thị. Kiểm tra một mẫu có nhiều vi khuẩn nếu có dữ liệu test.

`MIC`, `SIR`, đường kính, khoảng tham chiếu được giữ theo HIS. API không tính lại tính nhạy/kháng.

Kết quả KSD chưa được duyệt đầy đủ trả `409 KET_QUA_CHUA_DUYET`. Danh sách kháng sinh rỗng vẫn có thể đi cùng kết luận; không tự biến mảng rỗng thành “âm tính”.

Stored gốc có điều kiện chỉ lấy dòng có MIC hoặc đường kính. Nếu SSMS/API đều thiếu dòng chỉ có SIR, kiểm tra điều kiện này cùng phiếu HIS; đó là giới hạn truy vấn nguồn, không phải lỗi JSON. Không tự bỏ các JOIN/điều kiện chuyên môn mà chưa đối chiếu dữ liệu.

## 8. Test chữ ký và xét nghiệm lại

Chữ ký cho cả ba loại vẫn gọi cùng endpoint:

```http
GET http://localhost:5078/api/XNTraSau/{id}/chu-ky?kemAnh=true
Authorization: Bearer <token>
```

Kiểm tra:

```text
mathanhtoanct phải trùng response kết quả
daKyHIS
manvKy, tenNguoiKy, ngayKy
dangKyHsmHopLe
hienThiTichXanh
contentType, anhBase64
canhBaoHsm
```

Điều kiện tích xanh là đã ký HIS và có đăng ký HSM hợp lệ theo quy tắc `maNV`/`ksd` đã chốt. Đây không phải API kiểm chứng chữ ký mật mã trên một file PDF. Khi ConfigCA lỗi, giữ trạng thái chưa xác định và cảnh báo của endpoint hiện có, không tự chuyển thành “không đăng ký”.

KSD cũng đọc chữ ký trong `ketquacls`, đúng yêu cầu của bạn.

Test lại xét nghiệm đã thành công:

```http
GET http://localhost:5078/api/XNTraSau/10124/cau-hinh-ket-qua
GET http://localhost:5078/api/XNTraSau/10124/ket-qua/xet-nghiem
```

Riêng mẫu xét nghiệm 388, response có thêm `data.hinhAnh[]` với `contentType`, `soByte` và `anhBase64` để dựng biểu đồ PCR. API không trả đường dẫn file nội bộ của HIS. Stored bao chỉ đọc ảnh `anhcdha` được đánh dấu in kết quả và nằm trong thư mục ảnh CLS cho phép.

Đối chiếu `maLoaiDichVu` với danh sách xét nghiệm ở bước 4. Nếu có nhiều mẫu, truyền `idMauIn` đã chọn. Nếu bản ghi từng test có mã loại ngoài danh sách mới, API sẽ từ chối; cần xác nhận thêm mã đó thay vì tự coi là xét nghiệm chỉ vì lần trước đã trả dữ liệu.

## 9. Cách nối vào app/web sau khi API đạt

**Cập nhật:** Màn hình Flutter dùng chung đã được thêm vào ứng dụng. Xem [hướng dẫn chạy và đối chiếu giao diện](FLUTTER.md); phần dưới mô tả luồng API mà màn hình đang sử dụng.

Luồng gọi:

```text
Chọn một bản ghi XNTraSau
  -> GET /{id}/cau-hinh-ket-qua
  -> Chọn mẫu (nếu chỉ có một thì tự chọn)
  -> Đọc loaiKetQua + endpoint của mẫu
  -> Gọi endpoint với idMauIn
     GPB V2 có nhiều form: cho chọn idMauKqKhac
  -> Gọi /{id}/chu-ky?kemAnh=true
  -> Hiển thị dữ liệu + chữ ký của cùng id/chỉ định
```

Đây là API dữ liệu. Chưa có chức năng tự xuất PDF giống hệt mẫu WinForm. Frontend cần dựng ba nhóm giao diện; GPB tùy mẫu cần các nhãn/checkbox tương ứng, KSD cần nhóm theo vi khuẩn. Giữ đường xem PDF cũ cho trường hợp có file đính kèm nếu bạn muốn dùng song song.

Các endpoint PDF cũ trong `XNTraSauController.cs` hiện có `[AllowAnonymous]`. Khi đưa bộ kết quả lên môi trường thật, cần đưa các route này về cùng quy tắc phân quyền đọc kết quả, không coi phần PDF đã được bảo vệ chỉ vì các endpoint mới có `[Authorize]`. Hướng dẫn này chưa sửa các route cũ.

## 10. Sửa lỗi KSD thiếu cột/GROUP BY nếu còn

Chỉ sửa **bản clone** `usp_App_XNTraSau_KhangSinhDo` sau khi xem lại phần hiện có. Không thay toàn bộ stored đang dùng của WinForm.

Trong SELECT bảng kháng sinh đầu tiên, giữ các JOIN cũ và thay SELECT/GROUP BY bằng nội dung đủ khóa dưới đây (đoạn này theo đúng alias của stored gốc bạn gửi):

```sql
SELECT
    b1.vikhuanid,
    b1.mavikhuan,
    b2.tenvikhuan,
    b1.khangsinhid,
    b1.tennhomks,
    b3.tenkhangsinh,
    b1.MIC,
    b1.SIR,
    b1.duongkinh,
    b1.makhangsinh,
    b4.giatrithamchieu
FROM #dtketquaks b1
JOIN dbo.KSD_dmvikhuan b2 ON b2.vikhuanid = b1.vikhuanid
JOIN dbo.KSD_dmkhangsinh b3 ON b3.khangsinhid = b1.khangsinhid
JOIN dbo.KSD_MapVK_KS b4
    ON b4.khangsinhid = b1.khangsinhid
   AND b4.vikhuanid = b1.vikhuanid
GROUP BY
    b1.vikhuanid, b1.mavikhuan, b2.tenvikhuan,
    b1.khangsinhid, b1.tennhomks, b3.tenkhangsinh,
    b1.MIC, b1.SIR, b1.duongkinh, b1.makhangsinh,
    b4.giatrithamchieu, b4.ttin
ORDER BY b4.ttin;
```

Trong SELECT bảng `LẤY THÔNG TIN CHỈ ĐỊNH`, thêm ba biểu thức vào danh sách SELECT:

```sql
, b9.vikhuanid
, b9.mavikhuan
, b7.daduyet
```

Và thêm đúng ba biểu thức đó vào GROUP BY của **chính SELECT này**:

```sql
, b9.vikhuanid
, b9.mavikhuan
, b7.daduyet
```

Không thêm `#dtketquavk.vikhuanid` trong GROUP BY khi câu SELECT đang dùng alias `b9`. Lỗi 8120 trước đó xuất hiện khi thêm cột vào SELECT mà thiếu cột tương ứng ở GROUP BY.

Chạy lại stored trong SSMS với bộ tham số KSD đã có, kiểm tra đủ năm bảng, rồi mới test HTTP.

## 11. Bảng xử lý lỗi khi test

| HTTP/code | Việc cần làm |
|---|---|
| 401 | Kiểm tra Bearer token, hạn token và claim nhân viên |
| 404 KHONG_CO_CHI_DINH | Kiểm tra lại XNTraSau.Id và môi trường NSTL |
| 400 MAU_KHONG_HOP_LE | Chọn trong danhSachMau của chính bản ghi |
| 400 SAI_LOAI_KET_QUA | Gọi endpoint đúng với loại đã khai báo |
| 400 FORM_KHONG_THUOC_CHI_DINH | Không dùng form 12 cho chỉ định không có dữ liệu form đó |
| 400 FORM_KHONG_KHOP_MAU_IN | Đối chiếu cauhinh_mapmauintheomaukhac và mẫu đang chọn |
| 422 LOAI_DICH_VU_CHUA_HO_TRO | Kiểm tra maloaidichvu từ HIS, đối chiếu danh sách mã đã chốt; không lấy mã form/mẫu in thay thế |
| 409 CAN_CHON_MAU / CAN_CHON_FORM | Chọn mã từ danh sách trả về |
| 409 KET_QUA_CHUA_KY / KET_QUA_CHUA_DUYET | Đối chiếu trạng thái kết quả trên HIS |
| 422 HIS_TU_CHOI_DU_LIEU | Xem log API, có tên stored và SQL error; không sửa điều kiện đoán mò |
| 502 SAI_CAU_TRUC_STORED | Chạy stored trong SSMS, đếm số bảng kể cả bảng rỗng, bỏ SELECT debug nếu có |
| 502 THIEU_COT_STORED | Xem data.missing và bổ sung cột đúng trong clone |
| 502 SAI_BENH_NHAN / SAI_DICH_VU | Dừng đối chiếu khóa liên kết, không bỏ kiểm tra để trả dữ liệu |
| 500 LOI_DOC_KET_QUA | Xem exception trong log API; có thể là SQL, quyền ảnh hoặc sai tham số |

## 12. Tiêu chí hoàn tất đợt test

- Xét nghiệm đã có tiếp tục trả đúng chỉ số/kết quả/đơn vị và phạm vi tham chiếu.
- GPB trả đúng kết luận và đủ các trường V2; ô True/False khớp phiếu HIS.
- KSD không trộn dữ liệu giữa các vi khuẩn; MIC/SIR khớp HIS.
- Chữ ký của từng loại có đúng người và đúng chỉ định.
- Thử truyền mẫu của dịch vụ khác/form của chỉ định khác: API phải từ chối.
- Thử gọi GPB bằng chỉ định KSD hoặc ngược lại với mẫu hợp lệ: phải trả SAI_LOAI_KET_QUA; mã loại ngoài danh sách không được tự gọi stored mặc định.
- Thử kết quả chưa ký/chưa duyệt: API trả trạng thái đã quy định.
- Thử bản ghi có nhiều mẫu/form: API yêu cầu chọn, không tự lấy dòng đầu.

Mã mẫu được kiểm tra biên dịch riêng với .NET và các assembly hiện có: 0 lỗi, 0 cảnh báo. Helper chọn loại đã vượt qua 20 trường hợp kiểm tra, gồm đủ 10 mã loại bạn cung cấp, giá trị NULL và mã ngoài danh sách. Việc truy vấn thực tế, thứ tự bảng của các stored bạn đã sửa, quyền SQL và đối chiếu với phiếu HIS vẫn cần test theo các bước trên; chưa chạy vào database thay bạn.
