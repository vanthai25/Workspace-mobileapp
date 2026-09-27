/*
    Stored bao dành riêng cho API phiếu xét nghiệm.
    Không sửa ba stored gốc đang phục vụ WinForm.

    Thứ tự result set:
      0 = dongKetQua
      1 = thongTin
      2 = chanDoan
      3 = ghiChu
      4 = hinhAnh (chỉ mẫu 388, có thể không có dòng)
*/

IF OBJECT_ID(N'dbo.usp_App_XNTraSau_XetNghiem_Phieu', N'P') IS NULL
BEGIN
    EXEC(N'
        CREATE PROCEDURE dbo.usp_App_XNTraSau_XetNghiem_Phieu
        AS
        BEGIN
            SET NOCOUNT ON;
        END;
    ');
END;
GO

ALTER PROCEDURE dbo.usp_App_XNTraSau_XetNghiem_Phieu
    @makcb NVARCHAR(15) = N'',
    @barcode NVARCHAR(50) = N'',
    @ChuoiMahh NVARCHAR(MAX) = N'',
    @idmauin NVARCHAR(50) = N'',
    @mathanhtoanct NVARCHAR(MAX) = N'',
    @InTuLichSuCLS BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Mẫu 301 dùng đúng bộ ISOFIX của HIS để giữ dấu ISO và bố cục
    -- Huyết học - Đông máu. Các mẫu còn lại tiếp tục dùng clone API.
    IF LTRIM(RTRIM(@idmauin)) = N'301'
    BEGIN
        EXEC dbo.usp_XN_GETDLINPRT_ND_ISOFIX
             @makcb = @makcb,
             @barcode = @barcode,
             @ChuoiMahh = @ChuoiMahh,
             @idmauin = @idmauin,
             @mathanhtoanct = @mathanhtoanct,
             @InTuLichSuCLS = @InTuLichSuCLS;

        EXEC dbo.usp_XN_GETDLINPRT_TDT_ISOFIX
             @makcb = @makcb,
             @barcode = @barcode,
             @ChuoiMahh = @ChuoiMahh,
             @mathanhtoanct = @mathanhtoanct,
             @idmauin = @idmauin,
             @InTuLichSuCLS = @InTuLichSuCLS,
             @isdebug = 0;
    END
    ELSE
    BEGIN
        EXEC dbo.usp_App_XNTraSau_XetNghiem
             @makcb = @makcb,
             @barcode = @barcode,
             @ChuoiMahh = @ChuoiMahh,
             @idmauin = @idmauin,
             @mathanhtoanct = @mathanhtoanct,
             @InTuLichSuCLS = @InTuLichSuCLS;

        EXEC dbo.usp_XN_GETDLINPRT_TDT
             @makcb = @makcb,
             @barcode = @barcode,
             @ChuoiMahh = @ChuoiMahh,
             @mathanhtoanct = @mathanhtoanct,
             @idmauin = @idmauin,
             @InTuLichSuCLS = @InTuLichSuCLS,
             @isdebug = 0;
    END;

    -- Result set 3: chỉ lấy hai loại ghi chú cần cho phiếu.
    -- Không gọi toàn bộ TDD vì TDD còn đọc ảnh/chữ ký theo cơ chế cũ.
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


    -- Result set 4: ảnh biểu đồ PCR của mẫu 388.
    -- Chỉ đọc ảnh được đánh dấu in kết quả và nằm trong thư mục HIS cho phép.
    IF LTRIM(RTRIM(@idmauin)) = N'388'
    BEGIN
        CREATE TABLE #AnhKetQua
        (
            id INT IDENTITY(1, 1) NOT NULL,
            thutu INT NULL,
            duongDan NVARCHAR(500) NOT NULL,
            contentType VARCHAR(50) NULL,
            anh VARBINARY(MAX) NULL
        );

        DECLARE @SqlLayDuongDanAnh NVARCHAR(MAX);

        IF COL_LENGTH(N'dbo.anhcdha', N'inkq') IS NOT NULL
        BEGIN
            SET @SqlLayDuongDanAnh = N'
                INSERT INTO #AnhKetQua (thutu, duongDan)
                SELECT a.thutu, CONVERT(NVARCHAR(500), a.urlimage)
                FROM dbo.anhcdha AS a
                WHERE a.mathanhtoanct = @MaThanhToanChiTiet
                  AND ISNULL(a.inkq, 0) = 1
                  AND NULLIF(LTRIM(RTRIM(a.urlimage)), N'''') IS NOT NULL;';
        END
        ELSE
        BEGIN
            SET @SqlLayDuongDanAnh = N'
                INSERT INTO #AnhKetQua (thutu, duongDan)
                SELECT a.thutu, CONVERT(NVARCHAR(500), a.urlimage)
                FROM dbo.anhcdha AS a
                WHERE a.mathanhtoanct = @MaThanhToanChiTiet
                  AND NULLIF(LTRIM(RTRIM(a.urlimage)), N'''') IS NOT NULL;';
        END;

        EXEC sys.sp_executesql
            @SqlLayDuongDanAnh,
            N'@MaThanhToanChiTiet BIGINT',
            @MaThanhToanChiTiet = @MaThanhToanChiTiet;

        UPDATE #AnhKetQua
        SET contentType =
            CASE
                WHEN LOWER(RIGHT(duongDan, 4)) = N'.png' THEN 'image/png'
                WHEN LOWER(RIGHT(duongDan, 4)) = N'.bmp' THEN 'image/bmp'
                WHEN LOWER(RIGHT(duongDan, 4)) = N'.jpg'
                     OR LOWER(RIGHT(duongDan, 5)) = N'.jpeg'
                    THEN 'image/jpeg'
                ELSE NULL
            END;

        DECLARE @ThuMucAnhCLS NVARCHAR(260) =
            N'E:\DATA\Anh\AnhCLS\';

        DELETE FROM #AnhKetQua
        WHERE LEFT(duongDan, LEN(@ThuMucAnhCLS)) <> @ThuMucAnhCLS
           OR CHARINDEX(N'..', duongDan) > 0
           OR CHARINDEX(N'/', duongDan) > 0
           OR CHARINDEX(N':', duongDan, 3) > 0
           OR contentType IS NULL;

        DECLARE @AnhId INT;
        DECLARE @DuongDanAnh NVARCHAR(500);
        DECLARE @AnhDocDuoc VARBINARY(MAX);
        DECLARE @SqlDocAnh NVARCHAR(MAX);

        DECLARE AnhKetQuaCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT id, duongDan
            FROM #AnhKetQua
            ORDER BY ISNULL(thutu, 2147483647), id;

        OPEN AnhKetQuaCursor;
        FETCH NEXT FROM AnhKetQuaCursor INTO @AnhId, @DuongDanAnh;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @AnhDocDuoc = NULL;

            BEGIN TRY
                SET @SqlDocAnh =
                    N'SELECT @NoiDung = BulkColumn
                      FROM OPENROWSET(
                          BULK N'''
                    + REPLACE(@DuongDanAnh, N'''', N'''''')
                    + N''',
                          SINGLE_BLOB
                      ) AS img;';

                EXEC sys.sp_executesql
                    @SqlDocAnh,
                    N'@NoiDung VARBINARY(MAX) OUTPUT',
                    @NoiDung = @AnhDocDuoc OUTPUT;
            END TRY
            BEGIN CATCH
                SET @AnhDocDuoc = NULL;
            END CATCH;

            UPDATE #AnhKetQua
            SET anh = @AnhDocDuoc
            WHERE id = @AnhId;

            FETCH NEXT FROM AnhKetQuaCursor INTO @AnhId, @DuongDanAnh;
        END;

        CLOSE AnhKetQuaCursor;
        DEALLOCATE AnhKetQuaCursor;

        SELECT
            thutu,
            contentType,
            DATALENGTH(anh) AS soByte,
            anh AS Anh
        FROM #AnhKetQua
        WHERE anh IS NOT NULL
          AND DATALENGTH(anh) > 0
        ORDER BY ISNULL(thutu, 2147483647), id;
    END;
END;
GO
