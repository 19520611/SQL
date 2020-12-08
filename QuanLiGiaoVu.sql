--9.	Lớp trưởng của một lớp phải là học viên của lớp đó.
CREATE TRIGGER TG_CAU9 ON LOP
FOR INSERT
AS BEGIN
	DECLARE @TruongLop CHAR(5), @MaLop CHAR(3), @MaHV CHAR(5)
	SELECT @TruongLop =ins.TRGLOP ,@MaLop=ins.MALOP FROM inserted ins
	SELECT @MaHV=HV.MAHV FROM inserted ins, HOCVIEN HV WHERE HV.MALOP=ins.MALOP
	IF(@TruongLop = @MaHV) BEGIN
		PRINT 'Them đc'
	END
	ELSE BEGIN
		PRINT 'KHONG THEM DUOC'
		ROLLBACK TRAN
	END
END
--10.	Trưởng khoa phải là giáo viên thuộc khoa và có học vị “TS” hoặc “PTS”.
CREATE TRIGGER TG_CAU10 ON KHOA
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @TruongKhoa	CHAR(4), @MaGV CHAR(4), @HocVi VARCHAR(10)
	SELECT @TruongKhoa=ins.TRGKHOA, @HocVi=GV.HOCVI FROM inserted ins, GIAOVIEN GV WHERE ins.TRGKHOA=GV.MAGV AND ins.MAKHOA=GV.MAKHOA
	IF(@HocVi IN ('TS','PTS')) BEGIN
		PRINT 'THANH CONG'
	END
	ELSE BEGIN
		PRINT 'KHONG THANH CONH'
		ROLLBACK TRAN
	END
END
--15.	Học viên chỉ được thi một môn học nào đó khi lớp của học viên đã học xong môn học này.
CREATE TRIGGER TG__CAU15 ON HOCVIEN
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @MaLOP CHAR(3), @MaHV CHAR(5), @NgTHI SMALLDATETIME, @DenNGAY SMALLDATETIME
	SELECT @DenNGAY=GD.DENNGAY FROM inserted ins, GIANGDAY GD WHERE ins.MALOP=GD.MALOP
	SELECT @NgTHI=KQT.NGTHI FROM inserted ins, KETQUATHI KQT WHERE ins.MAHV=KQT.MAHV
	IF(@DenNGAY<=@NgTHI) BEGIN
		PRINT 'THEM DUOC'
	END
	ELSE BEGIN
		RAISERROR('KHONG THEM DUOC',16,1)
		ROLLBACK TRAN
	END
END
--16.	Mỗi học kỳ của một năm học, một lớp chỉ được học tối đa 3 môn.
CREATE TRIGGER TG_CAU16 ON LOP
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @MaLop CHAR(3), @HocKy TINYINT
	SELECT @MaLop=ins.MALOP FROM inserted ins
	IF (3>= (SELECT COUNT(GD.MAMH) AS SL FROM LOP L, GIANGDAY GD WHERE L.MALOP=GD.MALOP GROUP BY  L.MALOP, GD.HOCKY))
	BEGIN PRINT 'THEM DUOC'
	END
	ELSE BEGIN
		RAISERROR ('KHONG THEM DUOC',16,1)
		ROLLBACK TRAN
	END
END
--17.	Sỉ số của một lớp bằng với số lượng học viên thuộc lớp đó.
CREATE TRIGGER TR_CAU17 ON LOP
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @SiSo TINYINT, @MaLOP CHAR(3)
	SELECT @SiSo=ins.SISO FROM inserted ins
	IF (@SiSo = (SELECT COUNT(HV.MALOP) FROM inserted ins, HOCVIEN HV WHERE ins.MALOP=HV.MALOP))
	BEGIN PRINT 'THEM DUOC'
	END
	ELSE BEGIN
		RAISERROR ('KHONG HEM DUOC', 16,1)
	END
END
--18.	Trong quan hệ DIEUKIEN giá trị của thuộc tính MAMH và MAMH_TRUOC trong cùng một bộ không được giống nhau (“A”,”A”) và cũng không tồn tại hai bộ (“A”,”B”) và (“B”,”A”).
CREATE TRIGGER TG_CAU18 ON DIEUKIEN
FOR INSERT, UPDATE
AS BEGIN
	IF( 0 <> (SELECT COUNT(*) FROM inserted ins WHERE (ins.MAMH=ins.MAMH_TRUOC) OR ((ins.MAMH=ins.MAMH_TRUOC) AND (ins.MAMH_TRUOC=ins.MAMH))))
	BEGIN RAISERROR('KHONG THEM DUOC',16,1)
	END
	ELSE BEGIN
		PRINT('THEM DUOC')
	END
END
--19.	Các giáo viên có cùng học vị, học hàm, hệ số lương thì mức lương bằng nhau.
CREATE TRIGGER TG_CAU19 ON GIAOVIEN
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @SL INT
	SELECT @SL=COUNT(*) FROM inserted ins, GIAOVIEN GV WHERE ins.HOCHAM=GV.HOCHAM AND ins.HOCVI=GV.HOCHAM AND ins.HESO=GV.HESO AND ins.MUCLUONG<>GV.MUCLUONG
	IF(@SL<>0) BEGIN
		RAISERROR ('KHONG THEM DUOC',16,1);
	END
	ELSE BEGIN
		PRINT 'THEM DUOC'
	END
END
--20.	Học viên chỉ được thi lại (lần thi >1) khi điểm của lần thi trước đó dưới 5.
CREATE TRIGGER TG_CAU20 ON KETQUATHI
FOR INSERT, UPDATE
AS BEGIN
    DECLARE @KT numeric(4,2)
    SELECT @KT = COUNT(*)
    FROM Inserted I, KETQUATHI KQ
    WHERE I.MAHV = KQ.MAHV AND I.MAMH = KQ.MAMH AND KQ.LANTHI = I.LANTHI - 1 AND KQ.DIEM >= 5
    IF (@KT <> 0) BEGIN
		RAISERROR ('KHONG THEM DUOC',16,1);
	END
	ELSE BEGIN
		PRINT 'THEM DUOC'
	END
END
--21.	Ngày thi của lần thi sau phải lớn hơn ngày thi của lần thi trước (cùng học viên, cùng môn học).
CREATE TRIGGER TG_CAU21 ON KETQUATHI
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @KT NUMERIC(4,2)
	SELECT @KT=COUNT(*)  FROM inserted ins, KETQUATHI KQT WHERE ins.LANTHI=KQT.LANTHI-1 AND ins.NGTHI>KQT.NGTHI
	IF(@KT<>0) BEGIN
		RAISERROR ('KHONG THEM DUOC', 16, 1)
	END
	ELSE BEGIN
		PRINT('THEM DUOC')
	END
END
--22.	Khi phân công giảng dạy một môn học, phải xét đến thứ tự trước sau giữa các môn học (sau khi học xong những môn học phải học trước mới được học những môn liền sau).
CREATE TRIGGER TG_CAU22 ON GIANGDAY
FOR INSERT
AS BEGIN
---EM KHONG HIEU DE
END
--23.	Giáo viên chỉ được phân công dạy những môn thuộc khoa giáo viên đó phụ trách.
CREATE TRIGGER TG_CAU20 ON GIANGDAY
FOR INSERT, UPDATE
AS BEGIN
	DECLARE @KT NUMERIC(4,2)
	SELECT @KT=COUNT(*) FROM inserted ins, GIAOVIEN GV, KHOA K
	WHERE ((ins.MAGV=gv.MAGV) AND (GV.MAKHOA=K.MAKHOA)) AND ins.MAMH <> (SELECT MH.MAMH FROM MONHOC MH WHERE MH.MAKHOA=K.MAKHOA)
	IF(@KT<>0) BEGIN
		RAISERROR ('KHONG THEM DUOC', 16, 1)
	END
	ELSE BEGIN
		PRINT('THEM DUOC')
	END
END