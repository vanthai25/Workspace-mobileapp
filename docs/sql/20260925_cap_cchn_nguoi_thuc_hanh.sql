/*
  Chuyển DaoTao_CapCCHN thành hồ sơ người thực hành độc lập.
  MaSo chỉ được tự liên kết khi SoCCCD khớp với nhân sự bệnh viện.
  Chạy trên HVOfficeDatabase trước khi triển khai API mới.
*/
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'HoVaTen') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD HoVaTen nvarchar(250) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'NgaySinh') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD NgaySinh date NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'GioiTinh') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD GioiTinh bit NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'SoCCCD') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD SoCCCD varchar(15) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'NgayCapCCCD') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD NgayCapCCCD date NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'SoDienThoai') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD SoDienThoai varchar(20) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'DiaChiThuongTru') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD DiaChiThuongTru nvarchar(500) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'TrinhDoChuyenMon') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD TrinhDoChuyenMon nvarchar(150) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'TruongDonVi') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD TruongDonVi nvarchar(250) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'NgayBatDauThucHanh') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD NgayBatDauThucHanh date NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'NgayKetThucThucHanh') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD NgayKetThucThucHanh date NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'HocPhi') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD HocPhi decimal(18,2) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'GhiChu') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD GhiChu nvarchar(1000) NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'LoaiNhanVien') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD LoaiNhanVien int NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'AnhDaiDien') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD AnhDaiDien int NULL;
IF COL_LENGTH('dbo.DaoTao_CapCCHN', 'FileId_HocPhi') IS NULL
    ALTER TABLE dbo.DaoTao_CapCCHN ADD FileId_HocPhi int NULL;

/* Chuyển tiếp dữ liệu cũ đang liên kết trực tiếp bằng MaSo. */
EXEC sys.sp_executesql N'
    UPDATE cap
    SET HoVaTen = COALESCE(NULLIF(cap.HoVaTen, N''''), nv.HoVaTen, N''Chưa cập nhật''),
        NgaySinh = COALESCE(cap.NgaySinh, nv.NamSinh),
        GioiTinh = COALESCE(cap.GioiTinh, nv.GioiTinh),
        SoCCCD = COALESCE(NULLIF(cap.SoCCCD, ''''), nv.SoCCCD),
        NgayCapCCCD = COALESCE(cap.NgayCapCCCD, nv.NgayCapCCCD),
        SoDienThoai = COALESCE(NULLIF(cap.SoDienThoai, ''''), nv.SoDienThoai),
        DiaChiThuongTru = COALESCE(NULLIF(cap.DiaChiThuongTru, N''''), nv.DiaChiThuongTru),
        LoaiNhanVien = COALESCE(cap.LoaiNhanVien, nv.LoaiNhanVien)
    FROM dbo.DaoTao_CapCCHN cap
    LEFT JOIN dbo.NhanVien nv ON nv.MaSo = cap.MaSo;

    UPDATE dbo.DaoTao_CapCCHN
    SET HoVaTen = N''Chưa cập nhật''
    WHERE HoVaTen IS NULL OR LTRIM(RTRIM(HoVaTen)) = N'''';

    ALTER TABLE dbo.DaoTao_CapCCHN
        ALTER COLUMN HoVaTen nvarchar(250) NOT NULL;
';

/* Khoảng thực hành chung lấy từ các phân công cũ khi chưa có dữ liệu. */
EXEC sys.sp_executesql N'
    UPDATE cap
    SET NgayBatDauThucHanh = COALESCE(cap.NgayBatDauThucHanh, p.NgayBatDau),
        NgayKetThucThucHanh = COALESCE(cap.NgayKetThucThucHanh, p.NgayKetThuc)
    FROM dbo.DaoTao_CapCCHN cap
    OUTER APPLY (
        SELECT MIN(NgayBatDau) NgayBatDau, MAX(NgayKetThuc) NgayKetThuc
        FROM dbo.DaoTao_NguoiHuongDan
        WHERE IdCapCCHN = cap.IdCapCCCHN
    ) p;
';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name IN ('IX_DaoTao_CapCCHN_SoCCCD', 'UX_DaoTao_CapCCHN_SoCCCD')
      AND object_id = OBJECT_ID('dbo.DaoTao_CapCCHN')
)
    EXEC sys.sp_executesql N'
        CREATE INDEX IX_DaoTao_CapCCHN_SoCCCD
            ON dbo.DaoTao_CapCCHN(SoCCCD);
    ';

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DaoTao_CapCCHN_CC_LoaiNV')
    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DaoTao_CapCCHN WITH CHECK
        ADD CONSTRAINT FK_DaoTao_CapCCHN_CC_LoaiNV
            FOREIGN KEY (LoaiNhanVien) REFERENCES dbo.CC_LoaiNV(LoaiNV);
    ';
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DaoTao_CapCCHN_AnhDaiDien')
    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DaoTao_CapCCHN WITH CHECK
        ADD CONSTRAINT FK_DaoTao_CapCCHN_AnhDaiDien
            FOREIGN KEY (AnhDaiDien) REFERENCES dbo.HeThong_Files(IdFile);
    ';
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DaoTao_CapCCHN_FileHocPhi')
    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DaoTao_CapCCHN WITH CHECK
        ADD CONSTRAINT FK_DaoTao_CapCCHN_FileHocPhi
            FOREIGN KEY (FileId_HocPhi) REFERENCES dbo.HeThong_Files(IdFile);
    ';

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DaoTao_CapCCHN_ThoiGian')
    EXEC sys.sp_executesql N'
        ALTER TABLE dbo.DaoTao_CapCCHN
        ADD CONSTRAINT CK_DaoTao_CapCCHN_ThoiGian
            CHECK (NgayBatDauThucHanh IS NULL OR NgayKetThucThucHanh IS NULL OR NgayKetThucThucHanh >= NgayBatDauThucHanh);
    ';
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DaoTao_NguoiHuongDan_ThoiGian')
    ALTER TABLE dbo.DaoTao_NguoiHuongDan ADD CONSTRAINT CK_DaoTao_NguoiHuongDan_ThoiGian
        CHECK (NgayBatDau IS NULL OR NgayKetThuc IS NULL OR NgayKetThuc >= NgayBatDau);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
