USE [KPI_App]
GO

/****** Object:  UserDefinedFunction [dbo].[_KPI_USOrder]    Script Date: 01/15/2018 08:21:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Donika
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- Edits:
--	01/11/18	LKL		Fix JOIN and add constraint for CoNum
-- =============================================
CREATE FUNCTION [dbo].[_KPI_USOrder]
(
	@CoNum CoNumType
)
RETURNS tinyint
AS
BEGIN

declare @ret tinyint
set @ret = 0

	declare @country nvarchar(10)
	select @country = ca.country from co (nolock) join custaddr ca on ca.cust_num = co.cust_num and ca.cust_seq = co.cust_seq where co_num = @CoNum
	if ISNULL(@country,'') = 'USA' set @ret = 1
return @ret
END


GO


