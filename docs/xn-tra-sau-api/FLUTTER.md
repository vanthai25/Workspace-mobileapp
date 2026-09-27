# Màn hình kết quả Flutter dùng chung

Đã thêm màn hình xem kết quả trong Flutter, dùng cho app và trình duyệt máy tính/điện thoại. Không cần tạo trang HTML trong ProtectedPages cho màn hình này.

## Cách mở và test

1. Chạy API với các endpoint đã test thành công.
2. Khởi động lại Flutter để nạp các file mới.
3. Đăng nhập, mở **XN Trả Sau**, chọn một chỉ định.
4. Trong bảng chi tiết, nhấn **Xem kết quả**. Nút này có cả khi chưa có PDF đính kèm.
5. Chọn mẫu nếu có nhiều mẫu. GPB có nhiều form thì chọn thêm form. Chỉ có một lựa chọn sẽ tự chọn.
6. Kết quả được dựng thành PDF và mở ngay trong trình xem. Nhấn biểu tượng tải xuống trên thanh tiêu đề để lưu/chia sẻ file.

Các trường hợp người dùng đã cung cấp để test:

| XNTraSau.Id | Mẫu in | Form | Nội dung |
|---|---|---|---|
| 10369 | 376 | 12 | Thin Prep, kết luận và các checkbox |
| 6783 | 381 | Không có | Mô bệnh học: đại thể, vi thể, kết luận |
| 9892 | 383 | Không có | Tế bào học: mô tả và kết luận |
| 10734 | 301 | Không có | Xét nghiệm ISOFIX, bảng sáu cột và thông tin lấy/nhận mẫu |
| 10732 | 388 | Không có | HBV định lượng, ngưỡng phát hiện và biểu đồ PCR |
| 10725 | 391 | Không có | HSV type 1/2, bảng tác nhân và kết quả |
| 10737 | 474 | Không có | PCR tác nhân, bảng kết quả và định lượng DU |
| 10726 | 477 | Không có | HPV định type, nhóm nguy cơ cao/thấp và bảng hai cột |
| Chưa có ID test | 609 | Không có | Huyết đồ, bảng chỉ số và nhận xét |
| Chưa có ID test | 351 | Không có | Vi sinh, bảng kháng sinh đồ/MIC |
| Chưa có ID test | 743 | Không có | Vi sinh Liên cầu B, kết quả âm tính/dương tính |
| Chưa có ID test | 764 | Không có | Nuôi cấy nấm, kết quả kháng nấm đồ/MIC |

Với mẫu 381, bố cục hiện đặt `docketqua` vào **Đại thể**, `mota` vào **Vi thể**, `ketluan` vào **Kết luận**, dựa trên nội dung response đã cung cấp. Cần đối chiếu các tiêu đề với mẫu HIS thực tế. Nội dung được hiển thị nguyên bản, không tự tạo kết luận hoặc tính lại giá trị chuyên môn.

Màn hình kết quả chỉ hiển thị file PDF sau khi tải dữ liệu và chữ ký. Nút PDF đính kèm cũ vẫn có tại chi tiết chỉ định. Trình duyệt tải/chia sẻ PDF qua printing; thiết bị lưu file tạm và mở bằng ứng dụng hỗ trợ PDF.

## Các file chính

- `lib/screens/xn_trasau_ket_qua_screen.dart`: chọn mẫu/form, hiển thị kết quả và chữ ký.
- `lib/models/xn_trasau_ket_qua.dart`: đọc dữ liệu HIS, định danh loại kết quả, bố cục GPB theo mẫu/form.
- `lib/services/xn_trasau_ket_qua_service.dart`: gọi API qua ApiClient có xác thực.
- `lib/services/xn_result_pdf_service.dart`: dựng PDF A4 dùng chung và chọn bố cục riêng theo loại/mẫu/form.
- `lib/screens/xn_trasau_list_screen.dart`: nút mở màn hình kết quả và danh sách PDF.
- `lib/utils/xn_pdf_save*.dart`: xử lý lưu/mở PDF theo nền tảng.
- `lib/widgets/xn_gpb_376_report.dart`: phiếu 376/form 12 dựa trên file PRT đã xuất.
- `lib/models/xn_gpb_376_template.dart`: 32 liên kết trường/nhãn, nhóm và kiểu chữ lấy từ PRT.

## Mẫu 376 đã đọc từ PRT

File `Phiếu kết quả GPB_CTC.prt` là XML có bảng cấu hình vùng in và ô in. Đã lấy đủ 32 liên kết `NDG5!<tên trường>`, nhãn ở ô tương ứng, nhóm theo vị trí và kiểu chữ. Không cần điền nhãn mẫu này thủ công nữa. Bảng `gpb_376_form_12_labels.csv` đã có đủ nội dung.

Phiếu Flutter giữ các nhóm: đánh giá tiêu bản, biến đổi không u, vi sinh vật, tế bào tuyến nội mạc, bất thường biểu mô vảy/tuyến và u ác tính khác. Giá trị true in dấu X; false để ô trống; thiếu/null/trùng dữ liệu dùng dấu “—” kèm thông báo. Không tự tích mục cha khi một mục con được tích.

Nhãn được giữ nguyên từ nguồn, chỉ gộp xuống dòng thành khoảng trắng để Flutter tự dàn dòng. Nhãn `btgbieumovay2` trong PRT gốc đang kết thúc bằng `(ASC-H` mà chưa đóng ngoặc; chưa tự sửa nội dung nguồn. `TVaginalis` là T. Vaginalis, còn `cbVaginalis` là G. Vaginalis.

`gpb_376_template.json` lưu nhãn và tọa độ ô nguồn, kèm SHA-256 của file PRT để đối chiếu. `tools/extract_gpb376.ps1` là script trích dữ liệu cho đúng bản mẫu này. Script cấm DTD/external XML resolver, không chạy SQL hoặc biểu thức compute trong file. Liên kết form 12 được lấy từ response API của người dùng; file PRT xác nhận mã mẫu in 376.

Phiếu PDF 376 dùng dữ liệu đã trích từ PRT, logo và thông tin đơn vị cố định theo yêu cầu. Chữ ký dùng endpoint đã xác thực thay vì công thức chữ ký cũ trong file mẫu.

Khi thêm mẫu mới, đăng ký bố cục chuyên biệt trong `_specializedBuilders` của `xn_result_pdf_service.dart` theo khóa `LOAI_KET_QUA:idMauIn:idMauKqKhac`, ví dụ `GPB:376:12`. Luồng tải dữ liệu, xem PDF và nút tải xuống được dùng lại. Mẫu chưa đăng ký vẫn xuất bằng bố cục chung cho xét nghiệm, GPB hoặc kháng sinh đồ.

Mẫu mới chưa có bố cục riêng vẫn hiển thị các trường mô tả, nội dung bổ sung, kết luận, dữ liệu mở rộng và ảnh từ API. Không dùng mặc định bố cục checkbox của 376 cho mọi dịch vụ GPB.

## Mẫu 381 – mô bệnh học

File `Phiếu kết quả mô bệnh học.prt` xác nhận `idmauin=381`, không dùng form kết quả khác và gọi `usp_CDHA_INKQPRT_GPB`. Bố cục PDF riêng dùng `docketqua` cho nhận xét đại thể, `mota` cho nhận xét vi thể, `ketluan` cho chẩn đoán mô bệnh học, `denghi` cho bàn luận và `ngaytraKQ` cho ngày ở khu vực ký.

API GPB cần trả thêm `chiDinh.bschidinh`, `chiDinh.bschidinhchucdanh` và bảng `dichVu` có `ghichudv`, `tendichvukemghichu`. `ghichudv` là vị trí lấy mẫu trên phiếu 381. Người pha bệnh phẩm lấy từ `nhanVien.bslam2`; người làm tiêu bản lấy từ `nhanVien.ktvlam`.

## Mẫu 383 – tế bào học

File `Phiếu kết quả tế bào học.prt` xác nhận `idmauin=383`, không dùng form kết quả khác và gọi `usp_CDHA_INKQPRT_GPB`. Bố cục PDF riêng dùng `mota` cho nhận xét vi thể, `ketluan` cho chẩn đoán tế bào học, `denghi` cho bàn luận, `Solam` cho số lam và `ngaytraKQ` cho ngày ở khu vực ký. Phương pháp nhuộm trên mẫu là Giemsa. Mẫu dùng cùng các trường API bổ sung của mẫu 381; không cần thêm stored riêng.

## Mẫu 764 – nuôi cấy nấm

File `Phiếu kết quả Nuôi cấy nấm.prt` xác nhận `idmauin=764` và gọi `usp_KSD_InKQ_KS`. Mẫu được đăng ký bằng khóa `KHANG_SINH_DO:764:`. Bố cục lấy thông tin hành chính từ `benhNhan`, chẩn đoán từ `chanDoan`, còn SID và nội dung nuôi cấy từ dòng đầu của `viKhuanVaChiDinh`.

Các trường dùng trong `viKhuanVaChiDinh` gồm `barcode`, `noigui`, `ngaynhanbp`, `tenloaimau`, `ktvlam`, `tendichvu`, `tenvikhuan`, `ketluan`, `ngaylam` và `ghichuvitheokhuan`. Nếu API không trả `tendichvu`, phiếu dùng `tenDichVu` ở cấp ngoài. Trường `maylam` chỉ hiện khi API có dữ liệu.

Nếu `khangSinh` có dòng, phiếu tự thêm bảng Nhóm KS, Tên kháng sinh, Kết quả, SRI và PPXN. Kết quả ưu tiên `duongkinh`; khi không có đường kính thì dùng `MIC`. PPXN hiện `DISK` hoặc `MIC` tương ứng. Trường `SIR` của API được đặt dưới tiêu đề `SRI` để giữ đúng chữ trên mẫu PRT. Nếu danh sách rỗng, phần này được ẩn như phiếu nuôi cấy nấm trong ảnh đối chiếu.

Chữ ký vẫn dùng endpoint `/api/XNTraSau/{id}/chu-ky?kemAnh=true`, lấy từ `ketquacls`. Tiêu đề vùng ký của mẫu này là `BS/KTV Xét nghiệm`; ngày kết quả dùng `viKhuanVaChiDinh.ngaylam`.

Endpoint để kiểm tra dữ liệu thật:

```text
GET /api/XNTraSau/{id}/ket-qua/khang-sinh-do?idMauIn=764
```

Stored và controller hiện tại đã có đúng các nhóm dữ liệu cần thiết nên chưa cần tạo stored riêng. Chỉ sửa API/stored nếu response thật thiếu các trường đã liệt kê.

## Mẫu 351 – vi sinh

File `Phiếu kết quả Vi sinh.prt` xác nhận `idmauin=351` và dùng cùng stored `usp_KSD_InKQ_KS`. Mẫu được đăng ký bằng khóa `KHANG_SINH_DO:351:` và dùng chung khung hành chính, nội dung xét nghiệm, bảng thuốc và chữ ký với mẫu 764.

Mẫu 351 dùng nhãn `Tên vi khuẩn` và `Kết quả kháng sinh đồ - MIC`. Tên vi khuẩn khoa học được in đậm nghiêng. Các dòng bảng lấy `tennhomks`, `tenkhangsinh`, `duongkinh` hoặc `MIC`, `SIR`; PPXN được hiển thị là `DISK` khi có đường kính và `MIC` khi không có. Chỉ các dòng có cùng `vikhuanid` và `mavikhuan` với vi khuẩn đang in mới được đưa vào bảng.

Endpoint kiểm tra dữ liệu thật:

```text
GET /api/XNTraSau/{id}/ket-qua/khang-sinh-do?idMauIn=351
```

Không cần tạo stored hoặc endpoint mới cho mẫu này.

## Mẫu 743 – vi sinh Liên cầu B

File `Phiếu kết quả Vi sinh (Liên cầu B).prt` xác nhận `idmauin=743` và dùng stored `usp_KSD_InKQ_KS`. Mẫu được đăng ký bằng khóa `KHANG_SINH_DO:743:` và dùng chung khung vi sinh với mẫu 351/764.

Mẫu 743 dùng nhãn `Tên vi khuẩn` và `Kết quả`. Giá trị `tenvikhuan` được in đậm nghiêng khi có dữ liệu; giá trị `ketluan`, ví dụ `ÂM TÍNH`, được in đậm. Nếu `tenvikhuan` rỗng thì phiếu để trống sau nhãn, không tự thêm dấu gạch. Bảng kháng sinh chỉ xuất hiện khi `khangSinh` có dữ liệu phù hợp; trường hợp âm tính trong ảnh đối chiếu sẽ không có bảng.

Endpoint kiểm tra dữ liệu thật:

```text
GET /api/XNTraSau/{id}/ket-qua/khang-sinh-do?idMauIn=743
```

Không cần tạo stored hoặc endpoint mới cho mẫu này.

## Mẫu 301 – Huyết học, Đông máu và xét nghiệm ISOFIX

File `Phiếu kết quả xét nghiệm Huyết học - Đông máu.prt` xác nhận `idmauin=301`. Mẫu dùng `usp_XN_GETDLINPRT_ND_ISOFIX` cho bảng chỉ số và `usp_XN_GETDLINPRT_TDT_ISOFIX` cho hành chính, chẩn đoán. API vẫn dùng endpoint xét nghiệm chung; stored bao `usp_App_XNTraSau_XetNghiem_Phieu` chọn hai stored ISOFIX khi `@idmauin = N'301'`.

Mẫu được đăng ký bằng khóa `XET_NGHIEM:301:`. Phiếu có bảng sáu cột: STT, Tên xét nghiệm, Kết quả, Khoảng tham chiếu, QTXN và Máy XN. Không in cột đơn vị. Tên chỉ số giữ dấu `*` do stored ISOFIX thêm; các mã định dạng HIS trong `ketluan` quyết định màu và kiểu chữ của kết quả.

Phần lấy mẫu ưu tiên `ngaygiao` và `nguoigiao`, đúng liên kết trong PRT; nếu thiếu mới dùng `ngaylaymau` và `tennhanvienlaymau`. Người thực hiện ưu tiên `ktvlam`, sau đó dùng `bslam`. Ảnh và trạng thái chữ ký lấy từ endpoint chữ ký hiện tại, không đọc ảnh trong `usp_XN_GETDLINPRT_TDD`.

Endpoint kiểm tra với dữ liệu đã đối chiếu:

```text
GET /api/XNTraSau/10734/ket-qua/xet-nghiem?idMauIn=301
```

Trước khi gọi endpoint, chạy lại file `usp_App_XNTraSau_XetNghiem_Phieu_SQL_CU.sql` trên database HIS để cập nhật nhánh mẫu 301, sau đó khởi động lại API vì controller cũng có kiểm tra cấu trúc riêng cho kết quả ISOFIX.

## Mẫu 388 – HBV định lượng

File `Phiếu kết quả xét nghiệm HBV.prt` xác nhận `idmauin=388`, dùng `usp_XN_GETDLINPRT_ND`, `usp_XN_GETDLINPRT_TDT` và `usp_XN_GETDLINPRT_TDD_fix`. Mẫu được đăng ký bằng khóa `XET_NGHIEM:388:`.

Bảng kết quả có hai cột. `Kết quả định lượng` lấy `ketluan`, dự phòng bằng `ketqua_goc`; `Ngưỡng phát hiện` ghép `giatribinhthuong` và `tendonvitinh`. Màu và kiểu chữ của kết quả tiếp tục lấy từ mã định dạng HIS trong `ketluan`. Thiết bị cố định là `CFX-96`, QTXN lấy từ `quytrinhxn`, bệnh phẩm ưu tiên `tenloaimau` đúng liên kết PRT.

Biểu đồ PCR là ảnh thật của chỉ định, không phải ảnh mẫu cố định. PRT liên kết ô ảnh với `TDD3!Anh`; dữ liệu thật nằm trong `anhcdha.urlimage`. Stored bao chỉ đọc ảnh của mẫu 388 được đánh dấu `inkq=1`, kiểm tra đường dẫn phải thuộc `E:\DATA\Anh\AnhCLS\`, hỗ trợ PNG/BMP/JPG/JPEG và trả result set `hinhAnh`. Controller đổi `VARBINARY(MAX)` thành `anhBase64` và không công bố đường dẫn nội bộ. Flutter đặt ảnh bên trái, chú giải màu và chữ ký bên phải.

Endpoint đã đối chiếu bằng dữ liệu thật:

```text
GET /api/XNTraSau/10732/ket-qua/xet-nghiem?idMauIn=388
```

Dữ liệu kiểm tra có `mahh=197`, `mathanhtoanct=13279288` và một ảnh JPG 26.479 byte. Stored phần dữ liệu hiện hoàn thành khoảng 2,2 giây.

Để API trả biểu đồ, chạy lại `usp_App_XNTraSau_XetNghiem_Phieu_SQL_CU.sql` trên database HIS rồi khởi động lại API vì `XNTraSauKetQuaController.cs` đã bổ sung đọc result set ảnh.

## Mẫu 391 – HSV type 1/2

File `Phiếu kết quả xét nghiệm _HSV.prt` xác nhận `idmauin=391`. Mẫu dùng bộ stored xét nghiệm chung `usp_XN_GETDLINPRT_TDT`, `usp_XN_GETDLINPRT_ND` và `usp_XN_GETDLINPRT_TDD`; không cần thêm stored hay sửa controller.

Mẫu được đăng ký bằng khóa `XET_NGHIEM:391:` và dùng chung khung xét nghiệm Real-time PCR của mẫu 477. Thiết bị trên mẫu 391 được giữ cố định là `CFX-96` theo PRT; QTXN lấy từ `quytrinhxn`. Bảng hai cột lấy động `tenchiso`/`tenchiso_goc` và `ketluan`/`ketqua_goc`, nên tên dịch vụ cùng HSV type 1, type 2 không bị hard-code trong bố cục.

Bệnh phẩm ưu tiên `tenloaimau`, đúng liên kết `NDG0!tenloaimau` trong PRT. Dòng ghi chú dưới bảng lấy `ghichudichvu` và `ghichubarcode`; nếu nội dung chưa có tiền tố thì Flutter thêm nhãn `Ghi chú`. Thời gian/người lấy mẫu ưu tiên `ngaygiao`, `nguoigiao`.

Endpoint đã đối chiếu bằng dữ liệu thật:

```text
GET /api/XNTraSau/10725/ket-qua/xet-nghiem?idMauIn=391
```

Dữ liệu kiểm tra có `mahh=181`, `mathanhtoanct=13281469`, gồm tên dịch vụ, HSV type 1 và HSV type 2. Stored hoàn thành khoảng 3,5 giây.

## Mẫu 474 – PCR tác nhân và DU

File `Phiếu kết quả xét nghiệm _PCR tác nhân.prt` xác nhận `idmauin=474`. Mẫu dùng bộ stored xét nghiệm chung `usp_XN_GETDLINPRT_TDT`, `usp_XN_GETDLINPRT_ND` và `usp_XN_GETDLINPRT_TDD`; không cần thêm stored hay sửa controller.

Mẫu được đăng ký bằng khóa `XET_NGHIEM:474:` và dùng chung phần hành chính, phương pháp, chữ ký của nhóm Real-time PCR. Thiết bị được giữ cố định là `CFX-96` theo PRT; QTXN lấy từ `quytrinhxn`. Bệnh phẩm ưu tiên `ghichu`, đúng liên kết `NDG0!ghichu` của mẫu.

Bảng mẫu 474 có ba cột và ánh xạ khác mẫu 391/477:

- `Tên tác nhân`: `tenchiso`, dự phòng bằng `tenchiso_goc`.
- `Kết quả`: `mota`, ví dụ `ÂM TÍNH` hoặc `DƯƠNG TÍNH`.
- `DU`: `ketluan`, dự phòng bằng `ketqua_goc`, ví dụ `-` hoặc `3.16E+08`.

Phần chú giải DU dưới bảng được giữ theo PRT, gồm đơn vị detection unit, cách đọc `1E+n`, các ngưỡng tác nhân và ký hiệu `w/r`. Chú giải nằm bên trái vùng chữ ký như phiếu mẫu.

Endpoint đã đối chiếu bằng dữ liệu thật:

```text
GET /api/XNTraSau/10737/ket-qua/xet-nghiem?idMauIn=474
```

Dữ liệu kiểm tra có `mahh=187`, `mathanhtoanct=13281204`, gồm một dòng tên dịch vụ và tám tác nhân. Stored hoàn thành khoảng 1,2 giây.

## Mẫu 477 – HPV định type

File `Phiếu kết quả xét nghiệm _HPV Type.prt` xác nhận `idmauin=477`. Mẫu dùng bộ stored xét nghiệm chung `usp_XN_GETDLINPRT_TDT`, `usp_XN_GETDLINPRT_ND` và `usp_XN_GETDLINPRT_TDD`; API hiện tại đã trả đủ dữ liệu nên không cần thêm stored hay sửa controller.

Mẫu được đăng ký bằng khóa `XET_NGHIEM:477:`. Phiếu có phần phương pháp thực hiện với kỹ thuật cố định `Realtime PCR`; thiết bị lấy từ `tenmaylam` và QTXN lấy từ `quytrinhxn`. Bảng kết quả có hai cột `Tên tác nhân` và `Kết quả`. Tên dịch vụ, hai dòng `Type nguy cơ cao`/`Type nguy cơ thấp` cùng toàn bộ type HPV được lấy động từ `dongKetQua`, không hard-code danh sách type trong Flutter.

Màu chữ, in đậm, in nghiêng và gạch chân của tên tác nhân được đọc từ mã HIS trong `tenchiso`; định dạng kết quả được đọc từ `ketluan`. Vì vậy các dòng nhóm màu đỏ và các kết quả bất thường tiếp tục bám cấu hình HIS. Bệnh phẩm ưu tiên `ghichu`, sau đó `tenloaimaugop` hoặc `tenloaimau`. Thời gian/người lấy mẫu ưu tiên `ngaygiao`, `nguoigiao`, đúng liên kết trong PRT.

Endpoint đã đối chiếu bằng dữ liệu thật:

```text
GET /api/XNTraSau/10726/ket-qua/xet-nghiem?idMauIn=477
```

Dữ liệu kiểm tra có `mahh=10684`, `mathanhtoanct=13278523`, 30 dòng nội dung HPV và stored hoàn thành khoảng 2,8 giây. Chữ ký tiếp tục dùng endpoint chữ ký chung.

## Mẫu 609 – Huyết đồ

File `Phiếu kết quả Huyết đồ.prt` xác nhận `idmauin=609` và dùng stored `usp_XN_GETDLINPRT_ND`. Mẫu được đăng ký bằng khóa `XET_NGHIEM:609:`.

Bảng kết quả dùng trực tiếp `dongKetQua`. Dòng có `grouplevel != 0` được trình bày như dòng nhóm; dòng có `grouplevel = 0` dùng `tenchiso_goc`, `ketqua_goc`, `tendonvitinh`, `giatribinhthuong`, `quytrinhxn` và `InstrumentID`. Nội dung hiển thị lấy từ `ketqua_goc`; màu, in đậm, in nghiêng và gạch chân được đọc từ các mã HIS trong `ketluan`, ví dụ `<fc255,0,0>`, `<b>`, `<i>` và `<u>`. Cờ `HL` chỉ là dự phòng khi `ketluan` không có mã màu. Flutter không tự tính lại khoảng tham chiếu.

Các dữ liệu hành chính có sẵn trên dòng XN Trả Sau được ghép vào `appThongTin` trước khi dựng PDF: `hoten`, `namsinh`, `gioitinh`, `makcb`, `barcode`, `diachi`, `dienthoai`, `khoacd`, `phongcd`, `ngaycd`, `tennguoicd`. Metadata trong dòng kết quả như `bslam`, `ngaylam`, `ngaykhopBC`, `bschidinh` tiếp tục được dùng làm dự phòng.

Để đầu phiếu khớp đầy đủ mẫu HIS, endpoint xét nghiệm có thể trả thêm `data.thongTin` là một object hoặc mảng một phần tử với các trường:

```text
makcb, barcode, hoten, namsinh, tenphai, diachi, tendoituong, dienthoai,
tenkk, tenphong, sogiuong, ngayke, tennv, ngaylaymau, ngaykhopBC,
tennhanvienlaymau, tennhanviennhan, tinhtrangnguoibenh, tenchatluong,
tinhtrangmau,
tenbenh, ktvlam, bslam, ngaylam
```

Nếu chưa có `thongTin`, phiếu vẫn được tạo; trường chưa có dữ liệu được để trống. Nhận xét ưu tiên `ghichudichvu`, sau đó mới dùng `ghichu` trong `dongKetQua`.

Endpoint kiểm tra:

```text
GET /api/XNTraSau/{id}/ket-qua/xet-nghiem?idMauIn=609
```

Chữ ký dùng endpoint chữ ký hiện tại. Tên người thực hiện phía trái ưu tiên `ktvlam`, sau đó dùng `bslam`.

## Kiểm tra đã thực hiện

- Kiểm thử PDF thành công cho các mẫu 301, 376, 381, 383, 351, 388, 391, 474, 477, 609, 743, 764 và mẫu xét nghiệm dùng chung. Mẫu 301, 388, 391, 474, 477 và mẫu 609 với 20 chỉ số tạo đúng một trang A4.
- Build web debug thành công.
- Phân tích mã: không có lỗi hoặc warning; màn hình danh sách cũ còn 8 ghi chú lint về withOpacity và nội suy chuỗi.
- Chưa đăng nhập và gọi HIS trực tiếp từ màn hình mới, chưa test thiết bị Android/iOS thật.

Khi test điện thoại thật, base URL API cần là địa chỉ máy chủ điện thoại truy cập được. `localhost` là thiết bị đang chạy trình duyệt; `10.0.2.2` chỉ phục vụ kết nối từ Android Emulator. Không tự thay cấu hình địa chỉ API đang dùng của bạn.
