-- Chạy trên database HVOffice mà API đang sử dụng, trước khi cập nhật API.
-- Giữ nguyên cột IdKhoaPhong (int) của DaoTao_LopDaoTao.
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.DaoTao_LopDaoTao', N'U') IS NULL
    THROW 50001, N'Không thấy DaoTao_LopDaoTao. Hãy chọn đúng database HVOffice.', 1;
IF OBJECT_ID(N'dbo.Dm_KhoaPhong', N'U') IS NULL
    THROW 50002, N'Không thấy Dm_KhoaPhong. Hãy chọn đúng database HVOffice.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.DaoTao_LopKhoaPhong', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.DaoTao_LopKhoaPhong
        (
            IdLopDaoTao int NOT NULL,
            IdKhoaPhong int NOT NULL,
            CONSTRAINT PK_DaoTao_LopKhoaPhong
                PRIMARY KEY (IdLopDaoTao, IdKhoaPhong),
            CONSTRAINT FK_DaoTao_LopKhoaPhong_Lop
                FOREIGN KEY (IdLopDaoTao)
                REFERENCES dbo.DaoTao_LopDaoTao (IdLopDaoTao)
                ON DELETE CASCADE,
            CONSTRAINT FK_DaoTao_LopKhoaPhong_KhoaPhong
                FOREIGN KEY (IdKhoaPhong)
                REFERENCES dbo.Dm_KhoaPhong (IdKhoaPhong)
        );
    END;

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.DaoTao_LopKhoaPhong')
          AND name = N'IX_DaoTao_LopKhoaPhong_IdKhoaPhong_IdLopDaoTao'
    )
        CREATE INDEX IX_DaoTao_LopKhoaPhong_IdKhoaPhong_IdLopDaoTao
            ON dbo.DaoTao_LopKhoaPhong (IdKhoaPhong, IdLopDaoTao);

    -- Bổ sung liên kết cho lớp nội bộ cũ; chạy lại không tạo bản ghi trùng.
    INSERT INTO dbo.DaoTao_LopKhoaPhong (IdLopDaoTao, IdKhoaPhong)
    SELECT lop.IdLopDaoTao, lop.IdKhoaPhong
    FROM dbo.DaoTao_LopDaoTao AS lop
    INNER JOIN dbo.Dm_KhoaPhong AS khoa ON khoa.IdKhoaPhong = lop.IdKhoaPhong
    WHERE lop.PhamViDaoTao = 2
      AND NOT EXISTS (
          SELECT 1 FROM dbo.DaoTao_LopKhoaPhong AS link
          WHERE link.IdLopDaoTao = lop.IdLopDaoTao
            AND link.IdKhoaPhong = lop.IdKhoaPhong
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Các lớp cũ có khoa/phòng không còn trong danh mục, nếu có, cần kiểm tra lại.
SELECT lop.IdLopDaoTao, lop.TenLopDaoTao, lop.IdKhoaPhong
FROM dbo.DaoTao_LopDaoTao AS lop
LEFT JOIN dbo.Dm_KhoaPhong AS khoa ON khoa.IdKhoaPhong = lop.IdKhoaPhong
WHERE lop.PhamViDaoTao = 2 AND khoa.IdKhoaPhong IS NULL;
