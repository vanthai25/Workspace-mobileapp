SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.DaoTao_CapCCHN', N'U') IS NULL
        THROW 50001, N'Không tìm thấy bảng dbo.DaoTao_CapCCHN.', 1;

    IF OBJECT_ID(N'dbo.HeThong_Files', N'U') IS NULL
        THROW 50002, N'Không tìm thấy bảng dbo.HeThong_Files.', 1;

    IF COL_LENGTH(N'dbo.DaoTao_CapCCHN', N'FileId_ThongBaoTiepNhan') IS NULL
    BEGIN
        ALTER TABLE dbo.DaoTao_CapCCHN
        ADD FileId_ThongBaoTiepNhan INT NULL;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.DaoTao_CapCCHN')
          AND name = N'FK_DaoTao_CapCCHN_ThongBaoTiepNhan'
    )
    BEGIN
        ALTER TABLE dbo.DaoTao_CapCCHN WITH CHECK
        ADD CONSTRAINT FK_DaoTao_CapCCHN_ThongBaoTiepNhan
            FOREIGN KEY (FileId_ThongBaoTiepNhan)
            REFERENCES dbo.HeThong_Files (IdFile);

        ALTER TABLE dbo.DaoTao_CapCCHN
        CHECK CONSTRAINT FK_DaoTao_CapCCHN_ThongBaoTiepNhan;
    END;

    COMMIT TRANSACTION;

    SELECT
        c.name AS ColumnName,
        t.name AS DataType,
        c.is_nullable AS IsNullable
    FROM sys.columns c
    JOIN sys.types t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'dbo.DaoTao_CapCCHN')
      AND c.name = N'FileId_ThongBaoTiepNhan';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
