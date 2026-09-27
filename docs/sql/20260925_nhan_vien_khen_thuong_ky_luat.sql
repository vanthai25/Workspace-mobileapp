/*
  Khen thưởng / Kỷ luật nhân viên V2 - HVOfficeDatabase
  Có thể chạy lại nhiều lần.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.NhanVien_KhenThuong', N'U') IS NULL
    BEGIN
        EXEC(N'
            CREATE TABLE dbo.NhanVien_KhenThuong
            (
                MaKhenThuong       varchar(50)     NOT NULL,
                MaSo               varchar(5)      NOT NULL,
                CanCuKhen          nvarchar(500)   NULL,
                LyDoKhen           nvarchar(500)   NOT NULL,
                HinhThucKhen       nvarchar(500)   NOT NULL,
                SoTienKhen         decimal(18,2)   NULL,
                SoDiemKhen         int             NULL,
                NgayKhen           date            NOT NULL,
                SoQuyetDinhKhen    varchar(150)    NULL,
                NguoiKhen          nvarchar(150)   NULL,
                GhiChu             nvarchar(1000)  NULL,
                IdFile             int             NULL,
                NguoiUD            varchar(5)      NULL,
                NgayUD             datetime2(0)    NOT NULL
                    CONSTRAINT DF_NhanVien_KhenThuong_NgayUD DEFAULT (SYSDATETIME()),
                CONSTRAINT PK_NhanVien_KhenThuong PRIMARY KEY (MaKhenThuong),
                CONSTRAINT CK_NhanVien_KhenThuong_SoTien CHECK (SoTienKhen IS NULL OR SoTienKhen >= 0),
                CONSTRAINT CK_NhanVien_KhenThuong_SoDiem CHECK (SoDiemKhen IS NULL OR SoDiemKhen >= 0),
                CONSTRAINT FK_NhanVien_KhenThuong_NhanVien FOREIGN KEY (MaSo)
                    REFERENCES dbo.NhanVien(MaSo),
                CONSTRAINT FK_NhanVien_KhenThuong_File FOREIGN KEY (IdFile)
                    REFERENCES dbo.HeThong_Files(IdFile)
            );
        ');
    END;

    IF OBJECT_ID(N'dbo.NhanVien_KyLuat', N'U') IS NULL
    BEGIN
        EXEC(N'
            CREATE TABLE dbo.NhanVien_KyLuat
            (
                MaKyLuat           varchar(50)     NOT NULL,
                MaSo               varchar(5)      NOT NULL,
                LyDoKyLuat         nvarchar(500)   NOT NULL,
                DiaDiemXayRa       nvarchar(500)   NULL,
                MoTaSuViec         nvarchar(2000)  NULL,
                HinhThucKyLuat     nvarchar(2000)  NOT NULL,
                NgayXayRa          date            NULL,
                NgayKy             date            NOT NULL,
                NguoiKy            nvarchar(150)   NULL,
                SoTienKyLuat       decimal(18,2)   NULL,
                SoDiemKyLuat       int             NULL,
                SoQuyetDinhKyLuat  varchar(150)    NULL,
                KeoDaiThamNien     bit             NOT NULL
                    CONSTRAINT DF_NhanVien_KyLuat_KeoDaiThamNien DEFAULT (0),
                SoThangKeoDaiThamNien int          NULL,
                NgayBatDauKeoDaiThamNien date      NULL,
                GhiChu             nvarchar(1000)  NULL,
                IdFile             int             NULL,
                NguoiUD            varchar(5)      NULL,
                NgayUD             datetime2(0)    NOT NULL
                    CONSTRAINT DF_NhanVien_KyLuat_NgayUD DEFAULT (SYSDATETIME()),
                CONSTRAINT PK_NhanVien_KyLuat PRIMARY KEY (MaKyLuat),
                CONSTRAINT CK_NhanVien_KyLuat_SoTien CHECK (SoTienKyLuat IS NULL OR SoTienKyLuat >= 0),
                CONSTRAINT CK_NhanVien_KyLuat_SoDiem CHECK (SoDiemKyLuat IS NULL OR SoDiemKyLuat >= 0),
                CONSTRAINT FK_NhanVien_KyLuat_NhanVien FOREIGN KEY (MaSo)
                    REFERENCES dbo.NhanVien(MaSo),
                CONSTRAINT FK_NhanVien_KyLuat_File FOREIGN KEY (IdFile)
                    REFERENCES dbo.HeThong_Files(IdFile)
            );
        ');
    END;

    IF COL_LENGTH(N'dbo.NhanVien_KyLuat', N'SoThangKeoDaiThamNien') IS NULL
        EXEC(N'ALTER TABLE dbo.NhanVien_KyLuat ADD SoThangKeoDaiThamNien int NULL;');

    IF COL_LENGTH(N'dbo.NhanVien_KyLuat', N'NgayBatDauKeoDaiThamNien') IS NULL
        EXEC(N'ALTER TABLE dbo.NhanVien_KyLuat ADD NgayBatDauKeoDaiThamNien date NULL;');

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NhanVien_KhenThuong_MaSo_NgayKhen'
                   AND object_id = OBJECT_ID(N'dbo.NhanVien_KhenThuong'))
        EXEC(N'CREATE INDEX IX_NhanVien_KhenThuong_MaSo_NgayKhen
            ON dbo.NhanVien_KhenThuong(MaSo, NgayKhen DESC);');

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NhanVien_KyLuat_MaSo_NgayKy'
                   AND object_id = OBJECT_ID(N'dbo.NhanVien_KyLuat'))
        EXEC(N'CREATE INDEX IX_NhanVien_KyLuat_MaSo_NgayKy
            ON dbo.NhanVien_KyLuat(MaSo, NgayKy DESC);');

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NhanVien_KyLuat_ThamNien'
                   AND object_id = OBJECT_ID(N'dbo.NhanVien_KyLuat'))
        EXEC(N'CREATE INDEX IX_NhanVien_KyLuat_ThamNien
            ON dbo.NhanVien_KyLuat(MaSo, NgayBatDauKeoDaiThamNien)
            INCLUDE (SoThangKeoDaiThamNien)
            WHERE KeoDaiThamNien = 1;');

    EXEC(N'
        CREATE OR ALTER VIEW dbo.vw_NhanVien_KyLuatThamNien
        AS
        SELECT
            MaSo,
            SUM(ISNULL(SoThangKeoDaiThamNien, 0)) AS TongSoThangKeoDaiThamNien,
            MIN(NgayBatDauKeoDaiThamNien) AS NgayBatDauAnhHuongSomNhat,
            MAX(NgayBatDauKeoDaiThamNien) AS NgayBatDauAnhHuongGanNhat
        FROM dbo.NhanVien_KyLuat
        WHERE KeoDaiThamNien = 1
        GROUP BY MaSo;
    ');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
