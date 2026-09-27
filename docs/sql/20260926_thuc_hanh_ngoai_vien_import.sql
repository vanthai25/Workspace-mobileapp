/*
  Bổ sung dữ liệu phục vụ import Excel và báo cáo người thực hành ngoài BV.
  Chạy trên HVOfficeDatabase trước khi dùng chức năng import.
*/
SET XACT_ABORT ON;

IF OBJECT_ID('dbo.DaoTao_NguoiThucHanh', 'U') IS NULL
    THROW 50001, N'Sai database: không tìm thấy bảng dbo.DaoTao_NguoiThucHanh.', 1;

IF OBJECT_ID('dbo.DaoTao_DangKyThucHanh', 'U') IS NULL
    THROW 50002, N'Sai database: không tìm thấy bảng dbo.DaoTao_DangKyThucHanh.', 1;

IF OBJECT_ID('dbo.CC_LoaiNV', 'U') IS NULL
    THROW 50003, N'Sai database: không tìm thấy bảng dbo.CC_LoaiNV.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH('dbo.DaoTao_NguoiThucHanh', 'LoaiNhanVien') IS NULL
        ALTER TABLE dbo.DaoTao_NguoiThucHanh ADD LoaiNhanVien int NULL;

    IF COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'ThoiGianHocTuNgay') IS NULL
        ALTER TABLE dbo.DaoTao_DangKyThucHanh ADD ThoiGianHocTuNgay date NULL;

    IF COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'ThoiGianHocDenNgay') IS NULL
        ALTER TABLE dbo.DaoTao_DangKyThucHanh ADD ThoiGianHocDenNgay date NULL;

    IF COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'KhoaHoc') IS NULL
        ALTER TABLE dbo.DaoTao_DangKyThucHanh ADD KhoaHoc nvarchar(150) NULL;

    IF COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'HocKy') IS NULL
        ALTER TABLE dbo.DaoTao_DangKyThucHanh ADD HocKy nvarchar(100) NULL;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = 'FK_DaoTao_NguoiThucHanh_CC_LoaiNV'
          AND parent_object_id = OBJECT_ID('dbo.DaoTao_NguoiThucHanh')
    )
        ALTER TABLE dbo.DaoTao_NguoiThucHanh WITH CHECK
        ADD CONSTRAINT FK_DaoTao_NguoiThucHanh_CC_LoaiNV
            FOREIGN KEY (LoaiNhanVien) REFERENCES dbo.CC_LoaiNV(LoaiNV);

    IF NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = 'CK_DaoTao_DangKyThucHanh_ThoiGianHoc'
          AND parent_object_id = OBJECT_ID('dbo.DaoTao_DangKyThucHanh')
    )
        ALTER TABLE dbo.DaoTao_DangKyThucHanh
        ADD CONSTRAINT CK_DaoTao_DangKyThucHanh_ThoiGianHoc
            CHECK (
                ThoiGianHocTuNgay IS NULL
                OR ThoiGianHocDenNgay IS NULL
                OR ThoiGianHocDenNgay >= ThoiGianHocTuNgay
            );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT
    DB_NAME() AS DatabaseDaCapNhat,
    COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'ThoiGianHocTuNgay') AS ThoiGianHocTuNgay,
    COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'ThoiGianHocDenNgay') AS ThoiGianHocDenNgay,
    COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'KhoaHoc') AS KhoaHoc,
    COL_LENGTH('dbo.DaoTao_DangKyThucHanh', 'HocKy') AS HocKy,
    COL_LENGTH('dbo.DaoTao_NguoiThucHanh', 'LoaiNhanVien') AS LoaiNhanVien;
