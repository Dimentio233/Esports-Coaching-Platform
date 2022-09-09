-- Johnny He
-- Nested Stored Procedures on Transactional Tables
-- 1st
-- CREATE DATABASE Esports
-- USE Esports
GO

GO
CREATE TABLE tblGENDER
(GenderID INT IDENTITY (1,1) PRIMARY KEY,
GenderName varchar(10) NOT NULL)

GO
CREATE TABLE tblTIMEZONE
(TimezoneID INT IDENTITY (1,1) PRIMARY KEY,
GMT INT NULL,
TimezoneName varchar(30) NOT NULL)

GO
CREATE TABLE tblLANGUAGE
(LanguageID INT IDENTITY (1,1) PRIMARY KEY,
LanguageName varchar(30) NOT NULL)

GO 
CREATE TABLE tblGAME_TYPE
(GameTypeID INT IDENTITY (1,1) PRIMARY KEY,
GameTypeName varchar(30) NOT NULL)

GO
CREATE TABLE tblGAME
(GameID INT IDENTITY (1,1) PRIMARY KEY,
GameName varchar(40) NOT NULL,
TotalCoachHour Numeric(8,2) NOT NULL,
TotalRevenue Numeric(8,2) NOT NULL,
GameTypeID INT FOREIGN KEY REFERENCES tblGAME_TYPE (GameTypeID) NOT NULL)

GO
CREATE TABLE tblSTUDENT
(StudentID INT IDENTITY (1,1) PRIMARY KEY,
StudentFName varchar(25) NOT NULL,
StudentLName varchar(25) NOT NULL,
StudentBirth DATE NOT NULL,
TimezoneID INT FOREIGN KEY REFERENCES tblTIMEZONE (TimezoneID) NOT NULL,
GenderID INT FOREIGN KEY REFERENCES tblGENDER (GenderID) NOT NULL,
LanguageID INT FOREIGN KEY REFERENCES tblLANGUAGE (LanguageID) NOT NULL)

GO
CREATE TABLE tblCOACH
(CoachID INT IDENTITY (1,1) PRIMARY KEY,
CoachFName varchar(25) NOT NULL,
CoachLName varchar(25) NOT NULL,
TimezoneID INT FOREIGN KEY REFERENCES tblTIMEZONE (TimezoneID) NOT NULL,
GameID INT FOREIGN KEY REFERENCES tblGAME (GameID) NOT NULL,
LanguageID INT FOREIGN KEY REFERENCES tblLANGUAGE (LanguageID) NOT NULL,
GenderID INT FOREIGN KEY REFERENCES tblGENDER (GenderID) NOT NULL,
CoachBirth DATE NOT NULL)

GO
CREATE TABLE tblPAYMENT_METHOD
(PaymentMethodID INT IDENTITY (1,1) PRIMARY KEY,
PaymentName varchar(30) NOT NULL)

GO
CREATE TABLE tblLESSON_TYPE
(LessonTypeID INT IDENTITY (1,1) PRIMARY KEY,
LessonTypeName varchar(25) NOT NULL)

GO
CREATE TABLE tblORDER_TYPE
(OrderTypeID INT IDENTITY (1,1) PRIMARY KEY,
OrderTypeName varchar(25) NOT NULL)

GO
CREATE TABLE tblDISCOUNTS
(DiscountID INT IDENTITY (1,1) PRIMARY KEY,
Amount Numeric(5,2) NOT NULL,
ExpDate DATE NOT NULL,
DiscountName varchar(25) NOT NULL,
DiscuontCode varchar(10) NOT NULL)

GO
CREATE TABLE tblLESSON
(LessonID INT IDENTITY (1,1) PRIMARY KEY,
LessonName varchar(40) NOT NULL,
LessonTypeID INT FOREIGN KEY REFERENCES tblLESSON_TYPE (LessonTypeID) NOT NULL,
GameID INT FOREIGN KEY REFERENCES tblGAME (GameID) NOT NULL,
CoachID INT FOREIGN KEY REFERENCES tblCOACH (CoachID) NOT NULL,
LessonDate DATE NOT NULL,
LessonDuration INT NOT NULL,
Price Numeric(6,2) NOT NULL)

GO
CREATE TABLE tblORDER
(OrderID INT IDENTITY (1,1) PRIMARY KEY,
StudentID INT FOREIGN KEY REFERENCES tblSTUDENT (StudentID) NOT NULL,
OrderTypeID INT FOREIGN KEY REFERENCES tblORDER_TYPE (OrderTypeID) NOT NULL,
OrderDate DATE NOT NULL,
LessonID INT FOREIGN KEY REFERENCES tblLESSON (LessonID) NOT NULL,
DiscountID INT FOREIGN KEY REFERENCES tblDISCOUNTS (DiscountID) NOT NULL)

GO
CREATE TABLE tblPAYMENT
(PaymentID INT IDENTITY (1,1) PRIMARY KEY,
PaymentMethodID INT FOREIGN KEY REFERENCES tblPAYMENT_METHOD (PaymentMethodID) NOT NULL,
OrderID INT FOREIGN KEY REFERENCES tblORDER (OrderID) NOT NULL,
Amount Numeric(6,2) NOT NULL)

-- Stored Procedures

GO
CREATE PROCEDURE Insert_Order_Type
@OrderTypeName varchar(25)
AS
INSERT INTO tblORDER_TYPE(OrderTypeName)
VALUES (@OrderTypeName)

GO
CREATE PROCEDURE Insert_Lesson_Type
@LessonTypeName varchar(25)
AS
INSERT INTO tblLESSON_TYPE(LessonTypeName)
VALUES(@LessonTypeName)

GO
CREATE PROCEDURE Insert_Payment_Method
@PaymentName varchar(25)
AS
INSERT INTO tblPAYMENT_METHOD(PaymentName)
VALUES(@PaymentName)

-- Executing Stored Procedures

EXEC Insert_Payment_Method
@PaymentName = 'Cash'

EXEC Insert_Lesson_Type
@LessonTypeName = 'Q&A'

EXEC Insert_Order_Type
@OrderTypeName = 'Online'

SELECT * FROM tblORDER_TYPE

GO


CREATE OR ALTER PROCEDURE mhe_get_pmid
@NPaymentName varchar(30),
@PM_ID INT OUTPUT
AS
SET @PM_ID = (
   SELECT TOP 1 PaymentMethodID
   FROM tblPAYMENT_METHOD
   WHERE PaymentName = @NPaymentName
)
GO
CREATE OR ALTER PROCEDURE mhe_get_odid
@NStudentFName varchar(25),
@NStudentLName varchar(25),
@NStudentBirth DATE,
@NOrderTypeName varchar(25),
@NOrderDate DATE,
@NLessonName varchar(25),
@OD_ID INT OUTPUT
AS
SET @OD_ID = (
   SELECT Top 1 OrderID
   FROM tblORDER O
       JOIN tblSTUDENT S ON O.StudentID = S.StudentID
       JOIN tblLESSON L ON O.LessonID = L.LessonID
       JOIN tblORDER_TYPE OT ON O.OrderTypeID = OT.OrderTypeID
   WHERE StudentFName = @NStudentFName
   AND StudentLName = @NStudentLName
   AND StudentBirth = @NStudentBirth
   AND OrderTypeName = @NOrderTypeName
   AND OrderDate = @NOrderDate
   AND LessonName = @NLessonName
)
  GO
CREATE OR ALTER PROCEDURE insert_payment_mhe
@Amount NUMERIC(6,2),
@PaymentName varchar(25),
@StudentFName varchar(25),
@StudentLName varchar(25),
@StudentBirth DATE,
@OrderTypeName varchar(25),
@OrderDate DATE,
@LessonName varchar(25)
AS
DECLARE @PaymentMethodID INT, @OrderID INT
EXEC mhe_get_pmid
@NPaymentName = @PaymentName,
@PM_ID = @PaymentMethodID OUTPUT
EXEC mhe_get_odid
@NStudentFName = @StudentFName,
@NStudentLName = @StudentLName,
@NStudentBirth = @StudentBirth,
@NOrderTypeName = @OrderTypeName,
@NOrderDate = @OrderDate,
@NLessonName = @LessonName,
@OD_ID = @OrderID OUTPUT
IF @OrderID IS NULL
   BEGIN
       PRINT 'Hey add orderid is null';
       THROW 55135, 'dang it is busted.',1;
   END
INSERT INTO tblPAYMENT(PaymentMethodID, OrderID, Amount)
VALUES(@PaymentMethodID, @OrderID, @Amount)
-- This code is executed 5 times with different values
EXEC insert_payment_mhe
@Amount = 300.00,
@PaymentName = 'Credit Card',
@StudentFName = 'Hollow',
@StudentLName = 'Knight',
@StudentBirth = '2017-02-24',

  @OrderTypeName = 'Online: Voice Call',
@OrderDate = '2021-04-10',
@LessonName = 'Learn League Fundamentals'
-- 2nd
GO
CREATE PROCEDURE get_ltid_mhe
@NLessonTypeName varchar(25),
@LT_ID INT OUTPUT
AS
SET @LT_ID = (
   SELECT LessonTypeID
   FROM tblLESSON_TYPE
   WHERE LessonTypeName = @NLessonTypeName
)
GO
CREATE PROCEDURE get_gid_mhe
@NGameName varchar(25),
@G_ID INT OUTPUT
AS
SET @G_ID = (
   SELECT GameID
   FROM tblGAME
   WHERE GameName = @NGameName
)
GO
CREATE PROCEDURE get_coach_id
@NCoachFName varchar(25),
@NCoachLName varchar(25),
@NCoachBirth DATE,
@C_ID INT OUTPUT
AS
SET @C_ID = (
   SELECT CoachID
   FROM tblCOACH

     WHERE CoachFName = @NCoachFName
   AND CoachLName = @NCoachLName
   AND CoachBirth = @NCoachBirth
)
GO
CREATE PROCEDURE insert_lesson_mhe
@LessonName varchar(40),
@LessonTypeName varchar(25),
@GameName varchar(40),
@CoachFName varchar(25),
@CoachLName varchar(25),
@CoachBirth DATE,
@LessonDate DATE,
@LessonDuration INT,
@Price NUMERIC(6,2)
AS
DECLARE @LessonTypeID INT, @GameID INT, @CoachID INT
EXEC get_ltid_mhe
@NLessonTypeName = @LessonTypeName,
@LT_ID = @LessonTypeID OUTPUT
EXEC get_gid_mhe
@NGameName = @GameName,
@G_ID = @GameID OUTPUT
EXEC get_coach_id
@NCoachFName = @CoachFName,
@NCoachLName = @CoachLName,
@NCoachBirth = @CoachBirth,
@C_ID = @CoachID OUTPUT
INSERT INTO tblLESSON(LessonName, LessonTypeID, GameID, CoachID, LessonDate,
LessonDuration, Price)
VALUES(@LessonName, @LessonTypeID, @GameID, @CoachID, @LessonDate, @LessonDuration,
@Price)
-- This code is executed 5 times with different values
EXEC insert_lesson_mhe
@LessonName = 'Live Q&A',

  @LessonTypeName = 'Q&A',
@GameName = 'League of Legends',
@CoachFName = 'Crazy',
@CoachLName = 'Dave',
@CoachBirth = '2009-04-01',
@LessonDate = 'July 2, 2022',
@LessonDuration = 60,
@Price = 50.00
-- Business Rule
-- 1. Anyone whose first name starts with "G" and last name ends with "Y" and is born
-- earlier than
-- the year 2000 is barred from being a Chess coach. We have tons of data indicating
-- that these factors
-- combined do not make a good coach and the coach would start ranting about his life
-- story
-- in the middle of a lesson
GO
CREATE OR ALTER FUNCTION no_coach_g()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (
   SELECT CoachID
   FROM tblCOACH C
       JOIN tblGAME G ON C.GameID = G.GameID
   WHERE (CoachFName LIKE 'G%') AND (CoachLName LIKE '%y')
   AND YEAR(CoachBirth) < 2000
   AND GameName = 'Chess'
)
SET @RET = 1
RETURN @RET
END
GO
ALTER TABLE tblCOACH WITH NOCHECK
ADD CONSTRAINT CK_No_G
CHECK (dbo.no_coach_g() = 0)

  -- 2. No Mahjong game coaching lesson taught in Chinese may proceed longer than 1
-- hour.
-- If you want to get better, just go play with your grandparents, don't waste your
-- money here.
GO
CREATE FUNCTION mahjong_limit()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (
   SELECT LessonID
   FROM tblLESSON L
       JOIN tblCOACH C ON L.CoachID = C.CoachID
       JOIN tblLANGUAGE LG ON C.LanguageID = LG.LanguageID
       JOIN tblGAME G ON L.GameID = G.GameID
   WHERE GameName = 'Mahjong'
   AND LanguageName = 'Chinese'
   AND LessonDuration > 60
)
SET @RET = 1
RETURN @RET
END
GO
ALTER TABLE tblORDER with NOCHECK
ADD CONSTRAINT ck_mahjong_hour
CHECK (dbo.mahjong_limit() = 0)
-- Computed Columns
-- 1. Calculate the number of distinct students by game
GO

CREATE OR ALTER FUNCTION fn_student_per_game(@PK INT)
RETURNS INT
AS

  BEGIN
DECLARE @RET INT = (
   SELECT COUNT(DISTINCT StudentID)
   FROM tblORDER O
       JOIN tblLESSON L ON O.LessonID = L.LessonID
   WHERE L.GameID = @PK
)
RETURN @RET
END
GO
ALTER TABLE tblGAME
ADD mhe_CalcStudents AS (dbo.fn_student_per_game(GameID))
GO
-- 2. Calculate the number of orders for each type of game
CREATE OR ALTER FUNCTION order_per_game(@PK INT)
RETURNS INT
AS BEGIN
DECLARE @RET INT = (
   SELECT COUNT(O.OrderID)
   FROM tblORDER O
       JOIN tblLESSON L ON O.LessonID = L.LessonID
       JOIN tblGAME G ON L.GameID = G.GameID
       JOIN tblGAME_TYPE GT ON G.GameTypeID = GT.GameTypeID
   WHERE GT.GameTypeID = @PK
)
RETURN @RET
END
GO
ALTER TABLE tblGAME_TYPE
ADD mhe_calc_type AS (dbo.order_per_game(GameTypeID))
GO

 -- Complex Queries
-- 1. What is the total amount of discount offered to orders that are created since
-- 2022 have a coach with the first name of "J",  and speak Portuguese.
-- and the total number of orders made before 2022 that are of the game type "MOBA."
SELECT *
FROM
(SELECT OrderID, SUM(Amount) AS SumDiscountAmount
FROM tblORDER O
   JOIN tblDISCOUNTS D On O.DiscountID = D.DiscountID
   JOIN tblLESSON L ON O.LessonID = L.LessonID
   JOIN tblCOACH C ON L.CoachID = C.CoachID
   JOIN tblLANGUAGE LG ON C.LanguageID = LG.LanguageID
WHERE LanguageName = 'Portuguese'
AND YEAR(OrderDate) >= 2022
AND CoachFName LIKE 'J%'
GROUP BY OrderID) t1,
(SELECT OrderID, SUM(Price) as PriceBefore2022
FROM tblORDER O
   JOIN tblLESSON L ON O.LessonID = L.LessonID
   JOIN tblGAME G ON L.GameID = G.GameID
   JOIN tblGAME_TYPE GT ON G.GameTypeID = GT.GameTypeID
WHERE GameTypeName = 'MOBA'
AND YEAR(OrderDate) < 2022
GROUP BY OrderID) t2
WHERE t1.OrderID = t2.OrderID
-- 2. What is the number of male English speaking students whose first name includes
-- "o"
-- and the number of Non-Binrary Japanese students whose coach's first name starts
-- with "J."
SELECT *
FROM
(SELECT StudentID, COUNT(*) AS NumMaleEng
FROM tblSTUDENT S
   JOIN tblLANGUAGE L ON S.LanguageID = L.LanguageID
   JOIN tblGENDER G ON S.GenderID = G.GenderID
WHERE StudentFName LIKE '%o%'
AND GenderName = 'Male'
AND LanguageName = 'English'
 
  GROUP BY StudentID) A,
(SELECT StudentID, COUNT(*) AS NumNonJap
FROM tblSTUDENT S
   JOIN tblGENDER G ON S.GenderID = G.GenderID
   JOIN tblLANGUAGE L ON S.LanguageID = L.LanguageID
   JOIN tblCOACH C ON L.LanguageID = C.LanguageID
WHERE GenderName = 'Non-Binary'
AND CoachFName LIKE 'C%'
AND LanguageName = 'English'
GROUP BY StudentID) B
WHERE A.StudentID = B.StudentID
--  Cafter Li
--- insert a new row to Game table (nested stored procedure)
GO
CREATE OR ALTER PROCEDURE Get_GameTypeID
@GameType varchar(40),
@GT_ID INT OUTPUT
AS
SET @GT_ID = (SELECT GameTypeID
            FROM tblGAME_TYPE GT
            WHERE GT.GameTypeName = @GameType)
GO
CREATE OR ALTER PROCEDURE [dbo].[INSERT_GAME]
@GameType_Name varchar(50),
@GName varchar(50),
@TotalHr INT,
@TotalRev NUMERIC
AS
DECLARE @GAMETYPE_ID INT
EXEC Get_GameTypeID
@GameType = @GameType_Name,
 
  @GT_ID = @GAMETYPE_ID OUTPUT
INSERT INTO tblGAME(GameName, TotalCoachHour, GameTypeID, TotalRevenue)
VALUES(@GName, @TotalHr, @GAMETYPE_ID, @TotalRev)
GO
EXEC INSERT_GAME
@GameType_Name = 'MOBA',
@GName = 'League of Legends',
@TotalHr = 13,
@TotalRev = 240
EXEC INSERT_GAME
@GameType_Name = 'FPS',
@GName = 'Counter-Strike: Global Offensive',
@TotalHr = 2,
@TotalRev = 30
EXEC INSERT_GAME
@GameType_Name = 'FPS',
@GName = 'PlayerUnknown Battlegrounds',
@TotalHr = 4,
@TotalRev = 50
EXEC INSERT_GAME
@GameType_Name = 'Simulation and Sports',
@GName = 'Grand Turismo 7',
@TotalHr = 2,
@TotalRev = 100
EXEC INSERT_GAME
@GameType_Name = 'FPS',
@GName = 'Overwatch',
@TotalHr = 2,
@TotalRev = 40
GO

  --- Insert a new row to tblORDER using nested stored procedure
SELECT * FROM tblORDER
GO
CREATE OR ALTER PROCEDURE Get_StudentID
@FName varchar(50),
@LName varchar(50),
@DOB DATE,
@S_ID INT OUTPUT
AS
SET @S_ID = (SELECT StudentID
            FROM tblSTUDENT
            WHERE StudentFName = @FName
            AND StudentLName = @LName
            AND StudentBirth = @DOB)
GO
CREATE OR ALTER PROCEDURE Get_OrderTypeID
@TypeName varchar(50),
@OT_ID INT OUTPUT
AS
SET @OT_ID = (SELECT OrderTypeID
             FROM tblORDER_TYPE
             WHERE OrderTypeName = @TypeName)
GO
CREATE OR ALTER PROCEDURE Get_LessonID
@Name varchar(50),
@L_ID INT OUTPUT
AS
SET @L_ID = (SELECT LessonID
           FROM tblLESSON
           WHERE LessonName = @Name)
GO
CREATE OR ALTER PROCEDURE Get_DiscountID

  @DName varchar(50),
@D_ID INT OUTPUT
AS
SET @D_ID = (SELECT DiscountID
            FROM tblDISCOUNTS
            WHERE DiscountName = @DName)
GO
CREATE OR ALTER PROCEDURE [dbo].[INSERT_ORDER]
@F_NAME varchar(50),
@L_NAME varchar(50),
@BIRTH DATE,
@TName varchar(50),
@LesName varchar(50),
@D_Name varchar(50),
@ODate DATE
AS
DECLARE @SID INT, @OTID INT, @LID INT, @DID INT
EXEC Get_StudentID
@FName = @F_NAME,
@LName = @L_NAME,
@DOB = @BIRTH,
@S_ID = @SID OUTPUT
EXEC Get_OrderTypeID
@TypeName = @TName,
@OT_ID = @OTID OUTPUT
EXEC Get_LessonID
@Name = @LesName,
@L_ID = @LID OUTPUT
EXEC Get_DiscountID
@DName = @D_Name,
@D_ID = @DID OUTPUT
INSERT INTO tblORDER(StudentID, OrderTypeID, OrderDate, LessonID, DiscountID)
VALUES(@SID, @OTID, @ODate, @LID, @DID)
GO

  EXEC INSERT_ORDER
@F_NAME = 'Stark',
@L_NAME = 'Yin',
@BIRTH = 'February 20, 2002',
@TName = 'In-Person',
@ODate = 'June 20, 2022',
@LesName = 'Live Q&A',
@D_Name = 'JulySale'
EXEC INSERT_ORDER
@F_NAME = 'Hollow',
@L_NAME = 'Knight',
@BIRTH = '2017-02-24',
@TName = 'Online: Voice Call',
@ODate = 'April 10, 2021',
@LesName = 'Learn League Fundamentals',
@D_Name = 'UWDiscount'
EXEC INSERT_ORDER
@F_NAME = 'Optimus',
@L_NAME = 'Prime',
@BIRTH = '1984-02-14',
@TName = 'Online: Voice Call',
@ODate = 'August 22, 2020',
@LesName = 'Aim like Cpt Jack Sparrow',
@D_Name = 'SummerSale2022'
EXEC INSERT_ORDER
@F_NAME = 'Ezio',
@L_NAME = 'Auditore',
@BIRTH = '1459-06-24',
@TName = 'Online: Voice Call',
@ODate = 'March 15, 2021',
@LesName = 'Gameplay Analysis with Siri',
@D_Name = 'SummerSale2022'
EXEC INSERT_ORDER
@F_NAME = 'Lara',
@L_NAME = 'Croft',
@BIRTH = '1992-02-14',
@TName = 'Online: Voice Call',
@ODate = 'December 22, 2021',

  @LesName = 'Obliterate Your Opponents with Style',
@D_Name = 'ReturnCustomer'
GO
EXEC INSERT_ORDER
@F_NAME = 'Lara',
@L_NAME = 'Croft',
@BIRTH = '1992-02-14',
@TName = 'Online: Play Session Only',
@ODate = 'December 25, 2021',
@LesName = 'Gameplay Analysis with Siri',
@D_Name = 'ReturnCustomer'
GO
--- Two business rules
--- 1) All students must be older than 15 (includes 15) to place an order on our
-- Esports coaching platform, and
--- Students can spend no more than $200 on a single order.
--- The purpose of this business rule is to make sure that our customers or students
-- are not underage and the price for a single coaching
--- lesson is reasonable
CREATE FUNCTION Rule_NoKids()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (SELECT *
          FROM tblSTUDENT S
          JOIN tblORDER O ON S.StudentID = O.StudentID
          JOIN tblLESSON L ON O.LessonID = L.LessonID
          WHERE DATEDIFF(YEAR, S.StudentBirth, GETDATE()) < 15
          AND L.Price > 200)
SET @RET = 1
RETURN @RET

  END GO
ALTER TABLE tblSTUDENT WITH NOCHECK
ADD CONSTRAINT CK_NoYoungPeeps
CHECK (dbo.Rule_NoKids() = 0)
GO
--- 2) The lessonType 'Live Session', GameType 'FPS' must have a lesson duration
-- longer than 30 minutes
--- This business rule ensures that the coach can cover everything that can help
-- students to improve in the next plays, and since FPS games are relative
--- long, so 30 minutes is a minimum lesson duration for quality purpose.
CREATE FUNCTION Rule_Least30()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (SELECT *
          FROM tblCOACH C
          JOIN tblLESSON L ON C.CoachID = L.CoachID
          JOIN tblLESSON_TYPE LT ON L.LessonTypeID = LT.LessonTypeID
          JOIN tblGAME G ON C.GameID = G.GameID
          JOIN tblGAME_TYPE GT ON G.GameTypeID = GT.GameTypeID
          AND L.LessonDuration < 30
          AND LT.LessonTypeName = 'Live Session'
          AND GT.GameTypeName = 'FPS')
SET @RET = 1
RETURN @RET
END
GO
ALTER TABLE tblCOACH WITH NOCHECK
ADD CONSTRAINT CK_NoShortLesson
CHECK (dbo.Rule_Least30() = 0)
GO
--- 2 Computed columns using UDF

  --- 1) This computed column determines the year-to-date (YTD) revenue from Lesson
-- Price for each Coach.
--- The parameter for this UDF will be CoachID
CREATE FUNCTION Revenue_ByCoach(@Primary INT)
RETURNS NUMERIC
AS
BEGIN
DECLARE @RET NUMERIC = (SELECT SUM(DISTINCT L.Price)
                       FROM tblCOACH C
                           JOIN tblLESSON L ON C.CoachID = L.CoachID
                       WHERE C.CoachID = @Primary
                       AND YEAR(LessonDate) = YEAR(GetDate()))
RETURN @RET
END
GO
ALTER TABLE tblCOACH
ADD Coach_CalcRev AS (dbo.Revenue_ByCoach(CoachID))
GO
--- 2) This computed column determines the year-to-date (YTD) revenue from Lesson
-- Price By each Game type.
--- The parameter for this UDF will be GameTypeID
CREATE FUNCTION Revenue_ByGameType(@Primary INT)
RETURNS NUMERIC
AS
BEGIN
DECLARE @RET NUMERIC = (SELECT SUM(DISTINCT L.Price)
                      FROM tblGAME_TYPE GT
RETURN @RET
END
GO
     JOIN tblGAME G ON GT.GameTypeID = G.GameTypeID
     JOIN tblLesson L ON G.GameID = L.GameID
WHERE GT.GameTypeID = @Primary
AND YEAR(LessonDate) = YEAR(GetDate()))

  ALTER TABLE tblGAME_TYPE
ADD GameT_CalcRev AS (dbo.Revenue_ByGameType(GameTypeID))
GO
--- Two complex Queries
--- 1) Write the SQL to determine the Coach that meet all of the following conditions:
--- older than 21 (includes 21), GenderName male, and have total revenue over $100
-- from LessonType 'Mentality Coaching' after 2015
--- Coach more than 1 GameType and contains 'D' in last name
SELECT *
FROM
(SELECT C.CoachID, C.CoachFName, C.CoachLName, SUM(L.Price) AS TotalRevenue
FROM tblCOACH C
   JOIN tblGENDER G ON C.GenderID = G.GenderID
   JOIN tblLESSON L ON C.CoachID = L.CoachID
   JOIN tblLESSON_TYPE LT ON L.LessonTypeID = LT.LessonTypeID
WHERE DATEDIFF(YEAR, C.CoachBirth, GETDATE()) >= 21
AND G.GenderName = 'Male'
AND LT.LessonTypeName = 'Mentality Coaching'
AND YEAR(L.LessonDate) > 2015
GROUP BY C.CoachID, C.CoachFName, C.CoachLName
HAVING SUM(L.Price) > 100) A,
(SELECT C.CoachID, C.CoachFName, C.CoachLName, COUNT(GT.GameTypeName) AS NumType
FROM tblCOACH C
   JOIN tblGAME G ON C.GameID = G.GameID
   JOIN tblGAME_TYPE GT ON G.GameTypeID = GT.GameTypeID
WHERE C.CoachLName LIKE '%D%'
GROUP BY C.CoachID, C.CoachFName, C.CoachLName
HAVING COUNT(GT.GameTypeName) >= 2) B
WHERE A.CoachID = B.CoachID
--- 2) Write the SQL to determine the Order that meet all of the following conditions:
--- Payment method is 'Cash', OrderType is 'In-Person' and GameType is 'FPS' and Price
-- is over $100
--- Payment method is 'Credit Card' and GameName contains 'c', Student is born after
-- 1980
SELECT *
FROM
(SELECT O.OrderID, G.GameName

  FROM tblORDER O
   JOIN tblORDER_TYPE OT ON O.OrderTypeID = OT.OrderTypeID
   JOIN tblPAYMENT P ON O.OrderID = P.OrderID
   JOIN tblPAYMENT_METHOD PM ON P.PaymentMethodID = PM.PaymentMethodID
   JOIN tblLESSON L ON O.LessonID = L.LessonID
   JOIN tblGAME G ON L.GameID = G.GameID
   JOIN tblGAME_TYPE GT ON G.GameTypeID = GT.GameTypeID
WHERE PM.PaymentName = 'Cash'
AND OT.OrderTypeName = 'In-Person'
AND GT.GameTypeName = 'FPS'
AND L.Price > 100
GROUP BY O.OrderID, G.GameName) A,
(SELECT O.OrderID
FROM tblORDER O
   JOIN tblPAYMENT P ON O.OrderID = P.OrderID
   JOIN tblPAYMENT_METHOD PM ON P.PaymentMethodID = PM.PaymentMethodID
   JOIN tblLESSON L ON O.LessonID = L.LessonID
   JOIN tblGAME G ON L.GameID = G.GameID
   JOIN tblSTUDENT S ON O.StudentID = S.StudentID
WHERE PM.PaymentName = 'Credit Card'
AND G.GameName LIKE '%c%'
AND YEAR(S.StudentBirth) > 1980
GROUP BY O.OrderID, G.GameName) B
WHERE A.OrderID = B.OrderID
--  Stark Yin

GO
-- 1) 5-10 lines to look-up table (tables with NO FK)
-- tblLANGUAGE Insert procedure
 
  CREATE OR ALTER PROCEDURE stark_insert_Language
@LN varchar(25) -- LanguageName
AS
INSERT INTO tblLANGUAGE (LanguageName)
VALUES(@LN)
GO
EXEC stark_insert_Language
@LN = ''
GO
SELECT *
FROM tblLANGUAGE
-- Down with Language part
GO
-- tblGENDER insert procedure
CREATE OR ALTER PROCEDURE stark_insert_Gender
@GN VARCHAR (25) -- GenderName
AS
INSERT INTO tblGENDER (GenderName)
VALUES(@GN)
GO
-- Male, Female, Non-Binary
EXEC stark_insert_Gender
@GN = ''
GO
SELECT * FROM tblGENDER
-- End of Gender Part
GO
-- tblTIMEZON insert procedure
CREATE OR ALTER PROCEDURE stark_insert_TimeZone
@GMT INT,
@TZN varchar(25) -- TimezoneName
AS
INSERT INTO tblTIMEZONE (GMT, TimezoneName)
VALUES(@GMT, @TZN)
GO
-- GMT, TimezoneName: -7Pacific, -4Eastern, +1London, +2Paris, +8Beijing, +9Tokyo,
-- +10Sydney
EXEC stark_insert_TimeZone
@GMT = -7,
@TZN = 'Pacific Time Zone'

  SELECT * FROM tblTIMEZONE
-- End of Timezone Part
GO
/*
2) Stored procedures to populate transactional tables
Write the getLanguage, getGender, getTimezone for FK 'ID' to Student and Coach table
Then, nested stored procedure to create transactional tables
*/
-- getLanguage
CREATE OR ALTER PROCEDURE stark_getLanguageID
@LN varchar(25),-- LanguageName
@LID INT OUTPUT
AS
SET @LID = (SELECT L.LanguageID
            FROM tblLANGUAGE L
            WHERE L.LanguageName = @LN)
GO
-- getGender
CREATE OR ALTER PROCEDURE stark_getGenderID
@GN varchar(10),-- GenderName
@GID INT OUTPUT
AS
SET @GID = (SELECT G.GenderID
            FROM tblGENDER G
            WHERE G.GenderName = @GN)
GO
-- getTimezone
CREATE OR ALTER PROCEDURE stark_getTimezoneID
@gmt INT, -- GMT number
@tzn varchar(25),-- TimezoneName
@TZID INT OUTPUT
AS
SET @TZID = (SELECT TZ.TimezoneID
            FROM tblTIMEZONE TZ
            WHERE TZ.GMT = @gmt
            AND TZ.TimezoneName = @tzn)
GO
-- Now, creat procedure to populate Student table
CREATE OR ALTER PROCEDURE stark_populate_Student
@LanguageName VARCHAR(25),
@GenderName VARCHAR(10),
@GMT INT,
@TimeZoneName varchar(25),
@StudentFname varchar(25),
@StudentLname varchar(25),
@StudentBirth DATE
AS
DECLARE @LanguageID INT, @GenderID INT, @TimeZoneID INT
EXEC stark_getLanguageID
@LN = @LanguageName,
@LID = @LanguageID OUTPUT
IF @LanguageID IS NULL
    BEGIN
        PRINT('Uhhh...@LanguageID is null and that messing things up');
        THROW 114514, '@LanguageID is NULL and is being terminated', 1;
    END
EXEC stark_getGenderID
@GN = @GenderName,
@GID = @GenderID OUTPUT
IF @GenderID IS NULL
    BEGIN
        PRINT('Uhhh...@GenderID is null and that messing things up');
        THROW 114515, '@GenderID is NULL and is being terminated', 1;
    END
EXEC stark_getTimezoneID
@gmt = @GMT,
@tzn = @TimeZoneName,
@TZID = @TimeZoneID OUTPUT
IF @TimeZoneID IS NULL
    BEGIN
        PRINT('Uhhh...@TimeZoneID is null and that messing things up');
        THROW 114516, '@TimeZoneID is NULL and is being terminated', 1;
END
INSERT INTO tblSTUDENT (StudentFname, StudentLname, StudentBirth, LanguageID,
GenderID, TimezoneID)
VALUES (@StudentFname, @StudentLname, @StudentBirth, @LanguageID, @GenderID,
@TimezoneID)
-- 63Stark, 64Hollow Knight, 65Optims Prime, 66Ezio Auditore, 67Lara Croft, 68Tony
-- Stark
EXEC stark_populate_Student
@LanguageName = 'English',
@GenderName = 'Male',
@GMT = -4,
@TimeZoneName = 'Eastern Time Zone',
@StudentFname = 'Tony',
@StudentLname = 'Stark',
@StudentBirth = '1970-5-29'

  GO
SELECT * FROM tblSTUDENT
GO
/*
Stored Procedure to populate Coach table
Write the procedure getGameID to get FK GameID,
then write to update Coach table.
Game table required being populated
*/
-- getGameID
CREATE OR ALTER PROCEDURE stark_getGameID
@GMN varchar(25),
@GMID INT OUTPUT
AS
SET @GMID = (SELECT GM.GameID
             FROM tblGAME GM
             WHERE GM.GameName = @GMN)
GO
-- Now, procedure to populate Coach table
CREATE OR ALTER PROCEDURE stark_populate_Coach
@LanguageName VARCHAR(25),
@GenderName VARCHAR(10),
@GMT INT,
@TimeZoneName varchar(25),
@GameName varchar(40),
@CoachFname varchar(25),
@CoachLname VARCHAR(25),
@CoachBirth Date
-- @StudentReturningRates DOUBLE(5,2) -- (total number of digits, decimal numbers)
AS
DECLARE @LanguageID INT, @GenderID INT, @TimeZoneID INT, @GameID INT
EXEC stark_getLanguageID
@LN = @LanguageName,
@LID = @LanguageID OUTPUT
IF @LanguageID IS NULL
    BEGIN
        PRINT('Uhhh...@LanguageID is null and that messing things up');
        THROW 114514, '@LanguageID is NULL and is being terminated', 1;
    END
EXEC stark_getGenderID
@GN = @GenderName,
@GID = @GenderID OUTPUT

  IF @GenderID IS NULL
    BEGIN
        PRINT('Uhhh...@GenderID is null and that messing things up');
        THROW 114515, '@GenderID is NULL and is being terminated', 1;
    END
EXEC stark_getTimezoneID
@gmt = @GMT,
@tzn = @TimeZoneName,
@TZID = @TimeZoneID OUTPUT
IF @TimeZoneID IS NULL
    BEGIN
        PRINT('Uhhh...@TimeZoneID is null and that messing things up');
        THROW 114516, '@TimeZoneID is NULL and is being terminated', 1;
    END
EXEC stark_getGameID
@GMN = @GameName,
@GMID = @GameID OUTPUT
IF @GameID IS NULL
    BEGIN
        PRINT('Uhhh...@GameID is null and that messing things up');
        THROW 114517, '@GameID is NULL and is being terminated', 1;
    END
INSERT INTO tblCOACH(CoachFName, CoachLName, TimezoneID, GameID, LanguageID, GenderID,
CoachBirth)
VALUES(@CoachFname, @CoachLname, @TimeZoneID, @GameID, @LanguageID, @GenderID,
@CoachBirth)
-- 1CrazyDave OW, 2BruceWayne LOL, 3JackSparrow Grand Turismo 7, 4ElizabethDeWitt OW,
-- 5SiriMicrosoft LOL
EXEC stark_populate_Coach
@LanguageName = 'English',
@GenderName = 'Non-Binary',
@GMT = -7,
@TimeZoneName = 'Pacific Time Zone',
@GameName = 'League of Legends',
@CoachFname = 'Siri',
@CoachLname = 'Microsoft',
@CoachBirth = '2010-04-10'
GO
SELECT * FROM tblCOACH
-- End of Coach table
GO
/*
2. Write the SQL code to create two business rules leveraging User-Defined Functions
(UDF) in addition to a sentence or two to describe the purpose/intent of each business
rule.

  3. Write the SQL code two computed columns leveraging UDFs
4. Write the SQL code to create two different complex queries (defined below)
*/
-- 2. Write the SQL to enforce the following Business Rules:
-- 1) No students older than 100 years old may place an order after year 2010
CREATE OR ALTER FUNCTION fn_No100old_Orderafter2010()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (SELECT *
           FROM tblSTUDENT S
            JOIN tblORDER O ON S.StudentID = O.StudentID
           WHERE S.StudentBirth < DATEADD(YEAR, -100, GETDATE())
           AND O.OrderDate > '2010-01-01'
          )
SET @RET = 1
RETURN @RET
END
GO
ALTER TABLE tblORDER WITH NOCHECK
ADD CONSTRAINT CK_No100old_Orderafter2010
CHECK (dbo.fn_No100old_Orderafter2010() = 0)
GO
-- 2) No Online order of lessons about the game League of Legends may be paid by Cash
CREATE OR ALTER FUNCTION fn_noCash_OLorder_LOL()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (SELECT *
           FROM tblORDER O
            JOIN tblLESSON L ON O.LessonID = L.LessonID
            JOIN tblGAME G ON L.GameID = G.GameID
            JOIN tblORDER_TYPE OT ON O.OrderTypeID = OT.OrderTypeID
            JOIN tblPAYMENT P ON O.OrderID = P.OrderID
            JOIN tblPAYMENT_METHOD PM ON P.PaymentMethodID = PM.PaymentMethodID
           WHERE OT.OrderTypeName LIKE 'Online%'
           AND G.GameName = 'League of Legends'
           AND PM.PaymentName = 'Cash')
SET @RET = 1
RETURN @RET
END

  GO
ALTER TABLE tblPAYMENT
ADD CONSTRAINT stark_noCash_OLorder_LOL
CHECK (dbo.fn_noCash_OLorder_LOL() = 0)
GO
-- 3. Write the SQL code two computed columns leveraging UDFs
-- 1) The SQL to create a computed column that determines the total number of orders
-- each student had placed in Year 2022
CREATE OR ALTER FUNCTION fn_CalcStuOrder_Num(@PK INT)
RETURNS varchar(50)
AS
BEGIN
DECLARE @RET varchar(50) = (SELECT COUNT(O.OrderID)
                            FROM tblORDER O
                                JOIN tblSTUDENT S ON O.StudentID = S.StudentID
                            WHERE YEAR(O.OrderDate) = '2022'
                            AND S.StudentID = @PK)
RETURN @RET
END
GO
ALTER TABLE tblSTUDENT
ADD TotalOrder2022 AS (dbo.fn_CalcStuOrder_Num(StudentID))
GO
SELECT * FROM tblSTUDENT
GO
-- 2) The SQL to create a computed column that determines the number of orders being
-- placed on each Lesson Type in year 2021
CREATE OR ALTER FUNCTION fn_CalcnumOrder_LessonType(@PK INT)
RETURNS VARCHAR(50)
AS BEGIN
DECLARE @RET varchar(50) = (SELECT COUNT(O.OrderID)
                            FROM tblORDER O
    JOIN tblLESSON L ON O.LessonID = L.LessonID
    JOIN tblLESSON_TYPE LT ON L.LessonTypeID = LT.LessonTypeID
WHERE YEAR(O.OrderDate) = '2021'
AND LT.LessonTypeID = @PK
)
RETURN @RET
END
GO

  ALTER TABLE tblLESSON_TYPE
ADD NumOrders AS (dbo.fn_CalcnumOrder_LessonType(LessonTypeID))
GO
SELECT * FROM tblLESSON_TYPE
GO
-- 4. Write the SQL code to create two different complex queries (defined below)
-- 1) Write the SQL to meet all of the following conditions:
-- Find the coach who had teached the lesson with the lesson type 'Live  Session' at
-- least 1 time in year 2022,
-- that also have earned totally more than 100 dollar by Card payment method.
SELECT A.CoachID, A.CoachFName, A.CoachLName, A.teachTimes, B.totalEarn
FROM
(SELECT C.CoachID, C.CoachFName, C.CoachLName, COUNT(*) AS teachTimes
FROM tblCOACH C
    JOIN tblLESSON L ON C.CoachID = L.CoachID
    JOIN tblLESSON_TYPE LT ON L.LessonTypeID = LT.LessonTypeID
WHERE LT.LessonTypeName = 'Live Session'
AND YEAR(GETDATE()) = '2022'
GROUP BY C.CoachID, C.CoachFName, C.CoachLName
HAVING COUNT(*) >= 1) A,
(SELECT C.CoachID, C.CoachFName, C.CoachLName, SUM(P.Amount) AS totalEarn
FROM tblCOACH C
    JOIN tblLESSON L ON C.CoachID = L.CoachID
    JOIN tblORDER O ON L.LessonID = O.LessonID
    JOIN tblPAYMENT P ON O.OrderID = P.OrderID
    JOIN tblPAYMENT_METHOD PM ON P.PaymentMethodID = PM.PaymentMethodID
WHERE PM.PaymentName LIKE '%Card'
GROUP BY C.CoachID, C.CoachFName, C.CoachLName
HAVING SUM(P.Amount) >= 100) B
WHERE A.CoachID = B.CoachID
-- 2) Write the SQL code to meet the following conditions:
-- Find the students who have placed an order of lesson in game 'League of Legends'
-- that also use at least one discount in placing orders
SELECT A.StudentID, A.StudentFName, A.StudentLName, A.orderTimes, B.numDiscountsUsed
FROM
(SELECT S.StudentID, S.StudentFName, S.StudentLName, COUNT(*) AS orderTimes
FROM tblSTUDENT S
    JOIN tblORDER O ON S.StudentID = O.StudentID
    JOIN tblLESSON L ON O.LessonID = L.LessonID
    JOIN tblGAME G ON L.GameID = G.GameID
    JOIN tblDISCOUNTS D ON O.DiscountID = D.DiscountID
WHERE G.GameName = 'League of Legends'
GROUP BY S.StudentID, S.StudentFName, S.StudentLName

HAVING COUNT(*) IS NOT NULL) A,
(SELECT S.StudentID, S.StudentFName, S.StudentLName, COUNT(D.DiscountID) AS
numDiscountsUsed
FROM tblSTUDENT S
    JOIN tblORDER O ON S.StudentID = O.StudentID
    JOIN tblDISCOUNTS D ON O.DiscountID = D.DiscountID
GROUP BY S.StudentID, S.StudentFName, S.StudentLName
HAVING COUNT(D.DiscountID) >= 1) B
WHERE A.StudentID = B.StudentID