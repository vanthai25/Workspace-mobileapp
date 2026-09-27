# Bổ sung dữ liệu mẫu xét nghiệm 609

## Cách khuyến nghị: tạo stored bao dành riêng cho API

Với bản ghi `XNTraSau.Id=4930`, kiểm tra trực tiếp cho thấy
`usp_App_XNTraSau_XetNghiem` hiện chỉ trả một result set. Định nghĩa stored
đang chạy cũng chưa có lệnh gọi TDT và chưa có bảng ghi chú. Vì vậy controller
đúng sẽ báo thiếu cấu trúc.

Không cần sửa lại stored nội dung dài. Mở file
[`usp_App_XNTraSau_XetNghiem_Phieu.sql`](usp_App_XNTraSau_XetNghiem_Phieu.sql),
chạy toàn bộ trên database HIS, rồi đổi tên stored trong controller từ:

```csharp
"dbo.usp_App_XNTraSau_XetNghiem"
```

thành:

```csharp
"dbo.usp_App_XNTraSau_XetNghiem_Phieu"
```

Stored bao gọi lần lượt stored nội dung hiện có và TDT, sau đó trả riêng bảng
ghi chú. Cách này giữ nguyên các stored gốc đang dùng cho WinForm. Bản
[`XNTraSauKetQuaController_609.cs.txt`](XNTraSauKetQuaController_609.cs.txt)
đã dùng tên stored bao mới.

Các phần bên dưới mô tả phương án ghép trực tiếp vào stored nội dung. Chỉ dùng
phương án đó nếu không muốn tạo stored bao; không thực hiện đồng thời cả hai.

File PRT cấu hình ba nguồn dữ liệu:

```text
TDT: dbo.usp_XN_GETDLINPRT_TDT
ND:  dbo.usp_XN_GETDLINPRT_ND
TDD: dbo.usp_XN_GETDLINPRT_TDD
```

`dbo.usp_App_XNTraSau_XetNghiem` hiện là clone của `ND`, nên mới trả bảng chỉ số. Không gọi nguyên `TDD` từ API vì phần cuối stored này duyệt file bằng `xp_fileexist` và `OPENROWSET`; ảnh chữ ký đã có endpoint riêng.

## Sửa clone xét nghiệm

Mở bản hiện tại của `dbo.usp_App_XNTraSau_XetNghiem` trong SSMS.

1. Đổi `CREATE PROCEDURE` thành `ALTER PROCEDURE` nếu stored đã tồn tại.
2. Thêm `SET NOCOUNT ON;` ngay sau `BEGIN` nếu chưa có.
3. Ở cuối stored, giữ nguyên bảng kết quả hiện tại. Tìm đoạn cuối:

```sql
EXEC dbo.usp_DropSessionLocalTempTables;
SET TRAN ISOLATION LEVEL READ COMMITTED;
END;
```

Thay đoạn đó bằng đoạn sau:

```sql
    -- Dọn bảng tạm của phần nội dung ND trước khi gọi TDT.
    EXEC dbo.usp_DropSessionLocalTempTables;
    SET TRAN ISOLATION LEVEL READ COMMITTED;

    -- Result set 2 và 3:
    --   2 = thông tin hành chính
    --   3 = chẩn đoán
    EXEC dbo.usp_XN_GETDLINPRT_TDT
         @makcb = @makcb,
         @barcode = @barcode,
         @ChuoiMahh = @ChuoiMahh,
         @mathanhtoanct = @mathanhtoanct,
         @idmauin = @idmauin,
         @InTuLichSuCLS = @InTuLichSuCLS,
         @isdebug = 0;

    -- Result set 4: chỉ lấy ghi chú cần cho phiếu.
    -- Không chạy phần ảnh/chữ ký cũ trong TDD.
    DECLARE @GhiChuDichVu NVARCHAR(MAX) = N'';
    DECLARE @GhiChuBarcode NVARCHAR(MAX) = N'';
    DECLARE @MaThanhToanChiTiet BIGINT =
        CONVERT(BIGINT, LTRIM(RTRIM(@mathanhtoanct)));

    SELECT @GhiChuDichVu = STUFF((
        SELECT N';' + x.noidung
        FROM
        (
            SELECT DISTINCT LTRIM(RTRIM(g.noidung)) AS noidung
            FROM dbo.tbl_ghichuxntheodichvu AS g
            WHERE g.mathanhtoanct = @MaThanhToanChiTiet
              AND NULLIF(LTRIM(RTRIM(g.noidung)), N'') IS NOT NULL
        ) AS x
        FOR XML PATH(N''), TYPE
    ).value(N'.', N'NVARCHAR(MAX)'), 1, 1, N'');

    SELECT @GhiChuBarcode = STUFF((
        SELECT N';' + x.ghichu
        FROM
        (
            SELECT DISTINCT LTRIM(RTRIM(g.ghichu)) AS ghichu
            FROM dbo.ketquacls AS kq
            JOIN dbo.tbl_Ghichuxetnghiem AS g
              ON g.Barcode = kq.barcode
            WHERE kq.mathanhtoanct = @MaThanhToanChiTiet
              AND kq.makcb = @makcb
              AND NULLIF(LTRIM(RTRIM(g.ghichu)), N'') IS NOT NULL
        ) AS x
        FOR XML PATH(N''), TYPE
    ).value(N'.', N'NVARCHAR(MAX)'), 1, 1, N'');

    SELECT
        ISNULL(@GhiChuDichVu, N'') AS ghichudichvu,
        ISNULL(@GhiChuBarcode, N'') AS ghichubarcode;
END;
```

Không sửa `dbo.usp_XN_GETDLINPRT_TDT`, `dbo.usp_XN_GETDLINPRT_ND` hoặc `dbo.usp_XN_GETDLINPRT_TDD` đang phục vụ WinForm.

## Thứ tự bảng trả về

Sau thay đổi, `dbo.usp_App_XNTraSau_XetNghiem` trả bốn result set theo thứ tự:

```text
0: dongKetQua  - bảng chỉ số hiện tại
1: thongTin    - hành chính từ TDT
2: chanDoan    - chẩn đoán từ TDT
3: ghiChu      - ghichudichvu và ghichubarcode
```

## Test trong SSMS

```sql
EXEC dbo.usp_App_XNTraSau_XetNghiem
     @makcb = N'<MA_KCB>',
     @barcode = N'<BARCODE>',
     @ChuoiMahh = N'<MAHH>',
     @idmauin = N'609',
     @mathanhtoanct = N'<MA_THANH_TOAN_CT>',
     @InTuLichSuCLS = 0;
```

SSMS phải hiện đúng bốn bảng. Bảng thứ hai cần có các cột như `hoten`, `namsinh`, `tenphai`, `tenkk`, `tenphong`, `tendoituong`, `dienthoai`, `ngaylaymau`, `ngaykhopBC`, `tennhanvienlaymau`, `tennhanviennhan`, `tenchatluong`. Bảng thứ ba cần có `tenbenh`.

Nếu bảng `thongTin` bị rỗng trong khi mẫu 609 hợp lệ, kiểm tra điều kiện
`idmauketqua` trong `usp_XN_GETDLINPRT_TDT`. Một số dữ liệu HIS lưu nhiều mã
mẫu trong cùng chuỗi. Không sửa stored TDT gốc đang dùng cho WinForm; hãy tạo
clone dành cho API hoặc áp dụng cùng cách kiểm tra `dbo.StringSplit` đang có
trong `usp_App_XNTraSau_XetNghiem`.

## Sửa controller để giữ đủ bốn bảng

Controller đang chạy tại:

```text
D:\HVAPI3\HV-api\HV-api\Controllers\XNTraSauKetQuaController.cs
```

Bản đầy đủ đã sửa theo đúng controller hiện tại nằm tại
[`XNTraSauKetQuaController_609.cs.txt`](XNTraSauKetQuaController_609.cs.txt).
Bạn có thể đối chiếu hoặc chép nội dung file này sang controller API sau khi
stored đã trả đủ bốn bảng. Bản này còn trả mã `502 SAI_CAU_TRUC_STORED` cùng
thông báo cụ thể nếu stored thiếu bảng, thay vì che mọi lỗi cấu trúc thành 500.

Trong action `GetXetNghiem`, tìm từ dòng khai báo `var dongKetQua` đến hết
khối `using` gọi `dbo.usp_App_XNTraSau_XetNghiem`. Giữ nguyên phần khai báo
tham số stored, nhưng thay phần khai báo danh sách và phần đọc `reader` theo
mẫu dưới đây.

### 1. Thay phần khai báo danh sách

```csharp
var dongKetQua = new List<Dictionary<string, object?>>();
var thongTin = new List<Dictionary<string, object?>>();
var chanDoan = new List<Dictionary<string, object?>>();
var ghiChu = new List<Dictionary<string, object?>>();

bool daTimThayBangKetQua = false;
bool daTimThayBangThongTin = false;
bool daTimThayBangChanDoan = false;
bool daTimThayBangGhiChu = false;
```

### 2. Thay toàn bộ khối đọc `reader`

Thay đoạn bắt đầu bằng `await using var reader = ...` và vòng `do/while`
ngay sau đó bằng:

```csharp
await using var reader =
    await command.ExecuteReaderAsync(cancellationToken);

do
{
    if (reader.FieldCount == 0)
    {
        continue;
    }

    var columnNames = Enumerable.Range(0, reader.FieldCount)
        .Select(reader.GetName)
        .ToArray();

    var columns = columnNames
        .ToHashSet(StringComparer.OrdinalIgnoreCase);

    if (columns.Count != columnNames.Length)
    {
        throw new InvalidOperationException(
            "Stored xét nghiệm trả cột trùng tên.");
    }

    List<Dictionary<string, object?>>? bangDich = null;

    if (columns.Contains("machiso") && columns.Contains("ketluan"))
    {
        if (daTimThayBangKetQua)
        {
            throw new InvalidOperationException(
                "Stored trả nhiều bảng chỉ số ngoài cấu trúc dự kiến.");
        }

        string[] requiredColumns =
        [
            "tenchiso_goc",
            "ketqua_goc",
            "daduyet",
            "grouplevel",
            "mathanhtoanct",
            "mahh"
        ];

        if (requiredColumns.Any(x => !columns.Contains(x)))
        {
            throw new InvalidOperationException(
                "Stored xét nghiệm thiếu cột đầu ra cần thiết.");
        }

        daTimThayBangKetQua = true;
        bangDich = dongKetQua;
    }
    else if (columns.Contains("makcb")
             && columns.Contains("hoten")
             && columns.Contains("barcode"))
    {
        if (daTimThayBangThongTin)
        {
            throw new InvalidOperationException(
                "Stored trả nhiều bảng thông tin hành chính.");
        }

        daTimThayBangThongTin = true;
        bangDich = thongTin;
    }
    else if (columns.Contains("tenbenh"))
    {
        if (daTimThayBangChanDoan)
        {
            throw new InvalidOperationException(
                "Stored trả nhiều bảng chẩn đoán.");
        }

        daTimThayBangChanDoan = true;
        bangDich = chanDoan;
    }
    else if (columns.Contains("ghichudichvu")
             && columns.Contains("ghichubarcode"))
    {
        if (daTimThayBangGhiChu)
        {
            throw new InvalidOperationException(
                "Stored trả nhiều bảng ghi chú.");
        }

        daTimThayBangGhiChu = true;
        bangDich = ghiChu;
    }

    if (bangDich is null)
    {
        continue;
    }

    while (await reader.ReadAsync(cancellationToken))
    {
        var row = new Dictionary<string, object?>(
            StringComparer.OrdinalIgnoreCase);

        for (int i = 0; i < reader.FieldCount; i++)
        {
            row.Add(
                columnNames[i],
                reader.IsDBNull(i) ? null : reader.GetValue(i));
        }

        bangDich.Add(row);
    }
}
while (await reader.NextResultAsync(cancellationToken));
```

### 3. Kiểm tra cấu trúc sau khối `using`

Thay riêng khối `if (!daTimThayBangKetQua)` hiện có bằng:

```csharp
if (!daTimThayBangKetQua
    || !daTimThayBangThongTin
    || !daTimThayBangChanDoan
    || !daTimThayBangGhiChu)
{
    throw new InvalidOperationException(
        "Stored xét nghiệm phải trả đủ 4 bảng: "
        + "dongKetQua, thongTin, chanDoan và ghiChu.");
}

if (thongTin.Count == 0)
{
    throw new InvalidOperationException(
        "Stored xét nghiệm không trả thông tin hành chính.");
}
```

Giữ nguyên toàn bộ phần kiểm tra `dongDuLieu`, `mathanhtoanct`, `mahh` và
`daduyet` phía dưới.

### 4. Bổ sung ba mảng vào JSON thành công

Trong `return Ok(...)`, tìm đoạn cuối đang có:

```csharp
soDongDuLieu = dongDuLieu.Count,
dongKetQua
```

Thay bằng:

```csharp
soDongDuLieu = dongDuLieu.Count,
dongKetQua,
thongTin,
chanDoan,
ghiChu,
endpointChuKy = $"/api/XNTraSau/{id}/chu-ky?kemAnh=true"
```

Không bỏ trường `benhNhan` đang có vì Flutter vẫn dùng nó làm dữ liệu dự
phòng khi TDT thiếu một trường.

## Kiểm tra API

Build API:

```powershell
dotnet build
```

Sau đó gọi:

```http
GET http://localhost:5078/api/XNTraSau/<ID>/ket-qua/xet-nghiem?idMauIn=609
Authorization: Bearer <token>
```

JSON thành công phải có đủ:

```text
data.dongKetQua[]
data.thongTin[]
data.chanDoan[]
data.ghiChu[]
data.endpointChuKy
```

`thongTin[0]` cần có `hoten`, `makcb`, `barcode`, `tenkk`, `tenphong`,
`ngaylaymau` và `ngaykhopBC`. `chanDoan[0]` cần có `tenbenh`. Khi các phần
này đã xuất hiện, Flutter mẫu 609 tự dùng chúng, không cần đổi endpoint.
